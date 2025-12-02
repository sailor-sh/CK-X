# CK-X Exam 3: Implementation Checklist

**Generated**: 2025-11-30  
**Status**: ✅ Ready to implement  
**Estimated Time**: 5 min setup + 120-180 min completion

---

## What You're Getting

Four comprehensive files for generating a third practice exam from the Killer Shell PDF:

- ✅ **CK-X_exam3_guide.md** - Complete 11-phase implementation guide
- ✅ **generate_exam3_questions.py** - Python script (generates all 22 questions)
- ✅ **setup_exam3.sh** - Bash setup script (initializes environment)
- ✅ **exam3_quick_reference.md** - Quick implementation guide

---

## Implementation Steps (Do These)

### ✅ Phase 1: Setup (5 minutes)

- [ ] Clone or navigate to your CK-X repository
- [ ] Create directory: `mkdir -p exams/exam3 scripts`
- [ ] Place `generate_exam3_questions.py` in repo root
- [ ] Place `setup_exam3.sh` in `scripts/` directory
- [ ] Make script executable: `chmod +x scripts/setup_exam3.sh`

### ✅ Phase 2: Generate Questions (1 minute)

```bash
python3 generate_exam3_questions.py --output-dir exams/exam3
```

**Expected Result**: 22 YAML files created in `exams/exam3/q01.yaml` through `exams/exam3/q22.yaml`

- [ ] Check: `ls exams/exam3/q*.yaml | wc -l` returns `22`
- [ ] Each file contains question definition, namespace, difficulty, timeout, task

### ✅ Phase 3: Setup Kubernetes Environment (2 minutes)

```bash
./scripts/setup_exam3.sh
```

**Expected Result**: 25 namespaces created (22 questions + 3 preview) + /opt/course directories

- [ ] Check: `kubectl get ns | grep ckad-q` lists 22 question namespaces
- [ ] Check: `kubectl get ns | grep ckad-p` lists 3 preview namespaces
- [ ] Check: `ls -d /opt/course/exam3/q*` lists 22 question directories
- [ ] Check: `/opt/course/exam3/q15/web-moon.html` file exists (sample content)

### ✅ Phase 4: Test Individual Questions (30 minutes)

Start with easy questions to validate setup:

**Q1: List Namespaces (Easy)**
```bash
mkdir -p /opt/course/exam3/q01
kubectl get ns > /opt/course/exam3/q01/namespaces
cat /opt/course/exam3/q01/namespaces
# Expected: File contains namespace list with ckad-q* entries
```
- [ ] File created: `/opt/course/exam3/q01/namespaces`
- [ ] Content contains: `NAME`, `default`, `ckad-q01`, etc.

**Q2: Create Pod (Easy)**
```bash
# Create directories
mkdir -p /opt/course/exam3/q02

# Create pod with correct container name
kubectl -n ckad-q02 run pod1 --image=httpd:2.4.41-alpine --dry-run=client -oyaml > /tmp/q2.yaml
# Edit to change container name to pod1-container
kubectl -n ckad-q02 create -f /tmp/q2.yaml

# Create status command script
cat > /opt/course/exam3/q02/pod1-status-command.sh <<'EOF'
#!/bin/bash
kubectl -n ckad-q02 get pod pod1 -o jsonpath="{.status.phase}"
EOF
chmod +x /opt/course/exam3/q02/pod1-status-command.sh

# Test
./opt/course/exam3/q02/pod1-status-command.sh
# Expected output: "Running" or "Pending" depending on pod state
```
- [ ] Pod created: `kubectl -n ckad-q2 get pod pod1`
- [ ] Container name correct: pod1-container
- [ ] Script created: `/opt/course/exam3/q02/pod1-status-command.sh`
- [ ] Script returns pod status when executed

**Q3: Job with Parallelism (Medium)**
```bash
mkdir -p /opt/course/exam3/q03

# Create job definition
cat > /opt/course/exam3/q03/job.yaml <<'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: neb-new-job
  namespace: ckad-q03
spec:
  completions: 3
  parallelism: 2
  template:
    metadata:
      labels:
        id: awesome-job
    spec:
      containers:
      - image: busybox:1.31.0
        name: neb-new-job-container
        command:
        - sh
        - -c
        - sleep 2 && echo done
      restartPolicy: Never
EOF

# Create the job
kubectl -f /opt/course/exam3/q03/job.yaml create

# Monitor
kubectl -n ckad-q03 get job neb-new-job -w
# Expected: 3 completions, max 2 pods running in parallel
```
- [ ] Job YAML created: `/opt/course/exam3/q03/job.yaml`
- [ ] Job created successfully: `kubectl -n ckad-q03 get job neb-new-job`
- [ ] Job completes 3 times: `kubectl -n ckad-q03 get job neb-new-job` shows 3/3
- [ ] Max 2 parallel: Never see more than 2 running pods

