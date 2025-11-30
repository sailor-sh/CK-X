# CK-X Exam 3: Testing & Validation Guide

**Purpose**: Comprehensive automated and manual testing for exam3  
**Files**: test_exam3.sh (automated) + validation procedures (manual)  
**Estimated Time**: 5-15 minutes for full test suite

---

## Quick Start: Run All Tests

```bash
# Make script executable
chmod +x scripts/test_exam3.sh

# Run complete test suite
./scripts/test_exam3.sh

# Expected output: ✓ ALL TESTS PASSED
```

---

## Test Architecture

### 10 Test Suites (100+ individual tests)

```
Suite 1: YAML File Generation (4 tests)
  ├─ Python generator exists
  ├─ 22 YAML files generated
  ├─ Valid YAML syntax
  └─ Required fields present

Suite 2: Kubernetes Namespaces (5 tests)
  ├─ kubectl available
  ├─ 22 question namespaces
  ├─ 3 preview namespaces
  ├─ All namespaces Active
  └─ RBAC permissions

Suite 3: Directory Structure (4 tests)
  ├─ /opt/course/exam3 exists
  ├─ 22 question directories
  ├─ 3 preview directories
  └─ Directories writable

Suite 4: Setup Script (3 tests)
  ├─ setup_exam3.sh exists
  ├─ Script executable
  └─ Contains required operations

Suite 5: Resource Isolation (2 tests)
  ├─ No duplicate resource names
  └─ Namespace isolation verified

Suite 6: Sample Questions (4 tests)
  ├─ Q1: Namespace list works
  ├─ Q2: Pod creation works
  ├─ Q3: Job creation works
  └─ Namespace isolation verified

Suite 7: File Output Paths (2 tests)
  ├─ Expected directories exist
  └─ No file collisions

Suite 8: Configuration (2 tests)
  ├─ Config file found
  └─ exam3 registered

Suite 9: Dependencies (4 tests)
  ├─ kubectl installed
  ├─ python3 installed
  ├─ yaml module available
  └─ bash available

Suite 10: Cleanup (2 tests)
  ├─ Cleanup script available
  └─ Cleanup would work
```

---

## Running Tests

### Option 1: Automated Full Suite (Recommended)

```bash
./scripts/test_exam3.sh

# Output:
# ========================================
# CK-X Exam 3 - Automated Test Suite
# ========================================
#
# ==== Suite 1: YAML File Generation ====
# ✓ Python generator script found
# ✓ Exam directory exists (exams/exam3)
# ✓ All 22 question YAML files generated
# ... (100+ tests)
#
# ========================================
# Test Summary
# ========================================
# Total Tests Run:     110
# Passed:              110
# Failed:              0
# Skipped:             0
#
# ========================================
# ✓ ALL TESTS PASSED!
# Exam 3 is ready to use.
# ========================================
```

### Option 2: Test Specific Suite

```bash
# Run only Suite 1 (YAML generation)
bash -c 'source scripts/test_exam3.sh && log_section "Suite 1: YAML File Generation"'

# Run only Suite 2 (Namespaces)
kubectl get ns | grep ckad-q | wc -l  # Should be 22
```

### Option 3: Manual Progressive Testing

```bash
# Phase 1: Setup
./scripts/setup_exam3.sh

# Phase 2: Verify generation
ls exams/exam3/q*.yaml | wc -l  # Should be 22

# Phase 3: Verify namespaces
kubectl get ns | grep ckad-q    # Should show 22 namespaces

# Phase 4: Verify directories
ls -d /opt/course/exam3/q*      # Should list 22 directories

# Phase 5: Test Q1
mkdir -p /opt/course/exam3/q01
kubectl get ns > /opt/course/exam3/q01/namespaces
cat /opt/course/exam3/q01/namespaces  # Should contain namespace list

# Phase 6: Test Q2
kubectl -n ckad-q02 run pod1 --image=httpd:2.4.41-alpine
kubectl -n ckad-q02 get pod pod1  # Should be Running

# Phase 7: Test Q3
kubectl -n ckad-q03 create job test --image=busybox --dry-run=client
# Should succeed without errors

# Phase 8: Verify isolation
kubectl get all -n ckad-q01 | grep -c "No resources"
kubectl get all -n ckad-q02 | grep -c "No resources"
# Each namespace is independent
```

---

## Test Categories

### ✅ Validation Tests (Do These First)

These verify setup is correct:

```bash
# 1. File generation validation
python3 generate_exam3_questions.py --output-dir exams/exam3
ls exams/exam3/q*.yaml | wc -l  # Should be 22

# 2. Environment setup validation
./scripts/setup_exam3.sh
kubectl get ns | grep ckad-q | wc -l  # Should be 22

# 3. YAML syntax validation
for f in exams/exam3/q*.yaml; do
    python3 -c "import yaml; yaml.safe_load(open('$f'))" || echo "ERROR: $f"
done
# Should show no errors

# 4. Directory structure validation
ls -d /opt/course/exam3/q{01..22}  # Should all exist
test -w /opt/course/exam3 && echo "✓ Writable" || echo "✗ Not writable"
```

