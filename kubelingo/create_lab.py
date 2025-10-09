"""
Interactive Lab Creator for CK-X style labs (guided by CONTRIBUTING_AI.md).

This CLI walks through gated steps to scaffold a lab under a given root:
- facilitator/assets/exams/<category>/<id>/
- Writes config.json, assessment.json, answers.md, and scripts/*

By default it runs in mock/offline mode so tests do not require network or API keys.
Use --no-mock to require provider-backed generation (if configured). In --no-mock
mode, the command fails if an AI provider cannot generate proper manifests.
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass, field
from typing import Dict, Any, Tuple

import click
import yaml


def _ensure_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def _default_lab_name(category: str, lab_id: str) -> str:
    return f"{category.upper()} Practice Lab {lab_id}"


def _default_lab_desc(topic: str, difficulty: str) -> str:
    d = difficulty.lower() if difficulty else "medium"
    t = topic or "Kubernetes"
    return f"Practice lab on {t} ({d} difficulty)"


def _mock_question(topic: str, difficulty: str) -> Dict[str, Any]:
    # Minimal, deterministic manifest-based question suitable for script generation
    topic = topic or "deployment"
    qid = "q1"
    manifest = {
        "apiVersion": "apps/v1",
        "kind": "Deployment",
        "metadata": {"name": "nginx-deploy", "namespace": "default"},
        "spec": {
            "replicas": 2,
            "selector": {"matchLabels": {"app": "nginx"}},
            "template": {
                "metadata": {"labels": {"app": "nginx"}},
                "spec": {
                    "containers": [
                        {"name": "web", "image": "nginx:1.25"}
                    ]
                },
            },
        },
    }
    text = (
        "Create a Deployment named `nginx-deploy` with 2 replicas using the image "
        "`nginx:1.25` in the `default` namespace and label it `app=nginx`."
    )
    return {
        "id": qid,
        "topic": topic,
        "question": text,
        "source": "",
        "suggested_answer": yaml.safe_dump(manifest, sort_keys=False),
        "user_answer": "",
        "ai_feedback": "",
    }


@dataclass
class LabState:
    root: str
    category: str
    lab_numeric: str
    topic: str
    difficulty: str
    mock: bool = True
    hostname: str = "ckad9999"

    lab_id: str = field(init=False)
    name: str = ""
    description: str = ""
    question: Dict[str, Any] = field(default_factory=dict)
    scripts: Dict[str, str] = field(default_factory=dict)

    def __post_init__(self) -> None:
        self.lab_id = f"{self.category}-{self.lab_numeric}"

    # Filesystem paths
    @property
    def base_dir(self) -> str:
        return os.path.join(self.root, "facilitator", "assets", "exams", self.category, self.lab_numeric)

    @property
    def scripts_setup_dir(self) -> str:
        return os.path.join(self.base_dir, "scripts", "setup")

    @property
    def scripts_val_dir(self) -> str:
        return os.path.join(self.base_dir, "scripts", "validation")


class LabCreator:
    def __init__(self, state: LabState) -> None:
        self.s = state

    # --- Helper for manual gate
    def prompt_for_approval(self, title: str, content: str, non_interactive: bool = False) -> Tuple[bool, str]:
        while True:
            click.secho(f"--- {title} ---", fg="cyan")
            click.echo(content)
            click.secho("--------------------", fg="cyan")
            if non_interactive:
                return True, content
            choice = click.prompt(
                "Please review. [A]pprove, [R]etry, [E]dit?",
                type=click.Choice(["A", "R", "E"], case_sensitive=False),
                default="A",
            )
            c = choice.upper()
            if c == "A":
                return True, content
            if c == "R":
                return False, content
            if c == "E":
                edited = click.edit(content)
                content = edited if edited is not None else content

    # --- Stages ---
    def step_1_init(self, non_interactive: bool = False) -> None:
        self.s.name = self.s.name or _default_lab_name(self.s.category, self.s.lab_numeric)
        self.s.description = self.s.description or _default_lab_desc(self.s.topic, self.s.difficulty)
        proposal = json.dumps(
            {
                "lab_id": self.s.lab_id,
                "name": self.s.name,
                "description": self.s.description,
                "topic": self.s.topic,
                "difficulty": self.s.difficulty,
            },
            indent=2,
        )
        ok, content = self.prompt_for_approval("Lab Details", proposal, non_interactive)
        if not ok:
            # Retry with the same defaults for simplicity
            ok, content = self.prompt_for_approval("Lab Details (retry)", proposal, True)
        try:
            data = json.loads(content)
            self.s.name = data.get("name", self.s.name)
            self.s.description = data.get("description", self.s.description)
        except Exception:
            pass

    def step_2_generate_question(self, non_interactive: bool = False) -> None:
        if self.s.mock:
            generated = _mock_question(self.s.topic, self.s.difficulty)
        else:
            # Require provider-backed generation and fail on errors
            try:
                from .question_generator import generate_questions  # type: ignore
                generated = generate_questions("manifests", 1, self.s.difficulty)
                if isinstance(generated, list):
                    generated = generated[0]
            except Exception as e:
                raise click.ClickException(
                    f"AI provider failed to generate manifests: {e}"
                )
        ok, final_text = self.prompt_for_approval("Generated Question", generated.get("question", ""), non_interactive)
        if not ok:
            ok, final_text = self.prompt_for_approval("Generated Question (retry)", generated.get("question", ""), True)
        generated["question"] = final_text
        self.s.question = generated
        click.secho("Question approved.", fg="green")

    def step_3_generate_verification(self, non_interactive: bool = False) -> None:
        # Define four specific checks for clearer scoring and feedback
        steps = [
            {
                "id": "1",
                "description": "Deployment exists",
                "verificationScriptFile": "q1_s1_validate_exists.sh",
                "expectedOutput": "0",
                "weightage": 1,
            },
            {
                "id": "2",
                "description": "Deployment has correct replicas",
                "verificationScriptFile": "q1_s2_validate_replicas.sh",
                "expectedOutput": "0",
                "weightage": 1,
            },
            {
                "id": "3",
                "description": "Deployment uses correct image",
                "verificationScriptFile": "q1_s3_validate_image.sh",
                "expectedOutput": "0",
                "weightage": 1,
            },
            {
                "id": "4",
                "description": "Deployment has correct selector label(s)",
                "verificationScriptFile": "q1_s4_validate_selector.sh",
                "expectedOutput": "0",
                "weightage": 1,
            },
        ]
        text = json.dumps({"verification": steps}, indent=2)
        ok, content = self.prompt_for_approval("Verification Steps", text, non_interactive)
        if not ok:
            ok, content = self.prompt_for_approval("Verification Steps (retry)", text, True)
        try:
            data = json.loads(content)
            self.scripts_meta = data.get("verification", steps)  # type: ignore[attr-defined]
        except Exception:
            self.scripts_meta = steps  # type: ignore[attr-defined]
        click.secho("Verification steps approved.", fg="green")

    def step_4_generate_scripts(self, non_interactive: bool = False) -> None:
        # Write a temporary question YAML inside the lab for script generation
        _ensure_dir(self.s.base_dir)
        qfile = os.path.join(self.s.base_dir, "assessment_question.yaml")
        with open(qfile, "w") as f:
            yaml.safe_dump(self.s.question, f, sort_keys=False)

        # Use script generator; must succeed in --no-mock mode
        setup_path: str
        validation_path: str
        try:
            from .script_generator import generate_scripts_from_question_file  # type: ignore

            setup_path, validation_path = generate_scripts_from_question_file(
                qfile_path=qfile, out_root=os.path.join(self.s.base_dir, "scripts")
            )
        except Exception as e:
            # In non-mock mode, never fallback; fail early.
            if not self.s.mock:
                raise click.ClickException(
                    f"Script generation failed (invalid or missing manifests?): {e}"
                )
            # In mock mode, keep behavior strict as well to ensure proper manifests
            raise click.ClickException(
                f"Script generation failed in mock mode (this indicates malformed suggested_answer): {e}"
            )

        # Also mirror files into scripts/validation and scripts/setup roots, as per CONTRIBUTING_AI.md
        import shutil
        _ensure_dir(self.s.scripts_setup_dir)
        _ensure_dir(self.s.scripts_val_dir)
        setup_basename = os.path.basename(setup_path)
        val_basename = os.path.basename(validation_path)
        setup_flat = os.path.join(self.s.scripts_setup_dir, setup_basename)
        val_flat = os.path.join(self.s.scripts_val_dir, val_basename)
        try:
            shutil.copy2(setup_path, setup_flat)
            shutil.copy2(validation_path, val_flat)
        except Exception:
            pass

        # Record relative names for assessment.json
        self.s.scripts = {
            "setup": os.path.relpath(setup_flat, start=os.path.join(self.s.base_dir, "scripts")),
            "validation": os.path.relpath(val_flat, start=os.path.join(self.s.base_dir, "scripts")),
        }
        click.secho("Scripts generated.", fg="green")

        # Generate specific per-criterion validation scripts for clearer scoring
        # Parse values from the suggested manifest
        with open(qfile, "r") as f:
            qy = yaml.safe_load(f)
        suggested = qy.get("suggested_answer", "")
        try:
            docs = list(yaml.safe_load_all(suggested)) if suggested else []
        except Exception:
            docs = []
        dep = None
        for d in docs:
            if isinstance(d, dict) and (d.get("kind", "").lower() == "deployment"):
                dep = d
                break
        # Defaults
        dep_name = "nginx-deploy"
        dep_ns = "default"
        replicas = 2
        image = "nginx:1.25"
        # Read from manifest if present
        if isinstance(dep, dict):
            dep_name = (dep.get("metadata", {}).get("name") or dep_name)
            dep_ns = (dep.get("metadata", {}).get("namespace") or dep_ns)
            replicas = dep.get("spec", {}).get("replicas", replicas)
            # choose first container image
            try:
                containers = dep.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [])
                if containers and isinstance(containers, list):
                    c0 = containers[0]
                    image = c0.get("image", image)
            except Exception:
                pass
        val_dir = self.s.scripts_val_dir
        os.makedirs(val_dir, exist_ok=True)

        def _w(path: str, content: str) -> None:
            with open(path, "w") as f:
                f.write(content)
            try:
                os.chmod(path, 0o755)
            except Exception:
                pass

        # Script 1: exists
        s1 = f"""#!/bin/bash
