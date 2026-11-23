#!/bin/bash
# Validate that the test pod exists

POD_NAME="test-pod"
NAMESPACE="metadata-protect"

# Check if pod exists
kubectl get pod $POD_NAME -n $NAMESPACE &> /dev/null
if [ $? -ne 0 ]; then
  echo "❌ Pod '$POD_NAME' not found in namespace '$NAMESPACE'"
  exit 1
fi

# Check if pod is running
POD_STATUS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
  echo "❌ Pod '$POD_NAME' is not in Running state (current state: $POD_STATUS)"
  exit 1
fi

# Check if pod uses the busybox image as required
POD_IMAGE=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].image}')
if [[ "$POD_IMAGE" != *"busybox"* ]]; then
  echo "❌ Pod '$POD_NAME' is not using the busybox image (current image: $POD_IMAGE)"
  exit 1
fi

# kubectl run puts the command in args unless --command is supplied.
# Keep argument boundaries and inspect the executable, not arbitrary text.
# Shell support is limited to one literal sleep invocation; never evaluate it.
POD_RUNS_SLEEP=$(kubectl get pod $POD_NAME -n $NAMESPACE -o json | jq -r '
  .spec.containers[0]
  | ((.command // []) + (.args // [])) as $argv
  | if (["sleep", "/bin/sleep", "/usr/bin/sleep"] | index($argv[0])) != null then
      true
    elif (["busybox", "/bin/busybox"] | index($argv[0])) != null then
      $argv[1] == "sleep"
    elif (["sh", "/bin/sh", "ash", "/bin/ash"] | index($argv[0])) != null
      and (["-c", "-ec", "-ce"] | index($argv[1])) != null then
      ($argv[2] // "" | test(
        "\\A[ \\t\\r\\n]*(exec[ \\t]+)?((/(usr/)?bin/)?sleep|(/bin/)?busybox[ \\t]+sleep)([ \\t]+[-[:alnum:]_.+]+)+[ \\t]*;?[ \\t\\r\\n]*\\z"
      ))
    else
      false
    end
')
if [ "$POD_RUNS_SLEEP" != "true" ]; then
  echo "❌ Pod '$POD_NAME' is not running sleep command"
  exit 1
fi

echo "✅ Test pod exists and is correctly configured"
exit 0 