#!/bin/bash
# File: scripts/setup_exam3.sh
# Initialize CK-X Exam 3 environment

set -e

NAMESPACE_PREFIX="ckad-q"
TOTAL_QUESTIONS=22
PREVIEW_QUESTIONS=3

echo "=========================================="
echo "CK-X Exam 3 - Environment Setup"
echo "=========================================="
echo ""

# Create question namespaces
echo "Creating Kubernetes namespaces..."
for i in $(seq 1 $TOTAL_QUESTIONS); do
    ns="${NAMESPACE_PREFIX}$(printf '%02d' $i)"
    if kubectl get ns "$ns" > /dev/null 2>&1; then
        echo "  ⓘ Namespace $ns already exists"
    else
        kubectl create namespace "$ns"
        echo "  ✓ Created namespace $ns"
    fi
done

# Create preview namespaces (p1, p2, p3)
for prefix in p1 p2 p3; do
    ns="ckad-${prefix}"
    if kubectl get ns "$ns" > /dev/null 2>&1; then
        echo "  ⓘ Namespace $ns already exists"
    else
        kubectl create namespace "$ns"
        echo "  ✓ Created namespace $ns"
    fi
done

echo ""
echo "Creating /opt/course directories..."

# Create /opt/course directories
mkdir -p /opt/course/exam3

for i in $(seq 1 $TOTAL_QUESTIONS); do
    dir="/opt/course/exam3/q$(printf '%02d' $i)"
    mkdir -p "$dir"
    echo "  ✓ Created $dir"
done

for prefix in p1 p2 p3; do
    dir="/opt/course/exam3/${prefix}"
    mkdir -p "$dir"
    echo "  ✓ Created $dir"
done

echo ""
echo "Setting up prerequisites..."

# Q4: Configure Helm repository
echo "  ⓘ Q4 requires Helm repo setup (manual: helm repo add killershell http://localhost:6000)"

# Q11: Create container context
mkdir -p /opt/course/exam3/q11/image
echo "  ✓ Created /opt/course/exam3/q11/image directory"

# Q15: Create web-moon.html sample
cat > /opt/course/exam3/q15/web-moon.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Web Moon Webpage</title>
</head>
<body>
<h1>Team Moonpie Web Server</h1>
<p>This is some great content.</p>
</body>
</html>
EOF
echo "  ✓ Created /opt/course/exam3/q15/web-moon.html"

# Q16: Create cleaner.yaml template
mkdir -p /opt/course/exam3/q16
echo "  ✓ Created /opt/course/exam3/q16 directory"

# Q17: Create test-init-container.yaml template
mkdir -p /opt/course/exam3/q17
echo "  ✓ Created /opt/course/exam3/q17 directory"

echo ""
echo "=========================================="
echo "✓ Exam 3 environment ready!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Start individual questions: ./scripts/test_question.sh <number>"
echo "2. Run complete exam test: ./scripts/run_exam3_test.sh"
echo "3. Configure Helm for Q4: helm repo add killershell http://localhost:6000"
echo ""