set -euo pipefail
kubectl get deploy '{dep_name}' -n '{dep_ns}' >/dev/null 2>&1
"""
        _w(os.path.join(val_dir, "q1_s1_validate_exists.sh"), s1)

        # Script 2: replicas
        s2 = f"""#!/bin/bash
set -euo pipefail
rv=$(kubectl get deploy '{dep_name}' -n '{dep_ns}' -o jsonpath='{{.spec.replicas}}' 2>/dev/null || echo '')
[[ "$rv" = "{replicas}" ]]
"""
        _w(os.path.join(val_dir, "q1_s2_validate_replicas.sh"), s2)

        # Script 3: image (match any container image)
        s3 = f"""#!/bin/bash
set -euo pipefail
imgs=$(kubectl get deploy '{dep_name}' -n '{dep_ns}' -o jsonpath='{{.spec.template.spec.containers[*].image}}' 2>/dev/null || echo '')
grep -qw -- '{image}' <<< "$imgs"
"""
        _w(os.path.join(val_dir, "q1_s3_validate_image.sh"), s3)

        # Script 4: selector labels (if present)
        # Try to validate at least app= label from matchLabels; fallback to ok if none specified
        match_ok = False
        if isinstance(dep, dict):
            sel = dep.get("spec", {}).get("selector", {}).get("matchLabels", {})
            for k, v in sel.items():
                s4 = f"""#!/bin/bash
