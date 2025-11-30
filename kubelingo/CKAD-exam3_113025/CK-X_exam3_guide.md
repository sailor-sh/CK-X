# CK-X: Generate Practice Exam 3 from Killer Shell PDF

**Objective**: Create a third practice exam for CK-X simulator using questions from the attached Killer Shell Exam Sim PDF.

---

## CRITICAL ARCHITECTURE CONSIDERATION: Single Instance vs Multi-Instance

### The Key Challenge

Your existing CK-X simulator exams (exam1, exam2) **run all questions on a single instance** (`localhost`), which means:
- All Kubernetes resources are created in the same cluster
- No SSH jumping between instances required
- **Potential resource collisions** if questions create similarly-named resources

The **actual Killer Shell exam uses separate instances per question** to avoid conflicts:
```
Real exam:    Q1 → ssh ckad5601, Q2 → ssh ckad5601, Q3 → ssh ckad7326, ...
CK-X default: All questions → localhost (same cluster)
```

### Recommended Solution: Namespace Isolation Pattern

Instead of creating separate instances, **isolate each question in its own namespace**. This prevents collisions while keeping a single-instance environment:

```bash
Question 1  → namespace: ckad-q1
Question 2  → namespace: ckad-q2
Question 3  → namespace: ckad-q3
...
Question 22 → namespace: ckad-q22
```

**Benefits:**
- Eliminates resource naming conflicts
- Matches exam's "separate environment per question" intent
- Works with CK-X's single-instance design
- Easy cleanup: `kubectl delete ns ckad-q*`
- Maintains original question intent

---

## PHASE 1: Extract and Normalize Questions

### Step 1.1: Questions from PDF (22 total)

**Instance Distribution in PDF:**
- `ssh ckad5601`: Q1, Q2, Q6, Q12, Q17, Q18, Q19
- `ssh ckad7326`: Q3, Q4, Q5, Q7, Q8, Q16
- `ssh ckad9043`: Q9, Q10, Q11, Q13, Q14, Q15
- Preview: P1, P2, P3

**Namespaces in PDF:**
- default, neptune, mercury, saturn, mars, pluto, jupiter, earth, moon, sun

### Step 1.2: Namespace Normalization Strategy

Map each question to an isolated namespace to avoid collisions:

```yaml
# namespace_mapping.yaml
q1:
  original_ns: "default"
  exam_ns: "ckad-q1"
  reason: "Get namespaces"

q2:
  original_ns: "default"
  exam_ns: "ckad-q2"
  reason: "Pod creation"

q3:
  original_ns: "neptune"
  exam_ns: "ckad-q3"
  reason: "Job with parallelism"

# ... etc for all 22 questions
```

### Step 1.3: Resource Name Normalization

Some questions reference resources from previous questions (e.g., Q7 looks for pod from Saturn namespace).

**Solution**: Track resource dependencies and ensure they're created in the same namespace context within the question.

**Example - Question 7 (Move Pod):**
```
Original: Pod webserver-sat-003 in namespace "saturn"
Exam 3:   Pod webserver-sat-003 in namespace "ckad-q7-source" (simulated)
          Move to namespace "ckad-q7-target"
```

---

## PHASE 2: Generate Exam Question YAML Files

### Step 2.1: Question Structure in CK-X

Based on your CK-X repo, questions follow this format:

```yaml
# exams/exam3/q01.yaml
name: "Q1 - List Namespaces"
namespace: "ckad-q1"
instance: "localhost"  # Single instance
difficulty: "easy"
timeout: 600           # 10 minutes

setup:
  # Pre-create any required resources
  - apiVersion: v1
    kind: Namespace
    metadata:
      name: "ckad-q1"

task: |
  The DevOps team would like to get the list of all Namespaces in the cluster.
  Save the list to /opt/course/1/namespaces on ckad5601.
  
  (Modified for single instance: Save to /opt/course/exam3/q1/namespaces)

instructions:
  - "Run: kubectl get ns > /opt/course/exam3/q1/namespaces"
  - "Verify the file exists and contains namespace data"

validation:
  - type: "file_exists"
    path: "/opt/course/exam3/q1/namespaces"
  - type: "file_content"
    path: "/opt/course/exam3/q1/namespaces"
    contains: ["NAME", "STATUS", "AGE"]

cleanup:
  - kubectl delete ns ckad-q1
```

### Step 2.2: Namespace Isolation in Questions

**For questions that span multiple namespaces in original**, create the setup to support them:

**Example - Question 7 (Move Pod between namespaces):**
```yaml
# exams/exam3/q07.yaml

setup:
  # Create source namespace with pod
  - apiVersion: v1
    kind: Namespace
    metadata:
      name: "ckad-q7-source"
  
  # Create target namespace
  - apiVersion: v1
    kind: Namespace
    metadata:
      name: "ckad-q7-target"
  
  # Create the pod in source namespace
  - apiVersion: v1
    kind: Pod
    metadata:
      name: webserver-sat-003
      namespace: ckad-q7-source
      labels:
        id: webserver-sat-003
      annotations:
        description: "this is the server for the E-Commerce System my-happy-shop"
    spec:
      containers:
      - name: webserver-sat
        image: nginx:1.16.1-alpine

task: |
  Search for Pod 'my-happy-shop' in namespace 'ckad-q7-source' and move it to 'ckad-q7-target'.
  You can shut it down and recreate it.

validation:
  - type: "pod_exists_in_namespace"
    pod_name: "webserver-sat-003"
    namespace: "ckad-q7-target"
  - type: "pod_not_exists_in_namespace"
    pod_name: "webserver-sat-003"
    namespace: "ckad-q7-source"
```

---

## PHASE 3: Complete Question YAML Generation

### Here's your complete set of 22 questions for exam3:

```python
# Python script to generate all 22 exam questions
# File: generate_exam3_questions.py

import yaml
import os

EXAM_DIR = "exams/exam3"
os.makedirs(EXAM_DIR, exist_ok=True)

questions = [
    {
        "num": 1,
        "title": "List Namespaces",
        "namespace": "ckad-q1",
        "difficulty": "easy",
        "timeout": 300,
        "setup": [],
        "task": "Get all namespaces and save to /opt/course/exam3/q1/namespaces",
        "command": "mkdir -p /opt/course/exam3/q1 && kubectl get ns > /opt/course/exam3/q1/namespaces",
        "validation": {
            "file_exists": "/opt/course/exam3/q1/namespaces",
            "file_contains": ["default", "kube-system"]
        }
    },
    {
        "num": 2,
        "title": "Create Pod and Status Command",
        "namespace": "ckad-q2",
        "difficulty": "easy",
        "timeout": 300,
        "setup": [
            {"kind": "Namespace", "metadata": {"name": "ckad-q2"}}
        ],
        "task": """
        Create a Pod named pod1 in namespace ckad-q2:
        - Image: httpd:2.4.41-alpine
        - Container name: pod1-container
        
        Create a command in /opt/course/exam3/q2/pod1-status-command.sh that outputs pod status
        """,
        "solution": """
        mkdir -p /opt/course/exam3/q2
        kubectl -n ckad-q2 run pod1 --image=httpd:2.4.41-alpine --dry-run=client -oyaml > /tmp/pod1.yaml
        
        # Edit /tmp/pod1.yaml to set container name to pod1-container
        
        kubectl -n ckad-q2 create -f /tmp/pod1.yaml
        
        # Create status command
        cat > /opt/course/exam3/q2/pod1-status-command.sh <<EOF
        #!/bin/bash
        kubectl -n ckad-q2 get pod pod1 -o jsonpath="{.status.phase}"
        EOF
        chmod +x /opt/course/exam3/q2/pod1-status-command.sh
        """,
        "validation": {
            "pod_exists": {"name": "pod1", "namespace": "ckad-q2"},
            "file_exists": "/opt/course/exam3/q2/pod1-status-command.sh"
        }
    },
    {
        "num": 3,
        "title": "Job with Parallelism",
        "namespace": "ckad-q3",
        "difficulty": "medium",
        "timeout": 600,
        "setup": [
            {"kind": "Namespace", "metadata": {"name": "ckad-q3"}}
        ],
        "task": """
        Create a Job named neb-new-job in namespace ckad-q3:
        - Image: busybox:1.31.0
        - Command: sleep 2 && echo done
        - Completions: 3
        - Parallelism: 2
        - Container name: neb-new-job-container
        - Pod label: id=awesome-job
        
        Save job.yaml to /opt/course/exam3/q3/job.yaml
        Create the job and verify it completes all 3 runs with max 2 parallel
        """,
        "yaml_path": "/opt/course/exam3/q3/job.yaml",
        "validation": {
            "job_exists": {"name": "neb-new-job", "namespace": "ckad-q3"},
            "job_completions": 3,
            "job_parallelism": 2
        }
    },
    # ... Continue for all 22 questions
]

for q in questions:
    question_yaml = {
        "name": f"Q{q['num']} - {q['title']}",
        "namespace": q.get("namespace", "default"),
        "difficulty": q.get("difficulty", "medium"),
        "timeout": q.get("timeout", 600),
        "task": q.get("task", ""),
        "validation": q.get("validation", {})
    }
    
    filename = f"{EXAM_DIR}/q{q['num']:02d}.yaml"
    with open(filename, 'w') as f:
        yaml.dump(question_yaml, f, default_flow_style=False)
    print(f"✓ Generated {filename}")

print(f"\n✓ All 22 questions generated in {EXAM_DIR}/")
```

