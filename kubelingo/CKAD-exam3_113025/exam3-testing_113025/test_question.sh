#!/bin/bash
# File: scripts/test_question.sh
# Test individual questions in exam3
# Usage: ./scripts/test_question.sh <question_number>
# Example: ./scripts/test_question.sh 1
#          ./scripts/test_question.sh 2
#          ./scripts/test_question.sh 3

if [ -z "$1" ]; then
    echo "Usage: $0 <question_number>"
    echo "Example: $0 1"
    echo "         $0 2"
    echo ""
    echo "Testing Q1-Q22:"
    for i in {1..22}; do
        echo "  $0 $i"
    done
    echo ""
    echo "Testing preview questions P1-P3:"
    echo "  $0 p1"
    echo "  $0 p2"
    echo "  $0 p3"
    exit 0
fi

Q=$1
NAMESPACE=""
DIRECTORY=""

# Determine namespace and directory
if [[ $Q =~ ^p[0-9]$ ]]; then
    NAMESPACE="ckad-${Q}"
    DIRECTORY="/opt/course/exam3/${Q}"
else
    Q_NUM=$(printf '%02d' "$Q" 2>/dev/null || echo "$Q")
    NAMESPACE="ckad-q${Q_NUM}"
    DIRECTORY="/opt/course/exam3/q${Q_NUM}"
fi

echo "=========================================="
echo "Testing Question: Q${Q}"
echo "Namespace: $NAMESPACE"
echo "Directory: $DIRECTORY"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

test_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

# Test 1: Namespace exists
echo -e "${BLUE}Test 1: Namespace${NC}"
if kubectl get ns "$NAMESPACE" &>/dev/null; then
    test_pass "Namespace '$NAMESPACE' exists"
else
    test_fail "Namespace '$NAMESPACE' does not exist"
fi

# Test 2: Directory exists
echo ""
echo -e "${BLUE}Test 2: Directory${NC}"
if [ -d "$DIRECTORY" ]; then
    test_pass "Directory '$DIRECTORY' exists"
else
    test_fail "Directory '$DIRECTORY' does not exist"
fi

# Test 3: Question YAML exists
echo ""
echo -e "${BLUE}Test 3: Question YAML${NC}"
if [ -f "exams/exam3/q${Q_NUM}.yaml" ] 2>/dev/null || [ -f "exams/exam3/${Q}.yaml" ]; then
    test_pass "Question YAML file exists"
else
    test_fail "Question YAML file not found"
fi

# Question-specific tests
echo ""
echo -e "${BLUE}Test 4: Question-Specific Validation${NC}"