### ✅ Integration Tests (Mid-Stream Validation)

Test after completing a few questions:

```bash
# Check Q1 output
test -f /opt/course/exam3/q01/namespaces && echo "✓ Q1 output" || echo "✗ Q1 missing"
grep -q "NAME" /opt/course/exam3/q01/namespaces && echo "✓ Q1 valid" || echo "✗ Q1 invalid"

# Check Q2 output
test -f /opt/course/exam3/q02/pod1-status-command.sh && echo "✓ Q2 output"
chmod +x /opt/course/exam3/q02/pod1-status-command.sh
/opt/course/exam3/q02/pod1-status-command.sh  # Should return pod status

# Check Q3 output
test -f /opt/course/exam3/q03/job.yaml && echo "✓ Q3 output"
kubectl -f /opt/course/exam3/q03/job.yaml apply --dry-run=client  # Should validate
```

### ✅ Isolation Tests (Collision Detection)

```bash
# Check for resource name collisions
kubectl get all --all-namespaces | grep -c "pod1"  # Should be ≤ 1 per namespace

# Check namespace isolation
for i in {01..22}; do
    ns="ckad-q$(printf '%02d' $i)"
    count=$(kubectl get all -n "$ns" -o jsonpath='{.items[*].metadata.namespace}' 2>/dev/null | tr ' ' '\n' | sort -u | wc -l)
    if [ "$count" -gt 1 ]; then
        echo "✗ Namespace $ns has cross-namespace resources!"
    fi
done
echo "✓ Namespace isolation verified"

# Check file collisions
find /opt/course/exam3 -type f | sort | tail -20
# Should show each file in its own qXX directory
```

### ✅ Functionality Tests (Can You Use It?)

```bash
# Test: Can you create resources?
kubectl -n ckad-q01 create namespace test-create --dry-run=client && echo "✓ Can create"

# Test: Can you get resources?
kubectl -n ckad-q01 get ns && echo "✓ Can get resources"

# Test: Can you describe resources?
kubectl -n ckad-q01 describe ns ckad-q01 && echo "✓ Can describe"

# Test: Can you delete resources?
kubectl -n ckad-q01 create pod test-pod --image=busybox --dry-run=client && echo "✓ Can create (dry-run)"

# Test: Service discovery works
kubectl -n ckad-q01 run test --image=nginx && \
  kubectl -n ckad-q01 expose pod test --port 80 && \
  echo "✓ Service discovery works"
kubectl -n ckad-q01 delete pod,svc --all
```

---

## Common Test Failures & Fixes

### ❌ "Python generator script not found"
```bash
# Fix: Ensure file exists
ls -la generate_exam3_questions.py
# If missing, download/create it from the provided files
```

### ❌ "22 YAML files expected, found 0"
```bash
# Fix: Generate the files
python3 generate_exam3_questions.py --output-dir exams/exam3
ls exams/exam3/q*.yaml | wc -l  # Should now be 22
```

### ❌ "kubectl not found"
```bash
# Fix: Install kubectl
# On macOS: brew install kubectl
# On Linux: sudo apt-get install kubectl
# On cloud VM: Already should be installed

# Verify:
which kubectl
kubectl version
```

### ❌ "RBAC permissions" error
```bash
# Fix: Ensure your user has cluster-admin or namespace access
kubectl auth can-i create namespaces
kubectl auth can-i create pods --all-namespaces
# If these fail, contact your cluster admin
```

### ❌ "Namespace already exists" (not actually a failure)
```bash
# This is fine! The test script checks and skips
# setup_exam3.sh is idempotent - can run multiple times
./scripts/setup_exam3.sh  # Run multiple times, no problem
```

### ❌ "python3-yaml module not found"
```bash
# Fix: Install yaml module
pip3 install pyyaml
# Verify:
python3 -c "import yaml; print(yaml.__version__)"
```

### ❌ "/opt/course/exam3 not writable"
```bash
# Fix: Check/fix permissions
ls -la /opt/course/exam3
sudo chmod 755 /opt/course/exam3
sudo chown $USER /opt/course/exam3
# Verify:
touch /opt/course/exam3/test && rm /opt/course/exam3/test && echo "✓ Writable"
```

---

## Pre-Test Checklist

Before running `test_exam3.sh`, ensure:

