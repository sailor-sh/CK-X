
# First, let's analyze the PDF content structure and extract the questions
pdf_content = """
Question 1 | Namespaces - List namespaces, save to /opt/course/1/namespaces
Question 2 | Pods - Create pod1 with httpd:2.4.41-alpine, write status command to /opt/course/2/pod1-status-command.sh
Question 3 | Job - Create job neb-new-job in namespace neptune, 3 completions, 2 parallel
Question 4 | Helm Management - Delete/upgrade/install helm releases in namespace mercury
Question 5 | ServiceAccount, Secret - Extract token from ServiceAccount neptune-sa-v2
Question 6 | ReadinessProbe - Create pod6 with readiness probe, touch /tmp/ready
Question 7 | Pods, Namespaces - Find pod webserver-sat-003, move to neptune namespace
Question 8 | Deployment, Rollouts - Fix deployment api-new-c32 rollback issue
Question 9 | Pod -> Deployment - Convert Pod holy-api to Deployment with 3 replicas
Question 10 | Service, Logs - Create ClusterIP service, test with curl, capture logs
Question 11 | Working with Containers - Build docker/podman images with ENV variable
Question 12 | Storage, PV, PVC, Pod volume - Create PV, PVC, mount in deployment
Question 13 | Storage, StorageClass, PVC - Create StorageClass moon-retain, PVC moon-pvc-126
Question 14 | Secret, Secret-Volume, Secret-Env - Create secrets, mount as volume and env vars
Question 15 | ConfigMap, Configmap-Volume - Create ConfigMap from file, mount in deployment
Question 16 | Logging sidecar - Add logger-con sidecar to existing deployment
Question 17 | InitContainer - Add init container to create index.html
Question 18 | Service misconfiguration - Fix service selector labels
Question 19 | Service ClusterIP->NodePort - Change service type to NodePort port 30100
Preview 1 | LivenessProbe - Add TCP liveness probe to project-23-api deployment
Preview 2 | ServiceAccount - Create deployment with ServiceAccount, expose service
Preview 3 | ReadinessProbe - Fix readiness probe port misconfiguration
"""

# Extract structured information about each question
questions_data = {
    "q1": {
        "title": "Namespaces",
        "namespace": "default",
        "instance": "ckad5601",
        "task": "Get list of all namespaces and save to /opt/course/1/namespaces",
        "command": "kubectl get ns > /opt/course/1/namespaces",
        "type": "get_resource"
    },
    "q2": {
        "title": "Pods",
        "namespace": "default",
        "instance": "ckad5601",
        "task": "Create Pod pod1 (httpd:2.4.41-alpine, container name: pod1-container)",
        "subtask": "Write status command to /opt/course/2/pod1-status-command.sh",
        "type": "pod_creation"
    },
    "q3": {
        "title": "Job",
        "namespace": "neptune",
        "instance": "ckad7326",
        "task": "Create Job neb-new-job (busybox:1.31.0, 3 completions, 2 parallel)",
        "specs": {
            "image": "busybox:1.31.0",
            "command": "sleep 2 && echo done",
            "completions": 3,
            "parallelism": 2,
            "labels": {"id": "awesome-job"},
            "container_name": "neb-new-job-container"
        },
        "type": "job_creation"
    },
}

print("✓ Extracted question metadata structure")
print(f"Total questions in exam: 19 + 3 preview = 22 questions")
print("\nKey observations:")
print("- Questions span 2 instances: ckad5601, ckad7326, ckad9043")
print("- Namespaces used: default, neptune, earth, mercury, mars, jupiter, pluto, moon, sun")
print("- Topics: Pods, Jobs, Helm, Deployments, Storage, Services, Containers, Logging")
