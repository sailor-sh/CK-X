#!/bin/bash

set -euo pipefail
IFS=$'
	'

QUESTION_FILE='stored/ckad_q22_api_gateway.yaml'

echo "- Checking: Deployment/api-gateway in ns platform exists"
if ! kubectl get deployment 'api-gateway' -n 'platform' >/dev/null 2>&1; then
  echo "✖ Failed: Deployment/api-gateway in ns platform exists" && exit 1
fi
echo "- Checking: Service/api-gateway-svc in ns platform exists"
if ! kubectl get service 'api-gateway-svc' -n 'platform' >/dev/null 2>&1; then
  echo "✖ Failed: Service/api-gateway-svc in ns platform exists" && exit 1
fi
echo "- Checking: deployment/api-gateway: replicas=2"
if ! [ "$(kubectl get deploy 'api-gateway' -n 'platform' -o jsonpath='{.spec.replicas}')" = '2' ]; then
  echo "✖ Failed: deployment/api-gateway: replicas=2" && exit 1
fi
echo "- Checking: deployment/api-gateway: container gateway image=nginx:1.25-alpine"
if ! [ "$(kubectl get deploy 'api-gateway' -n 'platform' -o jsonpath="{.spec.template.spec.containers[?(@.name=='gateway')].image}")" = 'nginx:1.25-alpine' ]; then
  echo "✖ Failed: deployment/api-gateway: container gateway image=nginx:1.25-alpine" && exit 1
fi
echo "- Checking: deployment/api-gateway: readinessProbe.httpGet.path=/healthz"
if ! [ "$(kubectl get deploy 'api-gateway' -n 'platform' -o jsonpath="{.spec.template.spec.containers[?(@.name=='gateway')].readinessProbe.httpGet.path}")" = '/healthz' ]; then
  echo "✖ Failed: deployment/api-gateway: readinessProbe.httpGet.path=/healthz" && exit 1
fi
echo "- Checking: deployment/api-gateway: readinessProbe.httpGet.port=80"
if ! [ "$(kubectl get deploy 'api-gateway' -n 'platform' -o jsonpath="{.spec.template.spec.containers[?(@.name=='gateway')].readinessProbe.httpGet.port}")" = '80' ]; then
  echo "✖ Failed: deployment/api-gateway: readinessProbe.httpGet.port=80" && exit 1
fi
echo "- Checking: deployment/api-gateway: readinessProbe.periodSeconds=10"
if ! [ "$(kubectl get deploy 'api-gateway' -n 'platform' -o jsonpath="{.spec.template.spec.containers[?(@.name=='gateway')].readinessProbe.periodSeconds}")" = '10' ]; then
  echo "✖ Failed: deployment/api-gateway: readinessProbe.periodSeconds=10" && exit 1
fi
echo "- Checking: deployment/api-gateway: livenessProbe.httpGet.path=/healthz"
if ! [ "$(kubectl get deploy 'api-gateway' -n 'platform' -o jsonpath="{.spec.template.spec.containers[?(@.name=='gateway')].livenessProbe.httpGet.path}")" = '/healthz' ]; then
  echo "✖ Failed: deployment/api-gateway: livenessProbe.httpGet.path=/healthz" && exit 1
fi
echo "- Checking: deployment/api-gateway: livenessProbe.httpGet.port=80"
if ! [ "$(kubectl get deploy 'api-gateway' -n 'platform' -o jsonpath="{.spec.template.spec.containers[?(@.name=='gateway')].livenessProbe.httpGet.port}")" = '80' ]; then
  echo "✖ Failed: deployment/api-gateway: livenessProbe.httpGet.port=80" && exit 1
fi
echo "- Checking: deployment/api-gateway: livenessProbe.periodSeconds=10"
if ! [ "$(kubectl get deploy 'api-gateway' -n 'platform' -o jsonpath="{.spec.template.spec.containers[?(@.name=='gateway')].livenessProbe.periodSeconds}")" = '10' ]; then
  echo "✖ Failed: deployment/api-gateway: livenessProbe.periodSeconds=10" && exit 1
fi
echo "- Checking: deployment/api-gateway: selector app=api"
if ! [ "$(kubectl get deploy 'api-gateway' -n 'platform' -o jsonpath="{.spec.selector.matchLabels.app}")" = 'api' ]; then
  echo "✖ Failed: deployment/api-gateway: selector app=api" && exit 1
fi
echo "- Checking: deployment/api-gateway: selector tier=edge"
if ! [ "$(kubectl get deploy 'api-gateway' -n 'platform' -o jsonpath="{.spec.selector.matchLabels.tier}")" = 'edge' ]; then
  echo "✖ Failed: deployment/api-gateway: selector tier=edge" && exit 1
fi
echo "- Checking: service/api-gateway-svc: selector app=api"
if ! [ "$(kubectl get svc 'api-gateway-svc' -n 'platform' -o jsonpath="{.spec.selector.app}")" = 'api' ]; then
  echo "✖ Failed: service/api-gateway-svc: selector app=api" && exit 1
fi
echo "- Checking: service/api-gateway-svc: selector tier=edge"
if ! [ "$(kubectl get svc 'api-gateway-svc' -n 'platform' -o jsonpath="{.spec.selector.tier}")" = 'edge' ]; then
  echo "✖ Failed: service/api-gateway-svc: selector tier=edge" && exit 1
fi
echo "- Checking: service/api-gateway-svc: port[http]=8080"
if ! [ "$(kubectl get svc 'api-gateway-svc' -n 'platform' -o jsonpath="{.spec.ports[?(@.name=='http')].port}")" = '8080' ]; then
  echo "✖ Failed: service/api-gateway-svc: port[http]=8080" && exit 1
fi
echo "- Checking: service/api-gateway-svc: targetPort[http]=80"
if ! [ "$(kubectl get svc 'api-gateway-svc' -n 'platform' -o jsonpath="{.spec.ports[?(@.name=='http')].targetPort}")" = '80' ]; then
  echo "✖ Failed: service/api-gateway-svc: targetPort[http]=80" && exit 1
fi

# Collect manifests to feed Kubelingo AI validator (optional)
USER_MANIFEST=''
USER_MANIFEST+=$'---
'
USER_MANIFEST+="$(kubectl get deployment 'api-gateway' -n 'platform' -o yaml)"
USER_MANIFEST+=$'
'
USER_MANIFEST+=$'---
'
USER_MANIFEST+="$(kubectl get service 'api-gateway-svc' -n 'platform' -o yaml)"
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

echo "Validation passed: In the namespace 'platform', create a Deployment named 'api-gateway' with exactly 2 replicas."
