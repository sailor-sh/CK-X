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
        task="""Create a single Pod of image httpd:2.4.41-alpine in Namespace ckad-q02.
The Pod should be named pod1 and the container should be named pod1-container.

Your manager would like to run a command manually on occasion to output the status of that exact Pod.
Please write a command that does this into /opt/course/exam3/q02/pod1-status-command.sh.
The command should use kubectl.""",
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
        task="""Team Neptune needs a Job template located at /opt/course/exam3/q03/job.yaml.
This Job should run image busybox:1.31.0 and execute: sleep 2 && echo done
It should be in namespace ckad-q03, run a total of 3 times and should execute 2 runs in parallel.

Start the Job and check its history. Each pod created by the Job should have the label id: awesome-job.
The job should be named neb-new-job and the container neb-new-job-container.""",
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
        task="""Team Mercury asked you to perform operations using Helm, all in Namespace ckad-q04:
1. First, setup: helm repo add killershell http://localhost:6000 && helm repo update
2. Delete release internal-issue-report-apiv1
3. Upgrade release internal-issue-report-apiv2 to any newer version of chart killershell/nginx
4. Install a new release internal-issue-report-apache of chart killershell/apache.
   The Deployment should have two replicas, set these via Helm-values during install
5. Find and delete any releases stuck in pending-install state""",
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
        task="""Team Neptune has its own ServiceAccount named neptune-sa-v2 in Namespace ckad-q05.
A coworker needs the token from the Secret that belongs to that ServiceAccount.
Write the base64 decoded token to file /opt/course/exam3/q05/token on localhost.

Setup: Create ServiceAccount neptune-sa-v2 and a Secret associated with it before completing task.""",
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
        task="""Create a single Pod named pod6 in Namespace ckad-q06 of image busybox:1.31.0.
The Pod should have a readiness-probe executing: cat /tmp/ready
It should initially wait 5 and periodically wait 10 seconds.
This will set the container ready only if the file /tmp/ready exists.

The Pod should run the command: touch /tmp/ready && sleep 1d
which will create the necessary file to be ready and then idles.
Create the Pod and confirm it starts and becomes Ready.""",
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
        task="""The board of Team Neptune decided to take over control of one e-commerce webserver from Team Saturn.
The administrator who once setup this webserver is not part of the organisation any longer.
All information you could get was that the e-commerce system is called my-happy-shop.

Search for the correct Pod in Namespace ckad-q07-source and move it to Namespace ckad-q07-target.
It doesn't matter if you shut it down and spin it up again.

(Setup creates the source pod with the my-happy-shop annotation for discovery)""",
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
        task="""There is an existing Deployment named api-new-c32 in Namespace ckad-q08.
A developer did make an update to the Deployment but the updated version never came online.
Check the Deployment history and find a revision that works, then rollback to it.
Could you tell Team Neptune what the error was so it doesn't happen again?

(Setup creates the deployment with a broken revision for you to fix)""",
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
        task="""In Namespace ckad-q09 there is single Pod named holy-api.
It has been working okay for a while now but Team needs it to be more reliable.
Convert the Pod into a Deployment named holy-api with 3 replicas and delete the single Pod once done.

In addition, the new Deployment should set:
  allowPrivilegeEscalation: false
  privileged: false
for the security context on container level.

Please create the Deployment and save its yaml under /opt/course/exam3/q09/holy-api-deployment.yaml""",
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
        task="""Team needs a new cluster internal Service. Create a ClusterIP Service named project-plt-6cc-svc
in Namespace ckad-q10. This Service should expose a single Pod named project-plt-6cc-api
of image nginx:1.17.3-alpine, create that Pod as well.
The Pod should be identified by label: project=plt-6cc-api

The Service should use tcp port redirection of 3333:80.

Finally use curl from a temporary nginx:alpine Pod to get the response from the Service.
Write the response into /opt/course/exam3/q10/service_test.html
Also check if the logs of Pod project-plt-6cc-api show the request and write those into /opt/course/exam3/q10/service_test.log""",
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
        task="""There are files to build a container image located at /opt/course/exam3/q11/image on localhost.
The container will run a Golang application which outputs information to stdout.

Perform the following tasks:
1. Change the Dockerfile: set ENV variable SUN_CIPHER_ID to value: 5b9c1065-e39d-4a43-a04a-e59bcea3e03f
2. Build the image using docker, tag it registry.killer.sh:5000/sun-cipher:v1-docker and push it
3. Build the image using podman, tag it registry.killer.sh:5000/sun-cipher:v1-podman and push it
4. Run a container using podman, which keeps running detached, named sun-cipher using the podman image
5. Write the logs your container produces into /opt/course/exam3/q11/logs

Note: Run docker/podman as root using sudo.""",
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
        task="""Create a new PersistentVolume named earth-project-earthflower-pv.
It should have a capacity of 2Gi, accessMode ReadWriteOnce, hostPath /Volumes/Data
and no storageClassName defined.

Next create a new PersistentVolumeClaim in Namespace ckad-q12 named earth-project-earthflower-pvc.
It should request 2Gi storage, accessMode ReadWriteOnce and should not define a storageClassName.
The PVC should bound to the PV correctly.

Finally create a new Deployment project-earthflower in Namespace ckad-q12
which mounts that volume at /tmp/project-data.
The Pods of that Deployment should be of image httpd:2.4.41-alpine.""",
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
        task="""Team Moonpie (Namespace ckad-q13) needs more storage.
Create a new PersistentVolumeClaim named moon-pvc-126 in that namespace.

This claim should use a new StorageClass moon-retain with:
  - provisioner: moon-retainer
  - reclaimPolicy: Retain

The claim should request storage of 3Gi, accessMode ReadWriteOnce and use the new StorageClass.

The provisioner moon-retainer will be created by another team, so it's expected that the PVC will not bind yet.
Confirm this by writing the event message from the PVC into file /opt/course/exam3/q13/pvc-126-reason""",
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
        task="""You need to make changes on an existing Pod in Namespace ckad-q14 called secret-handler.

Create a new Secret secret1 which contains: user=test and pass=pwd
The Secret's content should be available in Pod secret-handler as environment variables:
  SECRET1_USER and SECRET1_PASS

Create a ConfigMap secret2 and mount it inside the same Pod at /tmp/secret2.

Your changes should be saved under /opt/course/exam3/q14/secret-handler-new.yaml
Both Secrets should only be available in Namespace ckad-q14.

Setup creates the initial Pod for you.""",
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
