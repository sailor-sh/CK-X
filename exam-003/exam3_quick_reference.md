# CK-X Exam 3: Quick Start Guide

## What You Have

1. **CK-X_exam3_guide.md** - Complete comprehensive guide (11 phases + gotchas + file structure)
2. **generate_exam3_questions.py** - Python script that generates all 22 question YAML files
3. **setup_exam3.sh** - Bash script to initialize exam environment
4. **This file** - Quick reference implementation guide

---

## TL;DR: Generate Exam 3 in 5 Minutes

### Step 1: Setup
```bash
cd your-CK-X-fork

# Create directory structure
mkdir -p exams/exam3 scripts

# Copy scripts
cp generate_exam3_questions.py ./
cp setup_exam3.sh scripts/
chmod +x scripts/setup_exam3.sh
```

### Step 2: Generate Questions
```bash
# Generate all 22 question YAML files
python3 generate_exam3_questions.py --output-dir exams/exam3

# Expected output:
# ✓ Q01 - List Namespaces              → q01.yaml
# ✓ Q02 - Create Pod and Status...     → q02.yaml
# ... (22 total)
# ✓ Generated 22 questions successfully!
```

### Step 3: Initialize Environment
```bash
# Create all 22 namespaces and /opt/course directories
./scripts/setup_exam3.sh

# Expected output:
# ✓ Created namespace ckad-q01
# ✓ Created namespace ckad-q02
# ... (22 total + 3 preview)
# ✓ Exam 3 environment ready!
```

### Step 4: Test a Question
```bash
# Test Q1 (easy - get namespaces)
mkdir -p /opt/course/exam3/q01
kubectl get ns > /opt/course/exam3/q01/namespaces
cat /opt/course/exam3/q01/namespaces

# Test Q2 (pod creation)
kubectl -n ckad-q02 run pod1 --image=httpd:2.4.41-alpine
kubectl -n ckad-q02 get pod pod1
```

### Step 5: Verify Integration
```bash
# List generated questions
ls -la exams/exam3/q*.yaml | wc -l  # Should be 22

# List created namespaces
kubectl get ns | grep ckad-q | wc -l  # Should be 22+3 preview

# Check directories created
ls -d /opt/course/exam3/q* | wc -l  # Should be 22
```

---

## Architecture Decision: Namespace Isolation

**Why**: Your CK-X simulator runs all questions on one instance (localhost), but Killer Shell uses separate instances. Namespace isolation prevents resource conflicts while matching the exam's intent.