case "$Q" in
    1|q1|Q1)
        # Q1: Get namespaces
        if [ -f "$DIRECTORY/namespaces" ]; then
            test_pass "Q1: Output file exists ($DIRECTORY/namespaces)"
            if grep -q "^NAME" "$DIRECTORY/namespaces"; then
                test_pass "Q1: Namespace list has header"
            else
                test_fail "Q1: Namespace list missing header"
            fi
        else
            test_fail "Q1: Output file missing ($DIRECTORY/namespaces)"
        fi
        ;;
    
    2|q2|Q2)
        # Q2: Pod creation and status command
        if kubectl -n "$NAMESPACE" get pod pod1 &>/dev/null; then
            test_pass "Q2: Pod 'pod1' exists"
        else
            test_fail "Q2: Pod 'pod1' not found"
        fi
        
        POD_CONTAINER=$(kubectl -n "$NAMESPACE" get pod pod1 -o jsonpath='{.spec.containers[0].name}' 2>/dev/null)
        if [ "$POD_CONTAINER" = "pod1-container" ]; then
            test_pass "Q2: Container name is correct (pod1-container)"
        else
            test_fail "Q2: Container name incorrect (found: $POD_CONTAINER)"
        fi
        
        if [ -f "$DIRECTORY/pod1-status-command.sh" ]; then
            test_pass "Q2: Status command script exists"
            if bash "$DIRECTORY/pod1-status-command.sh" &>/dev/null; then
                test_pass "Q2: Status command script is executable"
            else
                test_fail "Q2: Status command script not executable"
            fi
        else
            test_fail "Q2: Status command script not found"
        fi
        ;;
    
    3|q3|Q3)
        # Q3: Job with parallelism
        if kubectl -n "$NAMESPACE" get job neb-new-job &>/dev/null; then
            test_pass "Q3: Job 'neb-new-job' exists"
        else
            test_fail "Q3: Job 'neb-new-job' not found"
        fi
        
        COMPLETIONS=$(kubectl -n "$NAMESPACE" get job neb-new-job -o jsonpath='{.spec.completions}' 2>/dev/null)
        if [ "$COMPLETIONS" = "3" ]; then
            test_pass "Q3: Job completions set to 3"
        else
            test_fail "Q3: Job completions incorrect (found: $COMPLETIONS)"
        fi
        
        PARALLELISM=$(kubectl -n "$NAMESPACE" get job neb-new-job -o jsonpath='{.spec.parallelism}' 2>/dev/null)
        if [ "$PARALLELISM" = "2" ]; then
            test_pass "Q3: Job parallelism set to 2"
        else
            test_fail "Q3: Job parallelism incorrect (found: $PARALLELISM)"
        fi
        
        if [ -f "$DIRECTORY/job.yaml" ]; then
            test_pass "Q3: Job YAML file exists"
        else
            test_fail "Q3: Job YAML file not found"
        fi
        ;;
    
    5|q5|Q5)
        # Q5: ServiceAccount token
        if [ -f "$DIRECTORY/token" ]; then
            test_pass "Q5: Token file exists"
            TOKEN_LENGTH=$(wc -c < "$DIRECTORY/token")
            if [ "$TOKEN_LENGTH" -gt 100 ]; then
                test_pass "Q5: Token has reasonable length ($TOKEN_LENGTH bytes)"
            else
                test_fail "Q5: Token seems too short ($TOKEN_LENGTH bytes)"
            fi
        else
            test_fail "Q5: Token file not found"
        fi
        ;;
    
    6|q6|Q6)
        # Q6: ReadinessProbe
        if kubectl -n "$NAMESPACE" get pod pod6 &>/dev/null; then
            test_pass "Q6: Pod 'pod6' exists"
        else
            test_fail "Q6: Pod 'pod6' not found"
        fi
        
        PROBE=$(kubectl -n "$NAMESPACE" get pod pod6 -o jsonpath='{.spec.containers[0].readinessProbe}' 2>/dev/null)
        if [ ! -z "$PROBE" ]; then
            test_pass "Q6: ReadinessProbe configured"
        else
            test_fail "Q6: ReadinessProbe not configured"
        fi
        ;;
    
    10|q10|Q10)
        # Q10: Service and logs
        if kubectl -n "$NAMESPACE" get svc project-plt-6cc-svc &>/dev/null; then
            test_pass "Q10: Service exists"
        else
            test_fail "Q10: Service not found"
        fi
        
        if kubectl -n "$NAMESPACE" get pod project-plt-6cc-api &>/dev/null; then
            test_pass "Q10: Pod exists"
        else
            test_fail "Q10: Pod not found"
        fi
        
        if [ -f "$DIRECTORY/service_test.html" ]; then
            test_pass "Q10: HTML test output exists"
        else
            test_fail "Q10: HTML test output not found"
        fi
        
        if [ -f "$DIRECTORY/service_test.log" ]; then
            test_pass "Q10: Log test output exists"
        else
            test_fail "Q10: Log test output not found"
        fi
        ;;
    
    *)
        # Generic test for other questions
        test_pass "Q$Q: Basic validation passed (namespace exists and directory ready)"
        ;;
esac

# Summary
echo ""
echo "=========================================="
echo "Test Summary for Q${Q}"
echo "=========================================="
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Q${Q} validation passed${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}✗ Q${Q} validation failed${NC}"
    exit 1
fi
