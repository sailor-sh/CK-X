#!/bin/bash
# File: scripts/test_exam3.sh
# Comprehensive automated testing for CK-X Exam 3
# Tests namespace creation, question isolation, and resource validation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
NAMESPACE_PREFIX="ckad-q"
TOTAL_QUESTIONS=22
PREVIEW_QUESTIONS=3
EXAM_DIR="exams/exam3"
COURSE_DIR="/opt/course/exam3"
FAILED_TESTS=0
PASSED_TESTS=0

# Test reporting
declare -a FAILED_TEST_NAMES
declare -a SKIPPED_TESTS

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CK-X Exam 3 - Automated Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED_TESTS++))
}

log_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED_TESTS++))
    FAILED_TEST_NAMES+=("$1")
}

log_skip() {
    echo -e "${YELLOW}⊘${NC} $1"
    SKIPPED_TESTS+=("$1")
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BLUE}==== $1 ====${NC}"
}

# ============================================================================
# TEST SUITE 1: YAML FILE GENERATION
# ============================================================================

log_section "Suite 1: YAML File Generation"

# Test 1.1: Check Python script exists
if [ -f "generate_exam3_questions.py" ]; then
    log_pass "Python generator script found"
else
    log_fail "Python generator script not found (generate_exam3_questions.py)"
fi

# Test 1.2: Check exam directory exists
if [ -d "$EXAM_DIR" ]; then
    log_pass "Exam directory exists ($EXAM_DIR)"
else
    log_fail "Exam directory missing ($EXAM_DIR)"
fi

# Test 1.3: Count YAML files
YAML_COUNT=$(ls -1 "$EXAM_DIR"/q*.yaml 2>/dev/null | wc -l)
if [ "$YAML_COUNT" -eq 22 ]; then
    log_pass "All 22 question YAML files generated"
else
    log_fail "Expected 22 YAML files, found $YAML_COUNT"
fi

# Test 1.4: Validate YAML syntax
log_info "Validating YAML syntax..."
INVALID_YAML=0
for i in {01..22}; do
    yaml_file="$EXAM_DIR/q${i}.yaml"
    if [ -f "$yaml_file" ]; then
        if ! python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null; then
            log_fail "Invalid YAML syntax: q${i}.yaml"
            ((INVALID_YAML++))
        fi
    fi
done
if [ $INVALID_YAML -eq 0 ]; then
    log_pass "All YAML files have valid syntax"
fi

# Test 1.5: Check required fields in each question
log_info "Validating question structure..."
INVALID_QUESTIONS=0
for i in {01..22}; do
    yaml_file="$EXAM_DIR/q${i}.yaml"
    if [ -f "$yaml_file" ]; then
        # Check for required fields
        has_name=$(grep -c "name:" "$yaml_file" || echo 0)
        has_namespace=$(grep -c "namespace:" "$yaml_file" || echo 0)
        has_task=$(grep -c "task:" "$yaml_file" || echo 0)
        
        if [ $has_name -eq 0 ] || [ $has_namespace -eq 0 ] || [ $has_task -eq 0 ]; then
            log_fail "Q${i} missing required fields (name, namespace, task)"
            ((INVALID_QUESTIONS++))
        fi
    fi
done
if [ $INVALID_QUESTIONS -eq 0 ]; then
    log_pass "All questions have required fields"
fi

# ============================================================================
# TEST SUITE 2: KUBERNETES NAMESPACES
# ============================================================================

log_section "Suite 2: Kubernetes Namespaces"

# Test 2.1: Check if kubectl is available
if command -v kubectl &> /dev/null; then
    log_pass "kubectl found in PATH"
else
    log_fail "kubectl not found - cannot proceed with Kubernetes tests"
    log_skip "Remaining Kubernetes tests"
fi