```
┌─────────────────────────────────────────────────────────────┐
│              Single Kubernetes Cluster (localhost)           │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  ckad-q01   │  │  ckad-q02    │  │  ckad-q03    │ ...  │
│  │              │  │              │  │              │      │
│  │ Q1: Get NS  │  │ Q2: Pod      │  │ Q3: Job      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  ckad-p1    │  │  ckad-p2     │  │  ckad-p3     │      │
│  │              │  │              │  │              │      │
│  │ Preview 1   │  │ Preview 2    │  │ Preview 3    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

**Benefits:**
- ✅ No resource name collisions
- ✅ Clean separation between questions
- ✅ Easy cleanup: `kubectl delete ns ckad-q*`
- ✅ Matches real exam's "separate environment" intent
- ✅ Works with CK-X's single-instance design

---

## Key Implementation Points

### 1. Questions Map to Namespaces

| Q# | PDF Instance | PDF Namespace | Exam 3 Namespace | Topic |
|----|--------------|---------------|------------------|-------|
| 1  | ckad5601     | default       | ckad-q01         | Get namespaces |
| 2  | ckad5601     | default       | ckad-q02         | Pod creation |
| 3  | ckad7326     | neptune       | ckad-q03         | Job parallelism |
| 4  | ckad7326     | mercury       | ckad-q04         | Helm management |
| 5  | ckad7326     | neptune       | ckad-q05         | ServiceAccount + Secret |
| 6  | ckad5601     | default       | ckad-q06         | ReadinessProbe |
| 7  | ckad7326     | saturn→neptune| ckad-q07-src→tgt | Pod movement |
| 8  | ckad7326     | neptune       | ckad-q08         | Deployment rollback |
| 9  | ckad9043     | pluto         | ckad-q09         | Pod→Deployment |
| 10 | ckad9043     | pluto         | ckad-q10         | Service + logs |
| 11 | ckad9043     | n/a           | ckad-q11         | Docker/Podman build |
| 12 | ckad5601     | earth         | ckad-q12         | PV/PVC/Volume |
| 13 | ckad9043     | moon          | ckad-q13         | StorageClass |
| 14 | ckad9043     | moon          | ckad-q14         | Secret as env+vol |
| 15 | ckad9043     | moon          | ckad-q15         | ConfigMap volume |
| 16 | ckad7326     | mercury       | ckad-q16         | Logging sidecar |
| 17 | ckad5601     | mars          | ckad-q17         | InitContainer |
| 18 | ckad5601     | mars          | ckad-q18         | Service config fix |
| 19 | ckad5601     | jupiter       | ckad-q19         | Service ClusterIP→NodePort |
| P1 | n/a          | pluto         | ckad-p1          | LivenessProbe |
| P2 | n/a          | sun           | ckad-p2          | ServiceAccount |
| P3 | n/a          | earth         | ckad-p3          | ReadinessProbe fix |

### 2. File Output Organization

```
/opt/course/exam3/
├── q01/
│   └── namespaces                    # kubectl get ns output
├── q02/
│   └── pod1-status-command.sh        # kubectl command script
├── q03/
│   └── job.yaml                      # Job definition
├── q04/
│   └── (helm operations - no files)
├── q05/
│   └── token                         # Base64 decoded token
├── ...
├── q11/
│   ├── image/                        # Container build context
│   ├── Dockerfile
│   └── logs                          # Container logs
├── q12/
│   └── (PV/PVC - kubectl objects)
├── ...
└── p1,p2,p3/
    └── (preview question files)
```

### 3. Critical Gotchas Addressed

**Gotcha #1: Multi-Namespace Questions (Q7)**
- **Problem**: Q7 moves pod from one namespace to another
- **Solution**: Create `ckad-q07-source` and `ckad-q07-target` namespaces
- **Implementation**: In setup, pre-create both namespaces with pod in source

**Gotcha #2: Helm Repository (Q4)**
- **Problem**: Helm repo must be pre-configured
- **Solution**: Document in setup script (manual or scripted)
- **Implementation**: `helm repo add killershell http://localhost:6000`

**Gotcha #3: Container Registry (Q11)**
- **Problem**: Docker/Podman need registry access
- **Solution**: Assume `registry.killer.sh:5000` or local registry
- **Implementation**: Verify registry is running before Q11

