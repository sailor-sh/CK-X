#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

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

echo "Validation passed."