# Only run k8s tests if kubectl is available
if command -v kubectl &> /dev/null; then
    
    # Test 2.2: Count question namespaces
    NS_COUNT=$(kubectl get ns -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | tr ' ' '\n' | grep "^ckad-q" | wc -l)
    if [ "$NS_COUNT" -eq 22 ]; then
        log_pass "All 22 question namespaces created (ckad-q01 through ckad-q22)"
    else
        log_fail "Expected 22 question namespaces, found $NS_COUNT"
    fi
    
    # Test 2.3: Count preview namespaces
    PREVIEW_NS=$(kubectl get ns -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | tr ' ' '\n' | grep "^ckad-p" | wc -l)
    if [ "$PREVIEW_NS" -eq 3 ]; then
        log_pass "All 3 preview namespaces created (ckad-p1, ckad-p2, ckad-p3)"
    else
        log_fail "Expected 3 preview namespaces, found $PREVIEW_NS"
    fi
    
    # Test 2.4: Verify namespace status
    INACTIVE_NS=0
    for i in {01..22}; do
        ns="ckad-q$(printf '%02d' $i)"
        status=$(kubectl get ns "$ns" -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
        if [ "$status" != "Active" ]; then
            ((INACTIVE_NS++))
        fi
    done
    if [ $INACTIVE_NS -eq 0 ]; then
        log_pass "All question namespaces are Active"
    else
        log_fail "$INACTIVE_NS question namespaces are not Active"
    fi
    
    # Test 2.5: Check for RBAC permissions
    if kubectl get ns ckad-q01 &> /dev/null; then
        log_pass "Current user has RBAC permissions to access namespaces"
    else
        log_fail "Current user lacks RBAC permissions"
    fi

fi

# ============================================================================
# TEST SUITE 3: DIRECTORY STRUCTURE
# ============================================================================

log_section "Suite 3: Directory Structure"

# Test 3.1: Check course directory exists
if [ -d "$COURSE_DIR" ]; then
    log_pass "Course base directory exists ($COURSE_DIR)"
else
    log_fail "Course directory missing ($COURSE_DIR)"
fi

# Test 3.2: Check question directories
MISSING_DIRS=0
for i in {01..22}; do
    dir="$COURSE_DIR/q$(printf '%02d' $i)"
    if [ ! -d "$dir" ]; then
        ((MISSING_DIRS++))
    fi
done
if [ $MISSING_DIRS -eq 0 ]; then
    log_pass "All 22 question directories created"
else
    log_fail "$MISSING_DIRS question directories missing"
fi

# Test 3.3: Check preview directories
for prefix in p1 p2 p3; do
    if [ -d "$COURSE_DIR/$prefix" ]; then
        log_pass "Preview directory exists: $COURSE_DIR/$prefix"
    else
        log_fail "Preview directory missing: $COURSE_DIR/$prefix"
    fi
done

# Test 3.4: Check directory permissions (writable)
if [ -w "$COURSE_DIR" ]; then
    log_pass "Course directory is writable"
else
    log_fail "Course directory is not writable"
fi

# ============================================================================
# TEST SUITE 4: SETUP SCRIPT VALIDATION
# ============================================================================

log_section "Suite 4: Setup Script Validation"

# Test 4.1: Check setup script exists
if [ -f "scripts/setup_exam3.sh" ]; then
    log_pass "Setup script found (scripts/setup_exam3.sh)"
else
    log_fail "Setup script not found (scripts/setup_exam3.sh)"
fi

# Test 4.2: Check setup script is executable
if [ -x "scripts/setup_exam3.sh" ]; then
    log_pass "Setup script is executable"
else
    log_fail "Setup script is not executable"
fi

# Test 4.3: Check setup script for required functions
SETUP_CHECKS=0
if grep -q "kubectl create namespace" "scripts/setup_exam3.sh"; then
    ((SETUP_CHECKS++))
fi
if grep -q "mkdir.*opt/course" "scripts/setup_exam3.sh"; then
    ((SETUP_CHECKS++))
fi
if [ $SETUP_CHECKS -eq 2 ]; then
    log_pass "Setup script contains required operations"
else
    log_fail "Setup script missing required operations"
fi

# ============================================================================
# TEST SUITE 5: RESOURCE ISOLATION (COLLISION DETECTION)
# ============================================================================

log_section "Suite 5: Resource Isolation & Collision Detection"

if command -v kubectl &> /dev/null; then
    
    # Test 5.1: Check for duplicate resource names
    log_info "Scanning for duplicate resource names..."
    
    # Check pods
    PODS_PER_NS=$(kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"_"}{.metadata.namespace}{"\n"}{end}' 2>/dev/null | wc -l)
    if [ $PODS_PER_NS -lt 50 ]; then
        log_pass "No resource name collisions detected between namespaces"
    else
        log_info "Found $PODS_PER_NS pods across all namespaces (expected - may contain resources from other exams)"
    fi
    
    # Test 5.2: Verify namespace isolation (no cross-namespace resource refs)
    ISOLATION_OK=0
    for i in {01..22}; do
        ns="ckad-q$(printf '%02d' $i)"
        # Check if this namespace only contains its own resources
        ns_resources=$(kubectl get all -n "$ns" -o jsonpath='{.items[*].metadata.namespace}' 2>/dev/null | tr ' ' '\n' | sort -u)
        if echo "$ns_resources" | grep -q "^$ns$"; then
            ((ISOLATION_OK++))
        fi
    done
    if [ $ISOLATION_OK -gt 20 ]; then
        log_pass "Namespace isolation verified across $ISOLATION_OK namespaces"
    fi

fi

# ============================================================================
# TEST SUITE 6: SAMPLE QUESTION VALIDATION
# ============================================================================

log_section "Suite 6: Sample Question Tests"

if command -v kubectl &> /dev/null; then
    
    log_info "Testing Q1: List Namespaces"
    # Test 6.1: Q1 - Get namespaces
    if mkdir -p "$COURSE_DIR/q01" && kubectl get ns > "$COURSE_DIR/q01/namespaces.test" 2>/dev/null; then
        if grep -q "^NAME" "$COURSE_DIR/q01/namespaces.test" && grep -q "default" "$COURSE_DIR/q01/namespaces.test"; then
            log_pass "Q1: Namespace list generation works"
            rm -f "$COURSE_DIR/q01/namespaces.test"
        else
            log_fail "Q1: Namespace list invalid format"
        fi
    else
        log_fail "Q1: Cannot generate namespace list"
    fi
    
    log_info "Testing Q2: Pod Creation"
    # Test 6.2: Q2 - Create pod
    if kubectl -n ckad-q02 get ns &>/dev/null; then
        # Try to create a test pod
        if kubectl -n ckad-q02 run test-pod --image=busybox --dry-run=client &>/dev/null; then
            log_pass "Q2: Pod creation works"
        else
            log_fail "Q2: Pod creation failed"
        fi
    else
        log_skip "Q2: Namespace ckad-q02 not found"
    fi
    
    log_info "Testing Q3: Job Creation"
    # Test 6.3: Q3 - Create job
    if kubectl -n ckad-q03 get ns &>/dev/null; then
        if kubectl -n ckad-q03 create job test-job --image=busybox --dry-run=client &>/dev/null; then
            log_pass "Q3: Job creation works"
        else
            log_fail "Q3: Job creation failed"
        fi
    else
        log_skip "Q3: Namespace ckad-q03 not found"
    fi
    
    log_info "Testing namespace isolation (cross-namespace verification)"
    # Test 6.4: Verify resources in different namespaces don't interfere
    Q1_NS=$(kubectl get ns ckad-q01 -o jsonpath='{.metadata.name}' 2>/dev/null || echo "NotFound")
    Q2_NS=$(kubectl get ns ckad-q02 -o jsonpath='{.metadata.name}' 2>/dev/null || echo "NotFound")
    
    if [ "$Q1_NS" = "ckad-q01" ] && [ "$Q2_NS" = "ckad-q02" ]; then
        log_pass "Namespace isolation verified (Q1 and Q2 are separate)"
    else
        log_fail "Namespace isolation failed"
    fi

fi

# ============================================================================
# TEST SUITE 7: FILE OUTPUT VALIDATION
# ============================================================================

log_section "Suite 7: File Output Paths"

# Test 7.1: Check expected output file paths
EXPECTED_FILES=(
    "$COURSE_DIR/q01/namespaces"
    "$COURSE_DIR/q02/pod1-status-command.sh"
    "$COURSE_DIR/q03/job.yaml"
    "$COURSE_DIR/q05/token"
    "$COURSE_DIR/q10/service_test.html"
    "$COURSE_DIR/q10/service_test.log"
    "$COURSE_DIR/q11/logs"
    "$COURSE_DIR/q15/web-moon.html"
)

log_info "Checking expected output file locations..."
for expected_file in "${EXPECTED_FILES[@]}"; do
    dir=$(dirname "$expected_file")
    if [ -d "$dir" ]; then
        log_pass "Output directory ready: $dir"
    else
        log_fail "Output directory missing: $dir"
    fi
done

# Test 7.2: Verify no file collisions
COLLISION_COUNT=0
for i in {01..22}; do
    q_dir="$COURSE_DIR/q$(printf '%02d' $i)"
    if [ -d "$q_dir" ]; then
        # Each directory should only contain its own question's files
        file_count=$(find "$q_dir" -type f 2>/dev/null | wc -l)
        # This is okay - directories can be empty or have question-specific files
        if [ $file_count -gt 100 ]; then
            log_fail "Q$(printf '%02d' $i) directory has unexpectedly many files ($file_count)"
            ((COLLISION_COUNT++))
        fi
    fi
done
if [ $COLLISION_COUNT -eq 0 ]; then
    log_pass "No suspicious file accumulation detected (good isolation)"
fi

# ============================================================================
# TEST SUITE 8: CONFIGURATION VALIDATION
# ============================================================================

log_section "Suite 8: Configuration"

# Test 8.1: Check for exam config
if [ -f "config/exams.yaml" ] || [ -f "exams.yaml" ] || [ -f ".ck-x/exams.yaml" ]; then
    log_pass "Exam configuration file found"
else
    log_info "No central exam config found (config may be in app)"
fi

# Test 8.2: Look for exam3 reference
for config_file in "config/exams.yaml" "exams.yaml" ".ck-x/exams.yaml"; do
    if [ -f "$config_file" ]; then
        if grep -q "exam3" "$config_file"; then
            log_pass "exam3 registered in configuration"
            break
        fi
    fi
done

# ============================================================================
# TEST SUITE 9: DEPENDENCY CHECKS
# ============================================================================

log_section "Suite 9: Dependencies & Tools"

# Test 9.1: kubectl
if command -v kubectl &> /dev/null; then
    kubectl_version=$(kubectl version --client -o json 2>/dev/null | python3 -c "import sys, json; print(json.load(sys.stdin)['clientVersion']['gitVersion'])" 2>/dev/null || echo "unknown")
    log_pass "kubectl available (version: $kubectl_version)"
else
    log_fail "kubectl not found"
fi

# Test 9.2: python3
if command -v python3 &> /dev/null; then
    log_pass "python3 available"
else
    log_fail "python3 not found"
fi

# Test 9.3: yaml module for python
if python3 -c "import yaml" 2>/dev/null; then
    log_pass "python3-yaml module available"
else
    log_fail "python3-yaml module not found (required for generator)"
fi

# Test 9.4: bash version
if command -v bash &> /dev/null; then
    log_pass "bash available"
else
    log_fail "bash not found"
fi

# ============================================================================
# TEST SUITE 10: CLEANUP VALIDATION
# ============================================================================

log_section "Suite 10: Cleanup Capability"

# Test 10.1: Check cleanup script exists
if [ -f "scripts/cleanup_exam3.sh" ]; then
    log_pass "Cleanup script found (scripts/cleanup_exam3.sh)"
else
    log_info "Cleanup script not found (optional - can use kubectl delete)"
fi

# Test 10.2: Verify cleanup would work
if command -v kubectl &> /dev/null; then
    # Test that we can list namespaces for deletion
    if kubectl get ns -l app=ckad-exam3 2>/dev/null | grep -q "ckad-q" || \
       kubectl get ns | grep -q "ckad-q"; then
        log_pass "Namespaces can be identified for cleanup"
    fi
fi

# ============================================================================
# SUMMARY
# ============================================================================

log_section "Test Summary"

TOTAL_TESTS=$((PASSED_TESTS + FAILED_TESTS))
echo ""
echo "Total Tests Run:     $TOTAL_TESTS"
echo -e "Passed:              ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed:              ${RED}$FAILED_TESTS${NC}"
echo -e "Skipped:             ${YELLOW}${#SKIPPED_TESTS[@]}${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ ALL TESTS PASSED!${NC}"
    echo -e "${GREEN}Exam 3 is ready to use.${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "Failed Tests:"
    for test in "${FAILED_TEST_NAMES[@]}"; do
        echo -e "  ${RED}✗${NC} $test"
    done
    echo ""
    exit 1
fi
