# Validate if the pods of deployment 'nice-app' are running in the 'app' namespace
#check deployment status is runing or not
ENDPOINT_STATUS=$(kubectl get ep nice-app -n app -o jsonpath='{.subsets[0].addresses}' 2>/dev/null)

if [ -z "$ENDPOINT_STATUS" ]; then
    echo "Error: Endpoint status is empty"
    exit 1
else
    echo "Success: The Service works fine!"
    exit 0
fi