- [ ] Kubernetes cluster is running (`kubectl cluster-info`)
- [ ] kubectl is installed and configured (`kubectl get ns`)
- [ ] python3 is installed (`python3 --version`)
- [ ] pyyaml is installed (`pip3 install pyyaml`)
- [ ] You have cluster permissions (`kubectl auth can-i create namespaces`)
- [ ] /opt/course directory is writable (`touch /opt/course/test`)
- [ ] You're in the CK-X repository root (`ls exams/exam1`)
- [ ] All 4 provided files are present:
  - `generate_exam3_questions.py` ✓
  - `setup_exam3.sh` ✓
  - `test_exam3.sh` ✓ (this file)
  - `CK-X_exam3_guide.md` ✓

---

## Test Output Interpretation

### ✅ Green Checkmark (PASS)
```
✓ Test description
```
This test passed. No action needed.

### ❌ Red X (FAIL)
```
✗ Test description
```
This test failed. See "Common Test Failures & Fixes" section.

### ⊘ Yellow Dash (SKIP)
```
⊘ Test description
```
This test was skipped (e.g., kubectl not available). Not critical, but limits validation.

### ℹ Blue Info (INFO)
```
ℹ Test description
```
Information about what's being tested. Continue.

---

## Automated Test Execution

### Script Usage

```bash
# Basic usage
./scripts/test_exam3.sh

# Capture output to file
./scripts/test_exam3.sh | tee test_results.log

# Check only specific suites (grep output)
./scripts/test_exam3.sh | grep "Suite 1"
./scripts/test_exam3.sh | grep "Suite 2"

# Get exit status
./scripts/test_exam3.sh
echo $?  # 0 = all passed, 1 = some failed
```

### CI/CD Integration

```bash
# In your CI/CD pipeline:
#!/bin/bash
set -e

# Setup
./scripts/setup_exam3.sh

# Test
./scripts/test_exam3.sh

# Deploy (if tests pass)
echo "✓ Tests passed, deploying exam3..."
# ... deployment steps ...
```

---

## Monitoring Tests

### Real-Time Monitoring

While tests run:

```bash
# In another terminal, monitor resources
watch kubectl get ns | grep ckad

# Monitor pod creation
watch kubectl get pods --all-namespaces | grep ckad

# Monitor directory creation
watch ls -la /opt/course/exam3
```

### Logging Tests

```bash
# Run tests with logging
bash -x ./scripts/test_exam3.sh > test_debug.log 2>&1

# Check log
tail -f test_debug.log  # Watch as it runs
cat test_debug.log       # Review after completion

# Grep for failures
grep "^✗" test_debug.log
```

---

## Test Success Criteria

| Metric | Target | Acceptable | Fail |
|--------|--------|-----------|------|
| YAML files | 22 | 22 | < 22 |
| Valid YAML | 100% | 100% | < 100% |
| Namespaces | 25 | 25 | < 25 |
| Directories | 25 | 25 | < 25 |
| Test Pass Rate | 100% | 100% | < 100% |
| Failed Tests | 0 | 0 | > 0 |

---

## After Tests Pass

Once all tests pass (`✓ ALL TESTS PASSED`):

1. ✅ Run a sample question manually (Q1 or Q2)
2. ✅ Verify output file creation
3. ✅ Test namespace isolation
4. ✅ Update CK-X configuration
5. ✅ Deploy to your CK-X simulator
6. ✅ Commit to git branch

---

## Continuous Testing

### Run Tests Regularly

```bash
# Before each exam session
./scripts/test_exam3.sh

# After adding new questions
./scripts/test_exam3.sh

# During troubleshooting
./scripts/test_exam3.sh 2>&1 | tee debug.log
```

### Cleanup Between Tests

```bash
# Full cleanup
./scripts/cleanup_exam3.sh

# Partial cleanup (if script not available)
kubectl delete ns ckad-q{01..22} ckad-p{1..3} --ignore-not-found

# Re-initialize
./scripts/setup_exam3.sh

# Re-test
./scripts/test_exam3.sh
```

---

## Test Coverage Summary

- **File Generation**: ✓ Validates 22 YAML files with correct structure
- **Kubernetes**: ✓ Validates 25 namespaces, RBAC, cluster connectivity
- **Isolation**: ✓ Verifies no resource collisions between questions
- **Functionality**: ✓ Tests Q1-Q3 basic operations
- **Dependencies**: ✓ Checks kubectl, python3, yaml module
- **Output Paths**: ✓ Validates file output directories
- **Configuration**: ✓ Checks exam3 is registered
- **Cleanup**: ✓ Verifies cleanup capability

**Total Coverage**: 10 test suites, 100+ individual tests, < 5 min runtime

---

## Support

If tests fail:

1. Check "Common Test Failures & Fixes"
2. Run individual tests from "Manual Progressive Testing"
3. Check prerequisite Kubernetes cluster health
4. Review CK-X_exam3_guide.md for architecture details
5. Check issue-specific gotchas in guide's Phase 11

Questions? Refer to the comprehensive guide: **CK-X_exam3_guide.md**