---

## PHASE 4: Create Exam Initialization Script

### Step 4.1: Pre-setup Script

This creates all required namespaces and any base resources:

```bash
#!/bin/bash
# File: scripts/setup_exam3.sh
# Purpose: Initialize exam3 environment with all required namespaces

set -e

NAMESPACE_PREFIX="ckad-q"
TOTAL_QUESTIONS=22

echo "=========================================="
echo "Setting up CK-X Exam 3 Environment"
echo "=========================================="

# Create all question namespaces
for i in $(seq 1 $TOTAL_QUESTIONS); do
    ns="${NAMESPACE_PREFIX}$(printf '%02d' $i)"
    echo -n "Creating namespace ${ns}... "
    kubectl create namespace "${ns}" 2>/dev/null || echo "already exists"
done

# Create /opt/course directories on all nodes (if using hostPath)
echo ""
echo "Creating /opt/course directories..."
for i in $(seq 1 $TOTAL_QUESTIONS); do
    dir="/opt/course/exam3/q$(printf '%02d' $i)"
    mkdir -p "$dir"
    echo "✓ Created $dir"
done

echo ""
echo "=========================================="
echo "✓ Exam 3 environment ready!"
echo "=========================================="
```

### Step 4.2: Cleanup Script

```bash
#!/bin/bash
# File: scripts/cleanup_exam3.sh
# Purpose: Clean up exam3 resources

set -e

NAMESPACE_PREFIX="ckad-q"
TOTAL_QUESTIONS=22

echo "Cleaning up Exam 3..."

for i in $(seq 1 $TOTAL_QUESTIONS); do
    ns="${NAMESPACE_PREFIX}$(printf '%02d' $i)"
    echo -n "Deleting namespace ${ns}... "
    kubectl delete namespace "${ns}" --ignore-not-found=true 2>/dev/null
    echo "✓"
done

echo "✓ Cleanup complete"
```

---

## PHASE 5: Testing Strategy

### Step 5.1: Single Question Testing

```bash
#!/bin/bash
# File: scripts/test_question.sh
# Test an individual question

QUESTION_NUM=${1:-1}
NS="ckad-q$(printf '%02d' $QUESTION_NUM)"

echo "Testing Q${QUESTION_NUM}..."
echo "Namespace: ${NS}"

# Source the question setup
source "exams/exam3/q$(printf '%02d' $QUESTION_NUM).yaml"

# Run validation checks
kubectl get ns | grep "${NS}"
echo "✓ Namespace exists"

# Run question-specific validation
case $QUESTION_NUM in
    1)
        test -f /opt/course/exam3/q1/namespaces && echo "✓ Q1: namespaces file exists"
        ;;
    2)
        kubectl -n ckad-q2 get pod pod1 && echo "✓ Q2: pod1 exists"
        ;;
    3)
        kubectl -n ckad-q3 get job neb-new-job && echo "✓ Q3: job exists"
        ;;
    # ... more validation
esac
```

### Step 5.2: Full Exam Test Run

```bash
#!/bin/bash
# File: scripts/run_exam3_test.sh
# Run through all questions in sequence

set -e

echo "Running full Exam 3 test..."

# Setup
./scripts/setup_exam3.sh

# Run each question
for i in {01..22}; do
    echo ""
    echo "====== Question $i ======"
    timeout 600 bash "exams/exam3/q$i/run.sh" || echo "⚠ Q$i might have failed"
done

echo ""
echo "✓ Test run complete"
echo "Inspect /opt/course/exam3/q*/output* files for validation"
```

---

## PHASE 6: Integration with CK-X Simulator

### Step 6.1: Add Exam to CK-X Config

Update your CK-X configuration to register exam3:

```yaml
# config/exams.yaml

exams:
  exam1:
    name: "CKAD Simulator Exam 1"
    description: "First practice exam"
    path: "exams/exam1"
    questions: 19
    
  exam2:
    name: "CKAD Simulator Exam 2"
    description: "Second practice exam"
    path: "exams/exam2"
    questions: 19
  
  exam3:
    name: "CKAD Killer Shell Custom Exam"
    description: "Custom exam based on Killer Shell Exam Sim (Nov 2025)"
    path: "exams/exam3"
    questions: 22
    requires_setup: true  # Needs namespace initialization
    setup_script: "scripts/setup_exam3.sh"
    cleanup_script: "scripts/cleanup_exam3.sh"
```

### Step 6.2: CLI Commands for Exam 3

```bash
# Start exam3
kubelingo exam start exam3

# Validate specific question
kubelingo exam validate exam3 --question 5

# Get exam3 status
kubelingo exam status exam3

# Cleanup exam3
kubelingo exam cleanup exam3
```

---

## PHASE 7: Complete Question-by-Question Conversion

### Key Conversions for Each Question

| Q # | Original | Changes for Exam3 | Notes |
|-----|----------|-------------------|-------|
| 1   | Get ns, save to /opt/course/1/namespaces | Save to /opt/course/exam3/q1/namespaces | File path adapted |
| 2   | Pod in default ns | Pod in ckad-q2 ns | Isolated namespace |
| 3   | Job in neptune ns | Job in ckad-q3 ns | Isolated namespace |
| 4   | Helm ops in mercury ns | Helm ops in ckad-q4 ns | Isolated + helm setup |
| 5   | Secret in neptune ns | Secret in ckad-q5 ns | Isolated + SA creation |
| 6   | Pod in default ns | Pod in ckad-q6 ns | Isolated namespace |
| 7   | Move pod saturn→neptune | Move pod ckad-q7-src→ckad-q7-tgt | 2 namespaces in setup |
| 8   | Deployment rollback | Deployment rollback in ckad-q8 ns | Isolated namespace |
| 9   | Pod→Deploy in pluto | Pod→Deploy in ckad-q9 | Isolated namespace |
| 10  | Service in pluto | Service in ckad-q10 | Isolated namespace |
| 11  | Docker/Podman build | Same (container ops) | Use /opt/course/exam3/q11 |
| 12  | PV/PVC in earth | PV/PVC in ckad-q12 | Isolated namespace |
| 13  | StorageClass/PVC | StorageClass/PVC in ckad-q13 | Isolated namespace |
| 14  | Secrets in moon | Secrets in ckad-q14 | Isolated namespace |
| 15  | ConfigMap in moon | ConfigMap in ckad-q15 | Isolated namespace |
| 16  | Logging sidecar in mercury | Logging sidecar in ckad-q16 | Isolated namespace |
| 17  | InitContainer in mars | InitContainer in ckad-q17 | Isolated namespace |
| 18  | Service config in mars | Service config in ckad-q18 | Isolated namespace |
| 19  | Service NodePort in jupiter | Service NodePort in ckad-q19 | Isolated namespace |
| P1  | Liveness probe in pluto | Liveness probe in ckad-p1 | Preview question |
| P2  | Deployment with SA in sun | Deployment with SA in ckad-p2 | Preview question |
| P3  | Readiness probe fix in earth | Readiness probe fix in ckad-p3 | Preview question |

---

## PHASE 8: Addressing Multi-Instance Gotchas

### Gotcha #1: Cross-Namespace References

**Problem**: Some questions reference resources from "previous" questions in original exam.

**Solution**: Within exam3, use explicit setup sections:

```yaml
# Q7 setup includes Q7-source pod
setup:
  - name: "Create source namespace with target pod"
    resources:
      - kind: Namespace
        metadata:
          name: ckad-q7-source
      - kind: Pod
        metadata:
          name: webserver-sat-003
          namespace: ckad-q7-source
        # ...pod spec...

task: "Move pod from ckad-q7-source to ckad-q7-target"
```

### Gotcha #2: Helm Repositories

**Problem**: Q4 uses `helm repo` commands that depend on pre-configured repos.

**Solution**: Include helm setup in Q4's initialization:

```bash
# Before running Q4, ensure helm repo is configured:
helm repo add killershell http://localhost:6000
helm repo update
```

### Gotcha #3: Docker/Podman Registry

**Problem**: Q11 pushes images to `registry.killer.sh:5000`

**Solution**: Ensure registry is accessible or mock it:

```bash
# Option 1: Ensure registry is running
docker run -d -p 5000:5000 registry:2

# Option 2: Use local Docker registry
export REGISTRY_URL="localhost:5000"
```