set -euo pipefail
val=$(kubectl get deploy '{dep_name}' -n '{dep_ns}' -o jsonpath='{{{{.spec.selector.matchLabels.{k}}}}}' 2>/dev/null || echo '')
[[ "$val" = "{v}" ]]
"""
                _w(os.path.join(val_dir, "q1_s4_validate_selector.sh"), s4)
                match_ok = True
                break
        if not match_ok:
            # If no selector labels found in manifest, create a no-op that passes
            s4 = """#!/bin/bash
exit 0
"""
            _w(os.path.join(val_dir, "q1_s4_validate_selector.sh"), s4)

    def step_5_create_answers(self, non_interactive: bool = False) -> None:
        answers_md = [f"# {self.s.name}", "", "## Question", "", self.s.question.get("question", "")] 
        suggested = self.s.question.get("suggested_answer", "")
        if suggested:
            answers_md.extend(["", "## Suggested Answer (YAML)", "", "```yaml", suggested.strip(), "```"])
        content = "\n".join(answers_md)
        _ensure_dir(self.s.base_dir)
        with open(os.path.join(self.s.base_dir, "answers.md"), "w") as f:
            f.write(content)
        click.secho("answers.md created.", fg="green")

    def step_6_finalize(self, non_interactive: bool = False) -> None:
        _ensure_dir(self.s.base_dir)
        # config.json
        cfg = {
            "lab": self.s.lab_id,
            "workerNodes": 1,
            "answers": "assets/exams/%s/%s/answers.md" % (self.s.category, self.s.lab_numeric),
            "questions": "assessment.json",
            "totalMarks": 100,
            "lowScore": 40,
            "mediumScore": 60,
            "highScore": 90,
        }
        with open(os.path.join(self.s.base_dir, "config.json"), "w") as f:
            json.dump(cfg, f, indent=2)

        # assessment.json (single question referencing validation script)
        # CK-X expects verificationScriptFile to be a filename (looked up under scripts/validation).
        scripts_val_rel = self.s.scripts.get("validation", "validation/q1_validate.sh")
        try:
            import os as _os
            scripts_val_basename = _os.path.basename(scripts_val_rel)
        except Exception:
            scripts_val_basename = "q1_validate.sh"
        assessment = {
            "questions": [
                {
                    "id": "1",
                    "namespace": "default",
                    "machineHostname": self.s.hostname or "ckad9999",
                    "question": self.s.question.get("question", ""),
                    "concepts": [self.s.topic],
                    "verification": [
                        {
                            "id": step.get("id", "1"),
                            "description": step.get("description", "Validation"),
                            "verificationScriptFile": step.get("verificationScriptFile", "q1_s1_validate_exists.sh"),
                            "expectedOutput": str(step.get("expectedOutput", "0")),
                            "weightage": int(step.get("weightage", 1)),
                        }
                        for step in getattr(self, "scripts_meta", [])
                    ],
                }
            ]
        }
        with open(os.path.join(self.s.base_dir, "assessment.json"), "w") as f:
            json.dump(assessment, f, indent=2)

        # Update labs.json registry
        self._update_labs_registry()

        click.secho(f"Lab '{self.s.lab_id}' created at {self.s.base_dir}", fg="green")

    def _update_labs_registry(self) -> None:
        # Write or update the main labs.json registry under facilitator/assets/exams/labs.json
        reg_dir = os.path.join(self.s.root, "facilitator", "assets", "exams")
        _ensure_dir(reg_dir)
        reg_path = os.path.join(reg_dir, "labs.json")
        labs: Dict[str, Any]
        if os.path.exists(reg_path):
            try:
                with open(reg_path, "r") as f:
                    labs = json.load(f)
            except Exception:
                labs = {"labs": []}
        else:
            labs = {"labs": []}

        # Remove any existing entry with same id
        labs["labs"] = [l for l in labs.get("labs", []) if l.get("id") != self.s.lab_id]
        # Add new entry
        labs["labs"].append(
            {
                "id": self.s.lab_id,
                "assetPath": f"assets/exams/{self.s.category}/{self.s.lab_numeric}",
                "name": self.s.name or _default_lab_name(self.s.category, self.s.lab_numeric),
                "category": self.s.category.upper(),
                "description": self.s.description or _default_lab_desc(self.s.topic, self.s.difficulty),
                "warmUpTimeInSeconds": 60,
                "difficulty": self.s.difficulty.lower(),
            }
        )
        with open(reg_path, "w") as f:
            json.dump(labs, f, indent=2)


@click.command()
@click.option(
    "--root",
    type=click.Path(file_okay=False, dir_okay=True),
    default="kubelingo/out",
    help="Output root directory (kept isolated by default)",
)
@click.option("--lab-category", type=click.Choice(["ckad", "cka", "cks", "other"], case_sensitive=False), required=True)
@click.option("--lab-id", "lab_numeric", prompt=True, help="Lab numeric id, e.g. 003")
@click.option("--topic", default="deployment", help="Primary topic for generation")
@click.option("--difficulty", default="medium", help="Difficulty label")
@click.option("--name", default="", help="Optional custom lab name")
@click.option("--description", default="", help="Optional custom description")
@click.option("--mock/--no-mock", default=True, help="Use deterministic offline generation")
@click.option("--non-interactive", is_flag=True, default=False, help="Auto-approve all gates")
@click.option("--hostname", default="ckad9999", help="Machine hostname shown in question (e.g., ckad9999)")
def main(root: str, lab_category: str, lab_numeric: str, topic: str, difficulty: str, name: str, description: str, mock: bool, non_interactive: bool, hostname: str) -> None:
    """Run the interactive lab creator as described in CONTRIBUTING_AI.md."""
    state = LabState(
        root=root,
        category=lab_category.lower(),
        lab_numeric=lab_numeric,
        topic=topic,
        difficulty=difficulty,
        mock=mock,
    )
    state.hostname = hostname
    state.name = name
    state.description = description
    creator = LabCreator(state)

    click.echo("\n--- Step 1: Initialize Lab ---")
    creator.step_1_init(non_interactive=non_interactive)

    click.echo("\n--- Step 2: Generate Question ---")
    creator.step_2_generate_question(non_interactive=non_interactive)

    click.echo("\n--- Step 3: Generate Verification Steps ---")
    creator.step_3_generate_verification(non_interactive=non_interactive)

    click.echo("\n--- Step 4: Generate Scripts ---")
    creator.step_4_generate_scripts(non_interactive=non_interactive)

    click.echo("\n--- Step 5: Create Answers ---")
    creator.step_5_create_answers(non_interactive=non_interactive)

    click.echo("\n--- Step 6: Finalize ---")
    creator.step_6_finalize(non_interactive=non_interactive)


if __name__ == "__main__":
    main()