Continue with Q4-Q22 (refer to exam3_quick_reference.md for each question)

### ✅ Phase 5: Verify Full Integration (5 minutes)

```bash
# Count questions
ls exams/exam3/q*.yaml | wc -l
# Expected: 22

# Count namespaces
kubectl get ns | grep ckad-q | wc -l
# Expected: 22

# Count directories
ls -d /opt/course/exam3/q* | wc -l
# Expected: 22

# Check for file collisions (all should be in their qXX directories)
find /opt/course/exam3 -type f | head -10
```

- [ ] Exactly 22 question YAML files in exams/exam3/
- [ ] Exactly 22 question namespaces created (ckad-q01 through ckad-q22)
- [ ] Exactly 3 preview namespaces created (ckad-p1, ckad-p2, ckad-p3)
- [ ] Exactly 22 question directories in /opt/course/exam3/
- [ ] All files isolated to their question directory (no collisions)

### ✅ Phase 6: Update CK-X Configuration

Update your CK-X simulator's configuration to register exam3:

```yaml
# config/exams.yaml (or equivalent)
exams:
  exam1:
    name: "CKAD Simulator Exam 1"
    # ... existing config ...
  
  exam2:
    name: "CKAD Simulator Exam 2"
    # ... existing config ...
  
  exam3:  # NEW
    name: "CKAD Killer Shell Custom Exam"
    description: "All 22 questions from Killer Shell Exam Sim (Nov 2025)"
    path: "exams/exam3"
    questions: 22
    requires_setup: true
    setup_script: "scripts/setup_exam3.sh"
    cleanup_script: "scripts/cleanup_exam3.sh"
```

- [ ] Updated exams config file
- [ ] exam3 is recognized by CK-X (test with `kubelingo exam list`)
- [ ] Can start exam3 (test with `kubelingo exam start exam3`)

### ✅ Phase 7: Test Full Exam Flow (10 minutes)

```bash
# If using kubelingo CLI
kubelingo exam start exam3

# Or manually test a few questions end-to-end
# Test Q1-Q3 (easy to medium)
# Verify each produces expected output files

# Cleanup
./scripts/cleanup_exam3.sh
# Expected: All 25 namespaces deleted
```

- [ ] Can start exam3
- [ ] Each question has correct namespace isolation
- [ ] Output files are created correctly
- [ ] Cleanup script removes all exam resources
- [ ] No resource collisions between questions

### ✅ Phase 8: Commit and Deploy

```bash
git add exams/exam3/
git add generate_exam3_questions.py
git add scripts/setup_exam3.sh
git add config/exams.yaml  # Updated
git commit -m "feat: Add exam3 - 22 questions from Killer Shell PDF"
git push origin kubelingo
```

- [ ] All exam3 files committed
- [ ] Python generator committed
- [ ] Setup script committed
- [ ] Config updates committed
- [ ] Pushed to kubelingo branch

---

## Detailed Question Breakdown

### Easy Questions (4)
- **Q1**: List namespaces → Save to file (5 min)
- **Q2**: Create pod + status command (10 min)
- **Q5**: Extract ServiceAccount token (10 min)
- **Q6**: Add ReadinessProbe (10 min)

### Medium Questions (13)
- **Q3**: Job with parallelism (10 min)
- **Q4**: Helm management operations (15 min)
- **Q8**: Deployment rollback (10 min)
- **Q9**: Convert Pod to Deployment (10 min)
- **Q10**: Service + test with curl (15 min)
- **Q12**: PV/PVC/Volume mounting (15 min)
- **Q13**: StorageClass + pending PVC (10 min)
- **Q14**: Secrets as env + volume (15 min)
- **Q15**: ConfigMap volume mount (10 min)
- **Q18**: Fix Service misconfiguration (15 min)
- **Q19**: Service ClusterIP to NodePort (10 min)
- **P1**: Add LivenessProbe (10 min)
- **P2**: Deployment with ServiceAccount (10 min)

### Hard Questions (5)
- **Q7**: Move pod between namespaces (15 min) - Multi-namespace setup
- **Q11**: Docker/Podman build + push (20 min) - Container operations
- **Q16**: Logging sidecar container (15 min) - Multi-container pod
- **Q17**: InitContainer pattern (15 min) - Pod initialization
- **P3**: Fix ReadinessProbe port issue (15 min) - Debugging required

---

## Architecture Summary

### Namespace Isolation Pattern

```
Your Kubernetes Cluster (Single Instance: localhost)
├── ckad-q01  (Q1 - Get namespaces)
├── ckad-q02  (Q2 - Pod creation)
├── ckad-q03  (Q3 - Job)
├── ...
├── ckad-q22  (Q22 - Readiness fix)
├── ckad-p1   (Preview 1 - Liveness)
├── ckad-p2   (Preview 2 - ServiceAccount)
└── ckad-p3   (Preview 3 - Readiness fix)
```

