# validate the container image is correct having image name nginx
# Validate if the pods of deployment 'broken-app' are running in the 'troubleshooting' namespace
#check deployment status is runing or not
DEPLOYMENT_STATUS=$(kubectl get deployment broken-app -n troubleshooting -o jsonpath='{.status.conditions[?(@.type=="Available")].status}')
if [ "$DEPLOYMENT_STATUS" != "True" ]; then
    echo "Error: The deployment 'broken-app' is not running"
    exit 1
fi

IMAGE=$(kubectl get deployment broken-app -n troubleshooting -o jsonpath='{.spec.template.spec.containers[0].image}' | cut -d':' -f1)

if [ "$IMAGE" == "nginx" ]; then
    echo "Success: The container image is correct"
    exit 0
else
    echo "Error: The container image is not correct"
    exit 1
fi