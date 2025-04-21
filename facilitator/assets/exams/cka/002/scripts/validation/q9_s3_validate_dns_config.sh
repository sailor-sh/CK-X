#!/bin/bash
set -e

# Check if ConfigMap exists
kubectl get configmap dns-config -n dns-debug || {
    echo "ConfigMap dns-config not found in namespace dns-debug"
    exit 1
}

# Check if test pod uses the ConfigMap
DNS_CONFIG=$(kubectl get pod dns-test -n dns-debug -o jsonpath='{.spec.dnsConfig}')
if [[ -z "$DNS_CONFIG" ]]; then
    echo "Pod dns-test does not have custom DNS configuration"
    exit 1
fi

# Check if pod has correct DNS policy
DNS_POLICY=$(kubectl get pod dns-test -n dns-debug -o jsonpath='{.spec.dnsPolicy}')
if [[ "$DNS_POLICY" != "None" ]] && [[ "$DNS_POLICY" != "ClusterFirst" ]]; then
    echo "Incorrect DNS policy. Expected None or ClusterFirst, got $DNS_POLICY"
    exit 1
fi

# Check if search domains are configured
SEARCH_DOMAINS=$(kubectl get pod dns-test -n dns-debug -o jsonpath='{.spec.dnsConfig.searches[*]}')
if [[ -z "$SEARCH_DOMAINS" ]]; then
    echo "No search domains configured in pod's DNS config"
    exit 1
fi

echo "DNS configuration validation successful"
exit 0 