**Benefits:**
- ✅ No resource name collisions
- ✅ Matches real exam's "separate environment per question"
- ✅ Easy isolation and cleanup
- ✅ Supports single-instance CK-X design

### File Organization

```
Your Fork/
├── exams/exam3/
│   ├── q01.yaml through q22.yaml  (22 question definitions)
│   └── (no setup files - CLI handles it)
├── scripts/
│   ├── setup_exam3.sh             (Initialize environment)
│   └── cleanup_exam3.sh           (Optional - manual cleanup)
├── generate_exam3_questions.py    (Python generator)
├── config/exams.yaml              (Updated with exam3)
└── ...

/opt/course/exam3/
├── q01/namespaces                 (Q1 output)
├── q02/pod1-status-command.sh     (Q2 output)
├── q03/job.yaml                   (Q3 output)
├── ... (one per question)
└── (all isolated, no collisions)
```

---

## Common Issues & Solutions

### Issue: "Namespace already exists"
**Solution**: Script checks and skips. This is fine.

### Issue: kubectl not found
**Solution**: Ensure kubectl is in PATH. In exam environment, it's pre-installed.

### Issue: Cannot create pod
**Solution**: Check namespace exists: `kubectl get ns ckad-q02`

### Issue: Files not created
**Solution**: Ensure directories created: `mkdir -p /opt/course/exam3/q01`

### Issue: Helm commands fail (Q4)
**Solution**: Run: `helm repo add killershell http://localhost:6000`

### Issue: Docker/Podman registry fail (Q11)
**Solution**: Start registry: `docker run -d -p 5000:5000 registry:2`

### Issue: Multi-namespace question (Q7) problems
**Solution**: Setup script creates both source and target namespaces

---

## Success Criteria

You'll know it's working when:

✅ All 22 YAML files exist in `exams/exam3/`  
✅ All 25 namespaces (22+3) created successfully  
✅ Q1 produces `/opt/course/exam3/q01/namespaces`  
✅ Q2 produces `/opt/course/exam3/q02/pod1-status-command.sh`  
✅ Q3 completes job with 3 runs, 2 parallel max  
✅ Q4 Helm operations work  
✅ All questions run without collisions  
✅ Cleanup removes all resources  
✅ Can register exam3 in CK-X  
✅ Can start and complete exam3  

---

## Timeline

| Phase | Time | Status |
|-------|------|--------|
| Setup | 5 min | ⏳ Do this first |
| Generate | 1 min | ⏳ Run python script |
| Environment | 2 min | ⏳ Run bash script |
| Q1-Q3 Testing | 20 min | ⏳ Validate setup works |
| Q4-Q22 Completion | 90-150 min | 🎯 Full exam run |
| Integration | 10 min | ⏳ Update config |
| **Total** | **2-3 hours** | 🚀 **Ready!** |

---

## Files Reference

### 1. CK-X_exam3_guide.md
**Purpose**: Complete implementation guide  
**Contains**: 11 phases, gotcha handling, file structure, validation  
**Read when**: You need detailed explanations

### 2. generate_exam3_questions.py
**Purpose**: Generate all 22 question YAML files  
**Usage**: `python3 generate_exam3_questions.py --output-dir exams/exam3`  
**Creates**: 22 YAML files in exams/exam3/q01.yaml through q22.yaml

### 3. setup_exam3.sh
**Purpose**: Initialize Kubernetes environment  
**Usage**: `./scripts/setup_exam3.sh`  
**Creates**: 25 namespaces + /opt/course/exam3/q* directories

### 4. exam3_quick_reference.md
**Purpose**: Implementation quick reference  
**Read when**: You need a quick reminder during implementation

---

## Next Actions

**Immediate** (Do Now):
1. ✅ Download all 4 files
2. ✅ Read this checklist
3. ✅ Read exam3_quick_reference.md (5 min overview)

**Short Term** (Next 30 minutes):
1. ✅ Run: `python3 generate_exam3_questions.py`
2. ✅ Run: `./scripts/setup_exam3.sh`
3. ✅ Test Q1 and Q2
4. ✅ Verify file creation

**Medium Term** (Next 2-3 hours):
1. ✅ Complete Q3-Q22 questions
2. ✅ Verify all validations pass
3. ✅ Test full exam flow

**Final** (Before submitting):
1. ✅ Update CK-X configuration
2. ✅ Test exam3 in CK-X UI/CLI
3. ✅ Commit and push to kubelingo branch
4. ✅ Create pull request (if needed)

---

**Status**: ✅ **READY TO IMPLEMENT**

Start with Step 1 (Setup) and work through the checklist. Reference the detailed guide for any issues.

Good luck! 🚀