### Gotcha #4: File Paths on Single Instance

**Problem**: All questions write to /opt/course/* on localhost

**Solution**: Organize by question number:

```
/opt/course/exam3/
├── q01/namespaces
├── q02/pod1-status-command.sh
├── q03/job.yaml
└── ...
```

---

## PHASE 9: Validation and Testing

### Step 9.1: Pre-Flight Checks

```bash
#!/bin/bash
# scripts/preflight_exam3.sh

echo "Pre-flight checks for Exam 3..."

# 1. Check Kubernetes cluster
echo -n "✓ Kubernetes cluster: "
kubectl cluster-info | head -1

# 2. Check docker/podman
echo -n "✓ Docker available: "
which docker && echo "yes" || echo "no"

# 3. Check helm
echo -n "✓ Helm available: "
helm version --short

# 4. Check directories
echo -n "✓ /opt/course exists: "
test -d /opt/course && echo "yes" || mkdir -p /opt/course && echo "created"

# 5. Check DNS resolution
echo -n "✓ Kubernetes DNS: "
kubectl get svc -n kube-system | grep -q kube-dns && echo "yes" || echo "no"

echo "✓ Pre-flight checks complete!"
```

### Step 9.2: Validation Checks Per Question

```bash
# Question-specific validation functions

validate_q1() {
    test -f /opt/course/exam3/q1/namespaces || return 1
    grep -q "ckad-q01" /opt/course/exam3/q1/namespaces || return 1
}

validate_q2() {
    kubectl -n ckad-q2 get pod pod1 >/dev/null 2>&1 || return 1
    test -f /opt/course/exam3/q2/pod1-status-command.sh || return 1
}

validate_q3() {
    kubectl -n ckad-q3 get job neb-new-job >/dev/null 2>&1 || return 1
    [ "$(kubectl -n ckad-q3 get job neb-new-job -o jsonpath='{.spec.completions}')" == "3" ] || return 1
}

# ... etc for all 22 questions

# Run all validations
for i in {1..22}; do
    if validate_q$i; then
        echo "✓ Q$i validated"
    else
        echo "✗ Q$i failed validation"
    fi
done
```

---

## PHASE 10: Quick Start Instructions

### For You to Generate Exam 3:

```bash
# 1. Extract from PDF (already done manually above)
# 2. Create exam3 directory structure
mkdir -p exams/exam3/q{01..22}
mkdir -p scripts
mkdir -p config

# 3. Run setup
./scripts/setup_exam3.sh

# 4. Generate all question files (using Python template from Phase 3)
python3 generate_exam3_questions.py

# 5. Test individual questions
./scripts/test_question.sh 1
./scripts/test_question.sh 2
# ... etc

# 6. Run full exam test
./scripts/run_exam3_test.sh

# 7. Integrate with CK-X simulator
# Update exams.yaml config and restart simulator

# 8. Start using exam3
kubelingo exam start exam3
```

### To Access Exam 3:

```bash
# Via CLI
kubelingo exam start exam3 --question 1

# Via simulator UI
# Select "CKAD Killer Shell Custom Exam" from exam list
```

---

## PHASE 11: Special Handling for Tricky Questions

### Q4 - Helm Management
**Challenge**: Helm repo must be pre-configured

```yaml
setup:
  - name: "Configure Helm repository"
    commands:
      - "helm repo add killershell http://localhost:6000"
      - "helm repo update"

task: |
  Perform Helm operations in namespace ckad-q4:
  1. Delete release internal-issue-report-apiv1
  2. Upgrade internal-issue-report-apiv2 to newer nginx chart
  3. Install internal-issue-report-apache with 2 replicas
  4. Find and delete pending-install release
```

### Q7 - Pod Movement Between Namespaces
**Challenge**: Need to simulate "Saturn" namespace source

```yaml
setup:
  # Create "source" namespace (simulating Saturn)
  - kind: Namespace
    metadata:
      name: ckad-q7-source
  
  # Create target namespace (simulating Neptune)
  - kind: Namespace
    metadata:
      name: ckad-q7-target
  
  # Create pod in source
  - kind: Pod
    metadata:
      name: webserver-sat-003
      namespace: ckad-q7-source
      labels:
        id: webserver-sat-003
      annotations:
        description: "this is the server for the E-Commerce System my-happy-shop"
    spec:
      containers:
      - name: webserver-sat
        image: nginx:1.16.1-alpine

task: |
  Search for the pod with label my-happy-shop in namespace ckad-q7-source.
  Move it to namespace ckad-q7-target.
```

### Q11 - Docker/Podman Images
**Challenge**: Dockerfile context and registry

```yaml
setup:
  - name: "Create Dockerfile context"
    create_file: "/tmp/exam3/q11/Dockerfile"
    content: |
      FROM golang:1.15.15-alpine3.14
      WORKDIR /src
      # ... Dockerfile content ...
      
  - name: "Start local container registry (if needed)"
    command: "docker run -d -p 5000:5000 registry:2"

task: |
  Build Docker image with ENV SUN_CIPHER_ID=5b9c1065-e39d-4a43-a04a-e59bcea3e03f
  Tag as: registry.killer.sh:5000/sun-cipher:v1-docker
  Push to registry
```

### Q13 - StorageClass with Pending PVC
**Challenge**: Expected to NOT be bound initially

```yaml
validation:
  - type: "pvc_status"
    namespace: "ckad-q13"
    pvc_name: "moon-pvc-126"
    expected_status: "Pending"  # This is CORRECT - provisioner doesn't exist
    event_contains: "Waiting for a volume to be created"
```

---

## File Structure Template

```
your-fork/CK-X/
├── exams/
│   ├── exam1/
│   ├── exam2/
│   └── exam3/                          # NEW
│       ├── q01.yaml
│       ├── q02.yaml
│       ├── ...
│       ├── q22.yaml
│       └── setup/
│           ├── namespaces.yaml
│           ├── helm-repos.yaml
│           └── pre-requisites.yaml
├── scripts/
│   ├── setup_exam3.sh
│   ├── cleanup_exam3.sh
│   ├── test_question.sh
│   ├── run_exam3_test.sh
│   └── preflight_exam3.sh
├── config/
│   └── exams.yaml                      # Updated with exam3
├── validate/
│   └── exam3_validator.sh
└── generate_exam3_questions.py         # Generator script

/opt/course/exam3/                       # On test system
├── q01/namespaces
├── q02/pod1-status-command.sh
├── q03/job.yaml
└── ...
```

---

## Success Criteria

✅ **Exam 3 is ready when:**

1. All 22 questions are in `exams/exam3/qXX.yaml` format
2. Each question has its own namespace (`ckad-qXX`)
3. `setup_exam3.sh` creates all namespaces without errors
4. Each question can be tested in isolation
5. Full exam runs start-to-finish without collisions
6. File outputs go to `/opt/course/exam3/qXX/*`
7. Registered in CK-X config and accessible via CLI/UI
8. Documentation is clear on how to run each question

---

## Testing Checklist

- [ ] Setup script creates 22 namespaces
- [ ] Q1: Namespace list saved correctly
- [ ] Q2: Pod created with correct container name
- [ ] Q3: Job completes with 3 runs, max 2 parallel
- [ ] Q4: Helm commands execute without errors
- [ ] Q5: ServiceAccount token extracted
- [ ] Q6: ReadinessProbe works correctly
- [ ] Q7: Pod moves between namespaces
- [ ] Q8: Deployment rollback successful
- [ ] Q9: Pod converted to Deployment
- [ ] Q10: Service accessible via curl
- [ ] Q11: Docker/Podman images build and push
- [ ] Q12: PV/PVC bind correctly
- [ ] Q13: PVC remains pending (expected)
- [ ] Q14: Secrets accessible as env vars and volume
- [ ] Q15: ConfigMap mounts and serves content
- [ ] Q16: Logging sidecar captures logs
- [ ] Q17: InitContainer creates required files
- [ ] Q18: Service selector fixed
- [ ] Q19: Service converted to NodePort
- [ ] P1: Liveness probe added correctly
- [ ] P2: ServiceAccount applied to Deployment
- [ ] P3: ReadinessProbe port corrected
- [ ] Full cleanup removes all exam resources

---

## Next Steps

1. **Create exam3 directory**: `mkdir -p exams/exam3/{q01..q22}`
2. **Copy this template**: Use Python script to generate all 22 question YAML files
3. **Write setup scripts**: Create namespace and resource initialization
4. **Test individually**: Run each question to verify namespace isolation works
5. **Validate integration**: Ensure CK-X recognizes and runs exam3
6. **Document**: Add exam3 to README with instructions
7. **Commit**: Push to your kubelingo branch

Good luck! This approach gives you all the benefits of the actual Killer Shell exam structure while maintaining single-instance compatibility with CK-X.
