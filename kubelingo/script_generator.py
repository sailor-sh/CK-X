import os
import yaml
from typing import Any, Dict, List, Tuple


def _ensure_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def _iter_manifest_docs(s: str) -> List[Dict[str, Any]]:
    docs: List[Dict[str, Any]] = []
    try:
        for doc in yaml.safe_load_all(s):
            if not doc:
                continue
            if isinstance(doc, dict):
                docs.append(doc)
            elif isinstance(doc, list):
                # Expand lists of objects if present
                docs.extend([d for d in doc if isinstance(d, dict)])
    except Exception:
        pass
    return docs


def _safe_get(d: Dict[str, Any], path: str, default: Any = None) -> Any:
    cur: Any = d
    for part in path.split("."):
        if isinstance(cur, dict):
            cur = cur.get(part, default)
        else:
            return default
    return cur


def _normalize_kind(kind: str) -> str:
    return (kind or "").strip().lower()


def _resource_key(kind: str, name: str, ns: str) -> str:
    ns_part = ns if ns else "default"
    return f"{kind}/{name} in ns {ns_part}"


def _script_header() -> str:
    return """#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

"""


def _emit_check(cmd: str, desc: str) -> str:
    return (
        f"echo \"- Checking: {desc}\"\n"
        f"if ! {cmd}; then\n"
        f"  echo \"✖ Failed: {desc}\" && exit 1\n"
        f"fi\n"
    )


def _generate_setup_script(resources: List[Tuple[str, str, str]], title: str) -> str:
    out: List[str] = [_script_header()]
    # Gather namespaces and emit cleanups
    namespaces = sorted({ns for (_, _, ns) in resources if ns})
    for ns in namespaces:
        out.append(
            f"# Ensure a clean namespace: {ns}\n"
            f"if kubectl get namespace '{ns}' >/dev/null 2>&1; then\n"
            f"  kubectl delete namespace '{ns}' --wait=true || true\n"
            f"fi\n"
            f"kubectl create namespace '{ns}' >/dev/null 2>&1 || true\n\n"
        )
    # Best-effort individual deletions in case resources exist outside of namespace lifecycle
    for kind, name, ns in resources:
        ns_flag = f"-n '{ns}' " if ns else ""
        kind_lc = kind.lower()
        out.append(
            f"kubectl delete {kind_lc} '{name}' {ns_flag}--ignore-not-found=true || true\n"
        )
    out.append("\necho \"Setup complete: %s\"\n" % title)
    out.append("exit 0\n")
    return "".join(out)


def _jsonpath_escape(val: Any) -> str:
    # Basic shell-safe quoting for jsonpath comparisons
    s = str(val)
    return s.replace("'", "'\''")


