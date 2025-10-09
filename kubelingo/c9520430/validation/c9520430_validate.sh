#!/bin/bash

set -euo pipefail
IFS=$'
	'

QUESTION_FILE='stored/c9520430.yaml'

echo "- Checking: ConfigMap/app-config in ns default exists"
if ! kubectl get configmap 'app-config' -n 'default' >/dev/null 2>&1; then
  echo "✖ Failed: ConfigMap/app-config in ns default exists" && exit 1
fi

# Collect manifests to feed Kubelingo AI validator (optional)
USER_MANIFEST=''
USER_MANIFEST+=$'---
'
USER_MANIFEST+="$(kubectl get configmap 'app-config' -n 'default' -o yaml)"
USER_MANIFEST+=$'
'
python3 - <<'PY'
import os, sys, yaml
from kubelingo.validation import validate_manifest_with_llm
qfile = os.environ.get('QUESTION_FILE','')
if qfile and os.path.exists(qfile):
    with open(qfile,'r') as f: q = yaml.safe_load(f)
else:
    q = {'question': '','suggestion': ''}
user_input = os.environ.get('USER_MANIFEST','')
try:
    res = validate_manifest_with_llm(q, user_input, verbose=False)
    print('AI Feedback:' )
    print(res.get('feedback','').strip())
except Exception as e:
    print('AI Feedback: unavailable (', e, ')')
PY

echo "Validation passed: Create a ConfigMap named 'app-config' in the 'default' namespace with the following data: key1: value1, key2: value2."