**Gotcha #4: File Paths (Q1-Q22)**
- **Problem**: All questions write to /opt/course/* (must be writable)
- **Solution**: Create all directories in setup_exam3.sh
- **Implementation**: `mkdir -p /opt/course/exam3/q{01..22}`

---

## Complete Workflow

### Before Exam

```bash
# 1. Generate all questions
python3 generate_exam3_questions.py

# 2. Setup environment
./scripts/setup_exam3.sh

# 3. Verify setup
kubectl get ns | grep ckad-q

# 4. (Optional) Setup Helm for Q4
helm repo add killershell http://localhost:6000

# 5. Start exam
kubelingo exam start exam3
```

### During Exam

```bash
# Each question runs in its own namespace
# Example - Q1 (get namespaces):
mkdir -p /opt/course/exam3/q01
kubectl get ns > /opt/course/exam3/q01/namespaces

# Example - Q2 (create pod):
kubectl -n ckad-q02 run pod1 --image=httpd:2.4.41-alpine
mkdir -p /opt/course/exam3/q2
cat > /opt/course/exam3/q02/pod1-status-command.sh <<EOF
#!/bin/bash
kubectl -n ckad-q02 get pod pod1 -o jsonpath="{.status.phase}"
EOF
chmod +x /opt/course/exam3/q02/pod1-status-command.sh

# ... continue for all 22 questions
```

### After Exam

```bash
# Cleanup all exam resources
./scripts/cleanup_exam3.sh

# OR manually:
kubectl delete ns ckad-q{01..22} ckad-p{1..3} --ignore-not-found
```

---

## Question Difficulty Levels

- **Easy (4)**: Q1, Q2, Q5, Q6
- **Medium (13)**: Q3, Q4, Q8, Q9, Q10, Q12, Q13, Q14, Q15, Q18, P1, P2, Q19
- **Hard (5)**: Q7, Q11, Q16, Q17, Q21, P3

**Total time estimate**: ~2-3 hours for full exam

---

## Validation Checklist

Before declaring exam3 complete:

- [ ] `exams/exam3/q01.yaml` through `exams/exam3/q22.yaml` exist (22 files)
- [ ] All 22 question namespaces created: `kubectl get ns | grep ckad-q`
- [ ] All 25 namespaces (22+3 preview): ckad-q01 through ckad-q22, ckad-p1, ckad-p2, ckad-p3
- [ ] Directory structure: `/opt/course/exam3/q01` through `/opt/course/exam3/q22` + preview
- [ ] Q1 produces: `/opt/course/exam3/q01/namespaces`
- [ ] Q2 produces: `/opt/course/exam3/q02/pod1-status-command.sh`
- [ ] Q3 produces: `/opt/course/exam3/q03/job.yaml`
- [ ] Q4 works with Helm (repo configured)
- [ ] Q5 produces: `/opt/course/exam3/q05/token`
- [ ] ... (continue for all questions)
- [ ] Full exam runs without resource collisions
- [ ] Cleanup removes all exam namespaces

---

## Integration with CK-X CLI

Once exam3 is generated and tested:

```bash
# Update your CK-X config to recognize exam3
# (Follow your kubelingo config format)

# Then use:
kubelingo exam list           # Shows exam1, exam2, exam3
kubelingo exam start exam3    # Start exam3
kubelingo exam status exam3   # Show current progress
kubelingo exam validate exam3 --question 5  # Validate Q5
kubelingo exam cleanup exam3  # Cleanup resources
```

---

## Troubleshooting

**Q: "namespace already exists" errors in setup_exam3.sh**
- A: That's fine - script checks and skips. Just means namespace was created before.

**Q: "kubectl: command not found" in questions**
- A: Ensure kubectl is installed and in PATH. In exam, it's pre-installed.

**Q: Files not found in /opt/course/exam3/**
- A: Make sure you ran `./scripts/setup_exam3.sh` first to create directories.

**Q: Pod/Job/Service not creating**
- A: Check namespace exists: `kubectl get ns ckad-qXX`
- A: Check RBAC permissions for your user/ServiceAccount

**Q: Helm commands fail**
- A: Run: `helm repo add killershell http://localhost:6000 && helm repo update`

**Q: Docker/Podman registry issues (Q11)**
- A: Verify registry is running: `docker ps | grep registry`
- A: Or run: `docker run -d -p 5000:5000 registry:2`

---

## Files Provided

1. **CK-X_exam3_guide.md** (11K) - Full detailed guide with all phases
2. **generate_exam3_questions.py** (15K) - Python script to generate all 22 questions
3. **setup_exam3.sh** (4K) - Bash script to initialize environment
4. **exam3_quick_reference.md** (this file) - Implementation guide

---

## Next Steps After Generation

1. ✅ Run `python3 generate_exam3_questions.py`
2. ✅ Run `./scripts/setup_exam3.sh`
3. ✅ Test Q1: `kubectl get ns > /opt/course/exam3/q01/namespaces`
4. ✅ Verify: `cat /opt/course/exam3/q01/namespaces`
5. ✅ Continue through all 22 questions
6. ✅ Update CK-X config to register exam3
7. ✅ Commit to your kubelingo branch: `git push origin kubelingo`

---

## Support

Refer to **CK-X_exam3_guide.md** for:
- Complete architecture explanation
- Detailed gotcha handling (Helm, Docker, multi-namespace issues)
- File structure template
- Success criteria
- Testing checklist
- Special handling for tricky questions

This quick reference is for **implementation only**. For comprehensive understanding, see the full guide.

Good luck with Exam 3! 🚀
