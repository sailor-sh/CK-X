#!/bin/bash

# Validate readiness and liveness probes: HTTP GET /healthz on port 80, periodSeconds 10
NAMESPACE="platform"
DEPLOYMENT="api-gateway"

if ! kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Error: Deployment '$DEPLOYMENT' not found in namespace '$NAMESPACE'"
  exit 1
fi

RP=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}' 2>/dev/null)
LP=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}' 2>/dev/null)

if [ -z "$RP" ]; then
  echo "Error: readinessProbe not configured"
  exit 1
fi
if [ -z "$LP" ]; then
  echo "Error: livenessProbe not configured"
  exit 1
fi

RP_METHOD=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null)
RP_PORT=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}' 2>/dev/null)
RP_PERIOD=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.periodSeconds}' 2>/dev/null)

LP_METHOD=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}' 2>/dev/null)
LP_PORT=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.port}' 2>/dev/null)
LP_PERIOD=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.periodSeconds}' 2>/dev/null)

if [ "$RP_METHOD" != "/healthz" ] || [ "$LP_METHOD" != "/healthz" ]; then
  echo "Error: Expected probe path '/healthz' (got readiness='$RP_METHOD', liveness='$LP_METHOD')"
  exit 1
fi

if [ "$RP_PORT" != "80" ] || [ "$LP_PORT" != "80" ]; then
  echo "Error: Expected probe port 80 (got readiness='$RP_PORT', liveness='$LP_PORT')"
  exit 1
fi

if [ "$RP_PERIOD" != "10" ] || [ "$LP_PERIOD" != "10" ]; then
  echo "Error: Expected periodSeconds 10 (got readiness='$RP_PERIOD', liveness='$LP_PERIOD')"
  exit 1
fi

echo "Success: Probes configured with HTTP GET /healthz on port 80, periodSeconds 10"
exit 0

