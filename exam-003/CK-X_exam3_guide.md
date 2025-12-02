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
```

...

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