def _generate_validation_script(resources: List[Tuple[str, str, str]], docs: List[Dict[str, Any]], title: str, qfile_path: str) -> str:
    out: List[str] = [_script_header()]
    out.append(f"QUESTION_FILE='{qfile_path}'\n\n")

    # Presence checks
    for kind, name, ns in resources:
        desc = _resource_key(kind, name, ns)
        ns_flag = f"-n '{ns}'" if ns else ""
        out.append(_emit_check(f"kubectl get {kind.lower()} '{name}' {ns_flag} >/dev/null 2>&1", f"{desc} exists"))

    # Field checks for common resource types derived from manifest docs
    for doc in docs:
        kind = _normalize_kind(_safe_get(doc, 'kind', ''))
        name = _safe_get(doc, 'metadata.name', '')
        ns = _safe_get(doc, 'metadata.namespace', '')
        ns_flag = f"-n '{ns}'" if ns else ""

        if kind == 'deployment' and name:
            # replicas
            replicas = _safe_get(doc, 'spec.replicas')
            if replicas is not None:
                out.append(_emit_check(
                    f"[ \"$(kubectl get deploy '{name}' {ns_flag} -o jsonpath='{{.spec.replicas}}')\" = '{_jsonpath_escape(replicas)}' ]",
                    f"deployment/{name}: replicas={replicas}"
                ))
            # container name + image checks
            containers = _safe_get(doc, 'spec.template.spec.containers') or []
            if isinstance(containers, list):
                for c in containers:
                    cname = c.get('name')
                    cimage = c.get('image')
                    if cname and cimage:
                        jp = "{.spec.template.spec.containers[?(@.name=='%s')].image}" % cname
                        out.append(_emit_check(
                            f"[ \"$(kubectl get deploy '{name}' {ns_flag} -o jsonpath=\"{jp}\")\" = '{_jsonpath_escape(cimage)}' ]",
                            f"deployment/{name}: container {cname} image={cimage}"
                        ))
                    # probe basics if present
                    for probe_key in ('readinessProbe', 'livenessProbe'):
                        probe = c.get(probe_key)
                        if isinstance(probe, dict):
                            http = probe.get('httpGet') or {}
                            path = http.get('path')
                            port = http.get('port')
                            period = probe.get('periodSeconds')
                            if path is not None:
                                jp = (
                                    "{.spec.template.spec.containers[?(@.name=='%s')].%s.httpGet.path}"
                                    % (cname, probe_key)
                                )
                                out.append(_emit_check(
                                    f"[ \"$(kubectl get deploy '{name}' {ns_flag} -o jsonpath=\"{jp}\")\" = '{_jsonpath_escape(path)}' ]",
                                    f"deployment/{name}: {probe_key}.httpGet.path={path}"
                                ))
                            if port is not None:
                                jp = (
                                    "{.spec.template.spec.containers[?(@.name=='%s')].%s.httpGet.port}"
                                    % (cname, probe_key)
                                )
                                out.append(_emit_check(
                                    f"[ \"$(kubectl get deploy '{name}' {ns_flag} -o jsonpath=\"{jp}\")\" = '{_jsonpath_escape(port)}' ]",
                                    f"deployment/{name}: {probe_key}.httpGet.port={port}"
                                ))
                            if period is not None:
                                jp = (
                                    "{.spec.template.spec.containers[?(@.name=='%s')].%s.periodSeconds}"
                                    % (cname, probe_key)
                                )
                                out.append(_emit_check(
                                    f"[ \"$(kubectl get deploy '{name}' {ns_flag} -o jsonpath=\"{jp}\")\" = '{_jsonpath_escape(period)}' ]",
                                    f"deployment/{name}: {probe_key}.periodSeconds={period}"
                                ))

            # label checks (matchLabels)
            match_labels = _safe_get(doc, 'spec.selector.matchLabels') or {}
            for k, v in match_labels.items():
                jp = f"{{.spec.selector.matchLabels.{k}}}"
                out.append(_emit_check(
                    f"[ \"$(kubectl get deploy '{name}' {ns_flag} -o jsonpath=\"{jp}\")\" = '{_jsonpath_escape(v)}' ]",
                    f"deployment/{name}: selector {k}={v}"
                ))

        if kind == 'service' and name:
            sel = _safe_get(doc, 'spec.selector') or {}
            for k, v in sel.items():
                jp = f"{{.spec.selector.{k}}}"
                out.append(_emit_check(
                    f"[ \"$(kubectl get svc '{name}' {ns_flag} -o jsonpath=\"{jp}\")\" = '{_jsonpath_escape(v)}' ]",
                    f"service/{name}: selector {k}={v}"
                ))
            ports = _safe_get(doc, 'spec.ports') or []
            if isinstance(ports, list):
                for p in ports:
                    namep = p.get('name')
                    port = p.get('port')
                    target = p.get('targetPort')
                    if namep is not None:
                        jp = "{.spec.ports[?(@.name=='%s')].port}" % namep
                        out.append(_emit_check(
                            f"[ \"$(kubectl get svc '{name}' {ns_flag} -o jsonpath=\"{jp}\")\" = '{_jsonpath_escape(port)}' ]",
                            f"service/{name}: port[{namep}]={port}"
                        ))
                    if target is not None:
                        jp = "{.spec.ports[?(@.name=='%s')].targetPort}" % (namep or 'http')
                        out.append(_emit_check(
                            f"[ \"$(kubectl get svc '{name}' {ns_flag} -o jsonpath=\"{jp}\")\" = '{_jsonpath_escape(target)}' ]",
                            f"service/{name}: targetPort[{namep or 'http'}]={target}"
                        ))

    # Collect live manifests for AI feedback (optional)
    out.append("\n# Collect manifests to feed Kubelingo AI validator (optional)\n")
    out.append("USER_MANIFEST=''\n")
    for kind, name, ns in resources:
        ns_flag = f"-n '{ns}'" if ns else ""
        out.append(
            "USER_MANIFEST+=$'---\n'\n"
            f"USER_MANIFEST+=" + '"$(kubectl get ' + f"{kind.lower()} '{name}' {ns_flag} -o yaml" + ')"' + "\n"
            "USER_MANIFEST+=$'\n'\n"
        )

    out.append(
        "python3 - <<'PY'\n"
        "import os, sys, yaml\n"
        "from kubelingo.validation import validate_manifest_with_llm\n"
        "qfile = os.environ.get('QUESTION_FILE','')\n"
        "if qfile and os.path.exists(qfile):\n"
        "    with open(qfile,'r') as f: q = yaml.safe_load(f)\n"
        "else:\n"
        "    q = {'question': '','suggestion': ''}\n"
        "user_input = os.environ.get('USER_MANIFEST','')\n"
        "try:\n"
        "    res = validate_manifest_with_llm(q, user_input, verbose=False)\n"
        "    print('AI Feedback:' )\n"
        "    print(res.get('feedback','').strip())\n"
        "except Exception as e:\n"
        "    print('AI Feedback: unavailable (', e, ')')\n"
        "PY\n"
    )

    out.append("\necho \"Validation passed: %s\"\n" % title)
    return "".join(out)


