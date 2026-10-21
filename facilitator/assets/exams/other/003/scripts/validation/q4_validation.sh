#!/bin/bash
set -e

# Validation for Question 4: Observability and Monitoring Stack
echo "Validating Observability and Monitoring Stack scenario..."

# Check if monitoring namespace exists
if ! kubectl get namespace monitoring &> /dev/null; then
    echo "FAIL: Namespace 'monitoring' not found"
    exit 1
fi

# Check if Prometheus deployment exists
if ! kubectl get deployment prometheus -n monitoring &> /dev/null; then
    echo "FAIL: Deployment 'prometheus' not found in namespace monitoring"
    exit 1
fi

# Check if Grafana deployment exists
if ! kubectl get deployment grafana -n monitoring &> /dev/null; then
    echo "FAIL: Deployment 'grafana' not found in namespace monitoring"
    exit 1
fi

# Check if Jaeger deployment exists
if ! kubectl get deployment jaeger -n monitoring &> /dev/null; then
    echo "FAIL: Deployment 'jaeger' not found in namespace monitoring"
    exit 1
fi

# Check if Elasticsearch deployment exists
if ! kubectl get deployment elasticsearch -n monitoring &> /dev/null; then
    echo "FAIL: Deployment 'elasticsearch' not found in namespace monitoring"
    exit 1
fi

# Check if Fluentd DaemonSet exists
if ! kubectl get daemonset fluentd -n monitoring &> /dev/null; then
    echo "FAIL: DaemonSet 'fluentd' not found in namespace monitoring"
    exit 1
fi

# Check Prometheus readiness
PROMETHEUS_READY=$(kubectl get deployment prometheus -n monitoring -o jsonpath='{.status.readyReplicas}')
if [ "$PROMETHEUS_READY" != "1" ]; then
    echo "FAIL: Prometheus should have 1 ready replica, found: $PROMETHEUS_READY"
    exit 1
fi

# Check Grafana readiness
GRAFANA_READY=$(kubectl get deployment grafana -n monitoring -o jsonpath='{.status.readyReplicas}')
if [ "$GRAFANA_READY" != "1" ]; then
    echo "FAIL: Grafana should have 1 ready replica, found: $GRAFANA_READY"
    exit 1
fi

# Check Jaeger readiness
JAEGER_READY=$(kubectl get deployment jaeger -n monitoring -o jsonpath='{.status.readyReplicas}')
if [ "$JAEGER_READY" != "1" ]; then
    echo "FAIL: Jaeger should have 1 ready replica, found: $JAEGER_READY"
    exit 1
fi

# Check if services exist
REQUIRED_SERVICES=("prometheus-service" "grafana-service" "jaeger-service" "elasticsearch-service")
for svc in "${REQUIRED_SERVICES[@]}"; do
    if ! kubectl get service "$svc" -n monitoring &> /dev/null; then
        echo "FAIL: Service '$svc' not found in namespace monitoring"
        exit 1
    fi
done

# Check if ServiceMonitor exists for Prometheus
if ! kubectl get servicemonitor microservices-monitor -n monitoring &> /dev/null; then
    echo "WARN: ServiceMonitor 'microservices-monitor' not found (may not be supported)"
fi

# Check if ConfigMaps exist for configuration
REQUIRED_CONFIGMAPS=("prometheus-config" "grafana-config")
for cm in "${REQUIRED_CONFIGMAPS[@]}"; do
    if ! kubectl get configmap "$cm" -n monitoring &> /dev/null; then
        echo "FAIL: ConfigMap '$cm' not found in namespace monitoring"
        exit 1
    fi
done

# Check if PVC exists for data persistence
if ! kubectl get pvc prometheus-data -n monitoring &> /dev/null; then
    echo "FAIL: PVC 'prometheus-data' not found in namespace monitoring"
    exit 1
fi

echo "PASS: Observability and Monitoring Stack validation successful"
