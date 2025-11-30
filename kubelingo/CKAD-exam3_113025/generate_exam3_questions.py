#!/usr/bin/env python3
"""
Generate CK-X Exam 3 Questions from Killer Shell PDF
File: generate_exam3_questions.py

Usage:
    python3 generate_exam3_questions.py [--output-dir exams/exam3]
"""

import os
import yaml
import json
from pathlib import Path
from dataclasses import dataclass, asdict

@dataclass
class Question:
    """Question definition for exam3"""
    num: int
    title: str
    namespace: str
    difficulty: str
    timeout: int
    task: str
    setup_resources: list = None
    validation_checks: dict = None
    
    def __post_init__(self):
        if self.setup_resources is None:
            self.setup_resources = []
        if self.validation_checks is None:
            self.validation_checks = {}

# All 22 questions from Killer Shell PDF
EXAM3_QUESTIONS = [
    Question(
        num=1,
        title="List Namespaces",
        namespace="ckad-q01",
        difficulty="easy",
        timeout=300,
        task="""The DevOps team would like to get the list of all Namespaces in the cluster.
The list can contain other columns like STATUS or AGE.
Save the list to /opt/course/exam3/q01/namespaces on localhost.

Command: mkdir -p /opt/course/exam3/q01 && kubectl get ns > /opt/course/exam3/q01/namespaces""",
        validation_checks={
            "file_exists": "/opt/course/exam3/q01/namespaces",
            "file_contains": ["NAME", "default"]
        }
    ),
    
    Question(
        num=2,
        title="Create Pod and Status Command",
        namespace="ckad-q02",
        difficulty="easy",
        timeout=300,
        task="""The operations team requires a simple web server to be deployed for connectivity testing.
Your task is to create a Pod to host the web server and also to provide a shell script that can be used to check the pod's status.

All resources should be created in the `ckad-q02` namespace.

**Task 1: Create the Web Server Pod**

Create a Pod with the following specifications:

| Property         | Value              |
| ---------------- | ------------------ |
| Pod Name         | `pod1`             |
| Container Name   | `pod1-container`   |
| Image            | `httpd:2.4.41-alpine` |

**Task 2: Create the Status Check Script**

Your manager wants a simple script to quickly check the status of the new pod.

Create a script with the following specifications:

| Property          | Value                                         |
| ----------------- | --------------------------------------------- |
| File Path         | `/opt/course/exam3/q02/pod1-status-command.sh`  |
| Permissions       | Executable (`+x`)                             |
| Script Content    | The script must contain a single `kubectl` command that outputs the `.status.phase` of the `pod1` Pod. |

**Hint:** You can use `kubectl` with a `jsonpath` output expression to extract a specific field from a resource. For example: `kubectl get pod <pod-name> -o jsonpath='{.status.phase}'`. Remember to include the shebang `#!/bin/bash` in your script.""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-q02"}},
        ],
        validation_checks={
            "pod_exists": {"name": "pod1", "namespace": "ckad-q02"},
            "pod_container_name": {"name": "pod1-container"},
            "file_exists": "/opt/course/exam3/q02/pod1-status-command.sh"
        }
    ),
    
    Question(
        num=3,
        title="Job with Parallelism",
        namespace="ckad-q03",
        difficulty="medium",
        timeout=600,
        task="""Team Neptune requires a parallel Job to run a series of computations.

Your task is to create the Job and save its manifest. All resources should be in the `ckad-q03` namespace.

**Task 1: Create the Job**

Create a Job with the following specifications:

| Property           | Value                           |
| ------------------ | ------------------------------- |
| Job Name           | `neb-new-job`                   |
| Container Name     | `neb-new-job-container`         |
| Image              | `busybox:1.31.0`                |
| Command            | `sleep 2 && echo done`          |
| Completions        | `3`                             |
| Parallelism        | `2`                             |
| Pod Label          | `id: awesome-job`               |

Once created, ensure the Job is started and runs to completion.

**Task 2: Save the Manifest**

Save the YAML manifest for the `neb-new-job` Job to the following location:

| Property  | Value                          |
| --------- | ------------------------------ |
| File Path | `/opt/course/exam3/q03/job.yaml` |

""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-q03"}},
        ],
        validation_checks={
            "job_exists": {"name": "neb-new-job", "namespace": "ckad-q03"},
            "job_completions": 3,
            "job_parallelism": 2,
            "job_label": {"key": "id", "value": "awesome-job"},
            "file_exists": "/opt/course/exam3/q03/job.yaml"
        }
    ),
    
    Question(
        num=4,
        title="Helm Management",
        namespace="ckad-q04",
        difficulty="medium",
        timeout=600,
        task="""The Mercury team needs you to perform several Helm operations in the `ckad-q04` namespace.

**Task 1: Add and Update Helm Repository**

First, add the `killershell` repository and update your local repo information:

```bash
helm repo add killershell http://localhost:6000 && helm repo update
```

**Task 2: Manage Helm Releases**

Perform the following actions on the Helm releases:

1.  **Delete** the `internal-issue-report-apiv1` release.
2.  **Upgrade** the `internal-issue-report-apiv2` release to any newer version of the `killershell/nginx` chart.
3.  **Install** a new release named `internal-issue-report-apache` from the `killershell/apache` chart.
    *   The `Deployment` should have **two replicas**. Set this value during installation using the `--set` flag or a custom values file.
4.  **Find and delete** any releases that are stuck in the `pending-install` state.""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-q04"}},
        ],
        validation_checks={
            "helm_release_exists": {"name": "internal-issue-report-apache", "namespace": "ckad-q04"},
            "helm_release_count": 2
        }
    ),
    
    Question(
        num=5,
        title="ServiceAccount and Secret Token",
        namespace="ckad-q05",
        difficulty="easy",
        timeout=300,
        task="""Team Neptune has its own ServiceAccount, `neptune-sa-v2`, in the `ckad-q05` namespace.
A coworker needs the authentication token from the Secret that is automatically generated for this ServiceAccount.

Your task is to retrieve the token, decode it from base64, and save it to a file.

**Specifications:**

| Property           | Value                                  |
| ------------------ | -------------------------------------- |
| ServiceAccount Name| `neptune-sa-v2`                          |
| Namespace          | `ckad-q05`                             |
| Output File Path   | `/opt/course/exam3/q05/token`          |

**Hint:** First, you will need to identify the Secret associated with the `neptune-sa-v2` ServiceAccount. Then, you can retrieve the token data from that Secret. The token is base64 encoded, so you will need to decode it. You can use `kubectl get secret <secret-name> -o jsonpath='{.data.token}' | base64 --decode`.""",,
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-q05"}},
            {"kind": "ServiceAccount", "metadata": {"name": "neptune-sa-v2", "namespace": "ckad-q05"}},
        ],
        validation_checks={
            "file_exists": "/opt/course/exam3/q05/token",
            "file_not_empty": "/opt/course/exam3/q05/token"
        }
    ),
    
    Question(
        num=6,
        title="ReadinessProbe",
        namespace="ckad-q06",
        difficulty="medium",
        timeout=300,
        task="""A developer needs a Pod that only becomes 'Ready' after a specific condition is met.
You are tasked with creating a Pod that uses a `readinessProbe` to check for the existence of a file.

All resources should be in the `ckad-q06` namespace.

**Pod Specifications:**

| Property         | Value                          |
| ---------------- | ------------------------------ |
| Pod Name         | `pod6`                         |
| Image            | `busybox:1.31.0`               |
| Command          | `touch /tmp/ready && sleep 1d` |

**Readiness Probe Specifications:**

| Property           | Value              |
| ------------------ | ------------------ |
| Type               | `exec`             |
| Command            | `cat /tmp/ready`   |
| Initial Delay (s)  | `5`                |
| Period (s)         | `10`               |

Create the Pod and then verify that it starts and its status eventually becomes 'Running' and 'Ready'.
""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-q06"}},
        ],
        validation_checks={
            "pod_exists": {"name": "pod6", "namespace": "ckad-q06"},
            "pod_ready": {"name": "pod6", "namespace": "ckad-q06"}
        }
    ),
    
    Question(
        num=7,
        title="Move Pod Between Namespaces",
        namespace="ckad-q07",
        difficulty="hard",
        timeout=600,
        task="""The Neptune team is taking over an e-commerce webserver from Team Saturn. Your task is to locate and migrate the `my-happy-shop` Pod from its current namespace to a new target namespace.

**Namespaces:**
*   Source Namespace: `ckad-q07-source`
*   Target Namespace: `ckad-q07-target`

**Task 1: Identify the Pod**

Locate the Pod in the `ckad-q07-source` namespace that is associated with the `my-happy-shop` e-commerce system.
**Hint:** The Pod will have an annotation that identifies it as part of `my-happy-shop`. You can use `kubectl get pod -n <namespace> -o yaml` and then search for annotations.

**Task 2: Migrate the Pod**

Migrate the identified Pod from `ckad-q07-source` to `ckad-q07-target`. You can achieve this by:
1.  Extracting the Pod's YAML definition.
2.  Modifying the `namespace` field in the YAML to `ckad-q07-target`.
3.  Deleting the original Pod from `ckad-q07-source`.
4.  Creating the Pod in `ckad-q07-target` using the modified YAML.

**Task 3: Verify Migration**

Confirm that the Pod is successfully running in `ckad-q07-target` and is no longer present in `ckad-q07-source`.""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-q07-source"}},
            {"kind": "Namespace", "metadata": {"name": "ckad-q07-target"}},
            # Will add Pod in source namespace via setup script
        ],
        validation_checks={
            "pod_exists_in_namespace": {"name": "webserver-sat-003", "namespace": "ckad-q07-target"},
            "pod_not_exists_in_namespace": {"name": "webserver-sat-003", "namespace": "ckad-q07-source"}
        }
    ),
    
    Question(
        num=8,
        title="Deployment Rollback",
        namespace="ckad-q08",
        difficulty="hard",
        timeout=600,
        task="""An issue has occurred with an existing Deployment named `api-new-c32` in the `ckad-q08` namespace. A recent update caused the Deployment to fail, and the new version never became ready.

Your tasks are to identify a stable revision, perform a rollback, and document the cause of the failure.

**Namespace:** `ckad-q08`

**Task 1: Investigate and Rollback**

1.  **Examine the Deployment history** for `api-new-c32` to find previous revisions.
    *   **Hint:** Use `kubectl rollout history deployment/<deployment-name>` and `kubectl rollout undo deployment/<deployment-name> --to-revision=<revision-number>`.
2.  **Identify a working revision** from the history.
3.  **Perform a rollback** to the identified working revision.
4.  **Verify** that the Deployment is stable and all Pods are running.

**Task 2: Document the Error**

After fixing the Deployment, determine what caused the original update to fail.

1.  **Identify the specific error** that prevented the updated version from coming online.
2.  **Explain the error concisely** to help prevent similar issues in the future.""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-q08"}},
        ],
        validation_checks={
            "deployment_exists": {"name": "api-new-c32", "namespace": "ckad-q08"},
            "deployment_ready": {"name": "api-new-c32", "namespace": "ckad-q08"}
        }
    ),
    
    Question(
        num=9,
        title="Convert Pod to Deployment",
        namespace="ckad-q09",
        difficulty="medium",
        timeout=600,
        task="""A simple API, currently running as a single Pod named `holy-api`, needs to be made more reliable.
Your task is to convert the existing Pod into a high-availability Deployment.

The existing Pod is in the `ckad-q09` namespace.

**Task 1: Create the Deployment**

Create a new Deployment with the following specifications, based on the existing `holy-api` Pod:

| Property                 | Value                                        |
| ------------------------ | -------------------------------------------- |
| Deployment Name          | `holy-api`                                   |
| Replicas                 | `3`                                          |
| Security Context (Container Level) | `allowPrivilegeEscalation: false`, `privileged: false` |

Once the Deployment is running successfully, delete the original `holy-api` Pod.

**Task 2: Save the Manifest**

Save the YAML manifest for the new `holy-api` Deployment to the following file:

| Property  | Value                                       |
| --------- | ------------------------------------------- |
| File Path | `/opt/course/exam3/q09/holy-api-deployment.yaml` |
""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-q09"}},
        ],
        validation_checks={
            "deployment_exists": {"name": "holy-api", "namespace": "ckad-q09"},
            "deployment_replicas": 3,
            "file_exists": "/opt/course/exam3/q09/holy-api-deployment.yaml"
        }
    ),
    
    Question(
        num=10,
        title="Service and Logs",
        namespace="ckad-q10",
        difficulty="medium",
        timeout=600,
        task="""A new internal service needs to be deployed and tested. This involves creating a Pod, exposing it via a Service, and then verifying connectivity and logging.

All resources should be created in the `ckad-q10` namespace.

**Task 1: Create the Pod**

| Property         | Value                   |
| ---------------- | ----------------------- |
| Pod Name         | `project-plt-6cc-api`   |
| Image            | `nginx:1.17.3-alpine`   |
| Label            | `project: plt-6cc-api`  |

**Task 2: Create the Service**

| Property         | Value                   |
| ---------------- | ----------------------- |
| Service Name     | `project-plt-6cc-svc`   |
| Service Type     | `ClusterIP`             |
| Port Mapping     | `3333:80` (TCP)         |
| Selector         | `project: plt-6cc-api`  |

**Task 3: Test the Service and Save Artifacts**

1.  From a temporary `nginx:alpine` Pod, use `curl` to access the `project-plt-6cc-svc` service.
2.  Save the HTML response from the `curl` command to `/opt/course/exam3/q10/service_test.html`.
3.  Retrieve the logs from the `project-plt-6cc-api` Pod.
4.  Save the logs to `/opt/course/exam3/q10/service_test.log`.
""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-q10"}},
        ],
        validation_checks={
            "service_exists": {"name": "project-plt-6cc-svc", "namespace": "ckad-q10"},
            "pod_exists": {"name": "project-plt-6cc-api", "namespace": "ckad-q10"},
            "file_exists": "/opt/course/exam3/q10/service_test.html",
            "file_exists": "/opt/course/exam3/q10/service_test.log"
        }
    ),
    
    Question(
        num=11,
        title="Build Container Images",
        namespace="ckad-q11",
        difficulty="hard",
        timeout=900,
        task="""You are provided with a set of files at `/opt/course/exam3/q11/image` on `localhost` for building a container image. This container will execute a Golang application that writes output to `stdout`.

Your tasks involve modifying the Dockerfile, building and pushing the image using both Docker and Podman, running a Podman container, and capturing its logs.

**Task 1: Modify the Dockerfile**

Edit the Dockerfile located in `/opt/course/exam3/q11/image` to set the `ENV` variable `SUN_CIPHER_ID` to the value `5b9c1065-e39d-4a43-a04a-e59bcea3e03f`.

**Task 2: Build and Push Images**

1.  **Build with Docker:**
    *   Build the image using `docker`.
    *   Tag the image as `registry.killer.sh:5000/sun-cipher:v1-docker`.
    *   Push the tagged Docker image to the registry.
2.  **Build with Podman:**
    *   Build the image using `podman`.
    *   Tag the image as `registry.killer.sh:5000/sun-cipher:v1-podman`.
    *   Push the tagged Podman image to the registry.

**Task 3: Run Podman Container and Capture Logs**

1.  **Run Container:**
    *   Run a new container using `podman` from the `registry.killer.sh:5000/sun-cipher:v1-podman` image.
    *   Name the container `sun-cipher`.
    *   Ensure the container runs in detached mode (in the background).
2.  **Capture Logs:**
    *   Write all logs produced by the `sun-cipher` container into the file `/opt/course/exam3/q11/logs` on `localhost`.

**Note:** You may need to run `docker` and `podman` commands as `root` (e.g., using `sudo`).""",
        validation_checks={
            "file_exists": "/opt/course/exam3/q11/logs",
            "file_contains": "SUN_CIPHER_ID"
        }
    ),
    
    Question(
        num=12,
        title="Storage: PV, PVC, and Pod Volume",
        namespace="ckad-q12",
        difficulty="medium",
        timeout=600,
        task="""A new application requires persistent storage. Your task is to provision a PersistentVolume, claim it with a PersistentVolumeClaim, and consume it within a Deployment.

All namespaced resources should be in `ckad-q12`.

**Task 1: Create the PersistentVolume**

| Property         | Value                          |
| ---------------- | ------------------------------ |
| PV Name          | `earth-project-earthflower-pv` |
| Capacity         | `2Gi`                          |
| Access Modes     | `ReadWriteOnce`                |
| Host Path        | `/Volumes/Data`                |
| Storage Class    | (none)                         |

**Task 2: Create the PersistentVolumeClaim**

| Property         | Value                          |
| ---------------- | ------------------------------ |
| PVC Name         | `earth-project-earthflower-pvc`|
| Namespace        | `ckad-q12`                     |
| Capacity Request | `2Gi`                          |
| Access Modes     | `ReadWriteOnce`                |
| Storage Class    | (none)                         |

After creation, verify that the PVC successfully binds to the PV.

**Task 3: Create the Deployment**

| Property         | Value                          |
| ---------------- | ------------------------------ |
| Deployment Name  | `project-earthflower`          |
| Namespace        | `ckad-q12`                     |
| Image            | `httpd:2.4.41-alpine`          |
| Volume Name      | `project-data-vol` (example)   |
| Volume Mount Path| `/tmp/project-data`            |
| PVC to Use       | `earth-project-earthflower-pvc`|
""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-q12"}},
        ],
        validation_checks={
            "pv_exists": "earth-project-earthflower-pv",
            "pvc_exists": {"name": "earth-project-earthflower-pvc", "namespace": "ckad-q12"},
            "pvc_bound": True,
            "deployment_exists": {"name": "project-earthflower", "namespace": "ckad-q12"}
        }
    ),
    
    Question(
        num=13,
        title="StorageClass and PersistentVolumeClaim",
        namespace="ckad-q13",
        difficulty="medium",
        timeout=600,
        task="""Team Moonpie needs to dynamically provision storage using a custom StorageClass that is not yet available. Your task is to create the StorageClass and a PersistentVolumeClaim that uses it.

All namespaced resources should be in `ckad-q13`.

**Task 1: Create the StorageClass**

| Property         | Value             |
| ---------------- | ----------------- |
| SC Name          | `moon-retain`     |
| Provisioner      | `moon-retainer`   |
| Reclaim Policy   | `Retain`          |

**Task 2: Create the PersistentVolumeClaim**

| Property         | Value             |
| ---------------- | ----------------- |
| PVC Name         | `moon-pvc-126`    |
| Namespace        | `ckad-q13`        |
| Capacity Request | `3Gi`             |
| Access Modes     | `ReadWriteOnce`   |
| Storage Class    | `moon-retain`     |

**Task 3: Verify and Document**

The `moon-retainer` provisioner does not exist, so the PVC will remain in a `Pending` state.
1.  Verify that the PVC status is `Pending`.
2.  Extract the event message associated with the pending PVC.
3.  Save this message to the file `/opt/course/exam3/q13/pvc-126-reason`.
""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-q13"}},
        ],
        validation_checks={
            "storageclass_exists": "moon-retain",
            "pvc_exists": {"name": "moon-pvc-126", "namespace": "ckad-q13"},
            "pvc_status": "Pending",
            "file_exists": "/opt/course/exam3/q13/pvc-126-reason"
        }
    ),
    
    Question(
        num=14,
        title="Secret as Environment Variable and Volume",
        namespace="ckad-q14",
        difficulty="medium",
        timeout=600,
        task="""An existing Pod named `secret-handler` in the `ckad-q14` namespace needs to be updated to consume a Secret as environment variables and a ConfigMap as a volume.

**Task 1: Create the Secret**

Create a Secret with the following specifications:

| Property         | Value        |
| ---------------- | ------------ |
| Secret Name      | `secret1`    |
| Namespace        | `ckad-q14`   |
| Data             | `user=test`, `pass=pwd` |

**Task 2: Create the ConfigMap**

Create a ConfigMap with the following specifications:

| Property         | Value        |
| ---------------- | ------------ |
| ConfigMap Name   | `secret2`    |
| Namespace        | `ckad-q14`   |
| Data             | (empty, or specify a dummy key-value pair if required for validation) |

**Task 3: Modify the Existing Pod**

Modify the `secret-handler` Pod (which is provided by the setup) in `ckad-q14` to:

1.  Make the `secret1` data (`user`, `pass`) available as environment variables named `SECRET1_USER` and `SECRET1_PASS` respectively.
2.  Mount the `secret2` ConfigMap as a volume at the path `/tmp/secret2` inside the Pod.

**Task 4: Save the Pod Manifest**

Save the YAML manifest of the modified `secret-handler` Pod to the following location:

| Property  | Value                                        |
| --------- | -------------------------------------------- |
| File Path | `/opt/course/exam3/q14/secret-handler-new.yaml` |
""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-q14"}},
        ],
        validation_checks={
            "secret_exists": {"name": "secret1", "namespace": "ckad-q14"},
            "pod_exists": {"name": "secret-handler", "namespace": "ckad-q14"},
            "file_exists": "/opt/course/exam3/q14/secret-handler-new.yaml"
        }
    ),
    
    Question(
        num=15,
        title="ConfigMap and ConfigMap Volume",
        namespace="ckad-q15",
        difficulty="medium",
        timeout=600,
        task="""Team Moonpie has a nginx server Deployment called web-moon in Namespace ckad-q15.
Someone started configuring it but it was never completed.

To complete, create a ConfigMap called configmap-web-moon-html
containing the content of file /opt/course/exam3/q15/web-moon.html
under the data key-name: index.html

The Deployment web-moon is already configured to work with this ConfigMap and serve its content.
Test the nginx configuration for example using curl from a temporary nginx:alpine Pod.

Save your ConfigMap definition to /opt/course/exam3/q15/configmap.yaml""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-q15"}},
        ],
        validation_checks={
            "configmap_exists": {"name": "configmap-web-moon-html", "namespace": "ckad-q15"},
            "file_exists": "/opt/course/exam3/q15/configmap.yaml"
        }
    ),
    
    Question(
        num=16,
        title="Logging Sidecar Container",
        namespace="ckad-q16",
        difficulty="hard",
        timeout=600,
        task="""The Tech Lead decided it's time for more logging. There is an existing container named cleaner-con
in Deployment cleaner in Namespace ckad-q16.
This container mounts a volume and writes logs into a file called cleaner.log.

The yaml for the existing Deployment is available at /opt/course/exam3/q16/cleaner.yaml.
Persist your changes at /opt/course/exam3/q16/cleaner-new.yaml and make sure the Deployment is running.

Create a sidecar container named logger-con, image busybox:1.31.0, which mounts the same volume
and writes the content of cleaner.log to stdout using: tail -f /var/log/cleaner/cleaner.log
This way it can be picked up by kubectl logs.

Check if the logs of the new container reveal something about missing data incidents.""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-q16"}},
        ],
        validation_checks={
            "deployment_exists": {"name": "cleaner", "namespace": "ckad-q16"},
            "file_exists": "/opt/course/exam3/q16/cleaner-new.yaml"
        }
    ),
    
    Question(
        num=17,
        title="InitContainer",
        namespace="ckad-q17",
        difficulty="medium",
        timeout=600,
        task="""Your coworker would like to see an InitContainer in action.
There is a Deployment yaml at /opt/course/exam3/q17/test-init-container.yaml.
This Deployment spins up a single Pod of image nginx:1.17.3-alpine and serves files from a mounted volume,
which is empty right now.

Create an InitContainer named init-con which also mounts that volume and creates a file index.html
with content "check this out!" in the root of the mounted volume.

The InitContainer should be using image busybox:1.31.0.
Test your implementation for example using curl from a temporary nginx:alpine Pod.

Save your modified Deployment to /opt/course/exam3/q17/test-init-container-new.yaml""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-q17"}},
        ],
        validation_checks={
            "deployment_exists": {"name": "test-init-container", "namespace": "ckad-q17"},
            "file_exists": "/opt/course/exam3/q17/test-init-container-new.yaml"
        }
    ),
    
    Question(
        num=18,
        title="Service Misconfiguration",
        namespace="ckad-q18",
        difficulty="hard",
        timeout=600,
        task="""There seems to be an issue in Namespace ckad-q18 where the ClusterIP service manager-api-svc
should make the Pods of Deployment manager-api-deployment available inside the cluster.

You can test this with: curl manager-api-svc.ckad-q18:4444 from a temporary nginx:alpine Pod.

Check for the misconfiguration and apply a fix.

Setup creates the Deployment and broken Service for you to debug and fix.""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-q18"}},
        ],
        validation_checks={
            "service_exists": {"name": "manager-api-svc", "namespace": "ckad-q18"},
            "service_has_endpoints": True
        }
    ),
    
    Question(
        num=19,
        title="Change Service Type: ClusterIP to NodePort",
        namespace="ckad-q19",
        difficulty="medium",
        timeout=600,
        task="""In Namespace ckad-q19 you'll find an apache Deployment named jupiter-crew-deploy
and a ClusterIP Service called jupiter-crew-svc which exposes it.

Change this service to a NodePort one to make it available on all nodes on port 30100.

Test the NodePort Service using the internal IP of all available nodes and the port 30100 using curl.
You can reach the internal node IPs directly from your main terminal.

On which nodes is the Service reachable? On which node is the Pod running?""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-q19"}},
        ],
        validation_checks={
            "service_exists": {"name": "jupiter-crew-svc", "namespace": "ckad-q19"},
            "service_type": "NodePort",
            "service_nodeport": 30100
        }
    ),
    
    Question(
        num=20,
        title="Add Liveness Probe",
        namespace="ckad-p1",
        difficulty="medium",
        timeout=600,
        task="""There is an existing Deployment named project-23-api in Namespace ckad-p1.
The original yaml is available at /opt/course/exam3/p1/project-23-api.yaml

Add a liveness-probe to the Deployment:
- Type: TCP socket
- Port: 80
- Initial delay: 10 seconds
- Period: 15 seconds

Save your changes at /opt/course/exam3/p1/project-23-api-new.yaml and apply the changes.""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-p1"}},
        ],
        validation_checks={
            "deployment_exists": {"name": "project-23-api", "namespace": "ckad-p1"},
            "file_exists": "/opt/course/exam3/p1/project-23-api-new.yaml"
        }
    ),
    
    Question(
        num=21,
        title="Deployment with ServiceAccount",
        namespace="ckad-p2",
        difficulty="medium",
        timeout=600,
        task="""Team needs a new Deployment named sunny with 4 replicas of image nginx:1.17.3-alpine
in Namespace ckad-p2.

The Deployment and its Pods should use the existing ServiceAccount sa-sun-deploy.
(Setup creates this ServiceAccount for you)

Expose the Deployment internally using a ClusterIP Service named sun-srv on port 9999.
The nginx containers should run as default on port 80.

The management team would like to execute a command to check that all Pods are running on occasion.
Write that command into file /opt/course/exam3/p2/sunny_status_command.sh.
The command should use kubectl.""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-p2"}},
            {"kind": "ServiceAccount", "metadata": {"name": "sa-sun-deploy", "namespace": "ckad-p2"}},
        ],
        validation_checks={
            "deployment_exists": {"name": "sunny", "namespace": "ckad-p2"},
            "deployment_replicas": 4,
            "service_exists": {"name": "sun-srv", "namespace": "ckad-p2"},
            "file_exists": "/opt/course/exam3/p2/sunny_status_command.sh"
        }
    ),
    
    Question(
        num=22,
        title="Fix Readiness Probe Port",
        namespace="ckad-p3",
        difficulty="hard",
        timeout=600,
        task="""There is a Deployment in Namespace ckad-p3 that should be accessible via Service.
The Service tests show a connection timeout when trying to reach the Service.

Upon investigation you find:
- The Deployment earth-3cc-web exists but shows 0/4 ready replicas
- A Service earth-3cc-web-svc exists but has no endpoints

Check the Deployment configuration for the issue. The readiness-probe might be checking the wrong port.
Fix the readiness-probe port to make the Pods ready.

(Setup creates the Deployment and Service with wrong readiness-probe port for you to fix)

After fixing, write the issue description into /opt/course/exam3/p3/ticket-description.txt""",
        setup_resources=[
            {"kind": "Namespace", "metadata": {"name": "ckad-p3"}},
        ],
        validation_checks={
            "deployment_exists": {"name": "earth-3cc-web", "namespace": "ckad-p3"},
            "deployment_ready": {"replicas": "4/4"},
            "file_exists": "/opt/course/exam3/p3/ticket-description.txt"
        }
    ),
]