def generate_scripts_from_question_file(qfile_path: str, out_root: str) -> Tuple[str, str]:
    """Generate setup and validation scripts for a stored question file.

    Returns (setup_path, validation_path).
    """
    with open(qfile_path, 'r') as f:
        q = yaml.safe_load(f)

    # Title and identity
    qid = (q.get('id') or os.path.splitext(os.path.basename(qfile_path))[0]).strip()
    title = q.get('question', '').splitlines()[0] if q.get('question') else qid

    # Parse suggested answer into manifests (if present)
    suggested = q.get('suggested_answer') or q.get('suggestion') or ''
    docs = _iter_manifest_docs(suggested) if isinstance(suggested, str) else []

    # Collect resources (kind, name, ns)
    resources: List[Tuple[str, str, str]] = []
    for doc in docs:
        kind = str(_safe_get(doc, 'kind', '') or '').strip()
        name = str(_safe_get(doc, 'metadata.name', '') or '').strip()
        ns = str(_safe_get(doc, 'metadata.namespace', '') or '').strip()
        if kind and name:
            resources.append((kind, name, ns))

    # If no manifest docs are available or no resources discovered, skip generation.
    if not docs or not resources:
        raise ValueError("No manifest resources discovered in suggested_answer; skipping script generation.")

    # Determine output layout: scripts/<qid>/{setup,validation}/<qid>_*.sh
    base_dir = os.path.join(out_root, qid)
    setup_dir = os.path.join(base_dir, 'setup')
    val_dir = os.path.join(base_dir, 'validation')
    _ensure_dir(setup_dir)
    _ensure_dir(val_dir)

    setup_path = os.path.join(setup_dir, f"{qid}_setup.sh")
    validation_path = os.path.join(val_dir, f"{qid}_validate.sh")

    with open(setup_path, 'w') as sf:
        sf.write(_generate_setup_script(resources, title))

    with open(validation_path, 'w') as vf:
        vf.write(_generate_validation_script(resources, docs, title, qfile_path))

    # Make scripts executable
    try:
        os.chmod(setup_path, 0o755)
        os.chmod(validation_path, 0o755)
    except Exception:
        pass

    return setup_path, validation_path