def generate_question_yaml(question: Question) -> dict:
    """Convert Question dataclass to YAML-serializable dict"""
    return {
        "name": f"Q{question.num} - {question.title}",
        "namespace": question.namespace,
        "difficulty": question.difficulty,
        "timeout": question.timeout,
        "task": question.task,
        "setup_resources": question.setup_resources,
        "validation_checks": question.validation_checks
    }

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Generate CK-X Exam 3 questions")
    parser.add_argument("--output-dir", default="exams/exam3", help="Output directory for questions")
    args = parser.parse_args()
    
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"Generating {len(EXAM3_QUESTIONS)} questions to {output_dir}/")
    print("=" * 70)
    
    for question in EXAM3_QUESTIONS:
        filename = output_dir / f"q{question.num:02d}.yaml"
        yaml_data = generate_question_yaml(question)
        
        with open(filename, 'w') as f:
            yaml.dump(yaml_data, f, default_flow_style=False, sort_keys=False)
        
        print(f"✓ Q{question.num:02d} - {question.title:<40} → {filename.name}")
    
    print("=" * 70)
    print(f"✓ Generated {len(EXAM3_QUESTIONS)} questions successfully!")
    print(f"\nNext steps:")
    print(f"1. Create namespaces: ./scripts/setup_exam3.sh")
    print(f"2. Test individual questions: ./scripts/test_question.sh <num>")
    print(f"3. Run full exam: ./scripts/run_exam3_test.sh")

if __name__ == "__main__":
    main()
