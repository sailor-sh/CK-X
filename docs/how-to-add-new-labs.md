# Contributing Labs to CK-X Simulator

This guide explains how to create and contribute your own practice labs for the CK-X Simulator. By following these steps, you can create custom assessment scenarios for Kubernetes certification preparation (CKAD, CKA, CKS) or other container-related topics.

## Lab Structure Overview

Each lab in CK-X Simulator consists of:

1. **Category directory** (`category.json`) that groups the labs
2. **Configuration File** for lab settings and the lab's catalog entry (name, description, difficulty)
3. **Assessment File** containing questions and verification steps
4. **Setup and Verification Scripts** to prepare environments and validate student solutions
5. **Answers File** with solution documentation

# Considerations Before Creating a Lab
1. The cluster will consist of one control-plane node and multiple worker nodes.
2. SSH access to the nodes is not provided, which may restrict the development of labs that require access to Kubernetes internals or node internals.
3. All setup scripts will be executed simultaneously, so ensure that the questions are independent of each other.
4. Limit the setup to a maximum of two worker nodes to reduce system resource consumption during the exam.
5. When creating files in the cluster, use the /tmp/exam directory. This directory will be created during setup and removed during cleanup.


## Step 1: Create Lab Directory Structure

First, create a directory structure for your lab using this pattern:

```
facilitator/
└── assets/
    └── exams/
        └── [category]/
            ├── category.json
            └── [id]/
                ├── config.json
                ├── assessment.json
                ├── answers.md
                └── scripts/
                    ├── setup/
                    │   └── [setup scripts]
                    └── validation/
                        └── [verification scripts]
```

Where:
- `[category]` is a directory with a `category.json` (see Step 6); the existing ones are `ckad`, `cka`, `cks`, `cks-reddit`, `cks-mhagou`, `other`
- `[id]` is a numeric identifier (e.g., `001`, `002`)

For example, to create a new CKAD lab with ID 003:
```
facilitator/assets/exams/ckad/003/
```

## Step 2: Create Configuration File

Create a `config.json` file in your lab directory with the following structure:

```json
{
  "lab": "ckad-003",
  "name": "CKAD Practice Lab - Advanced Deployments",
  "description": "Practice advanced deployment patterns and strategies",
  "difficulty": "Medium",
  "warmUpTimeInSeconds": 260,
  "examDurationInMinutes": 120,
  "workerNodes": 1,
  "answers": "assets/exams/ckad/003/answers.md",
  "questions": "assessment.json",
  "totalMarks": 100,
  "lowScore": 40,
  "mediumScore": 60,
  "highScore": 90
}
```

Parameters:
- `lab`: Unique identifier for the lab (should match directory structure)
- `name`, `description`, `difficulty`: how the lab is listed in the webapp
- `warmUpTimeInSeconds`, `examDurationInMinutes`: preparation time and exam length (defaults: 260 and 120)
- `workerNodes`: Number of worker nodes required for this lab
- `answers`: Path to answers markdown file
- `questions`: sessment JSON filename
- `totalMarks`: Maximum possible score
- `lowScore`, `mediumScore`, `highScore`: Score thresholds for result categorization

## Step 3: Create Assessment File

Create an `assessment.json` file that defines questions, namespaces, and verification steps:

```json
{
  "questions": [
    {
      "id": "1",
      "namespace": "default",
      "machineHostname": "node01",
      "question": "Create a deployment named `nginx-deploy` with 3 replicas using the nginx:1.19 image.\n\nEnsure the deployment is created in the `default` namespace.",
      "concepts": ["deployments", "replication"],
      "verification": [
        {
          "id": "1",
          "description": "Deployment exists",
          "verificationScriptFile": "q1_s1_validate_deployment.sh",
          "expectedOutput": "0",
          "weightage": 2
        },
        {
          "id": "2",
          "description": "Deployment has 3 replicas",
          "verificationScriptFile": "q1_s2_validate_replicas.sh",
          "expectedOutput": "0",
          "weightage": 1
        },
        {
          "id": "3",
          "description": "Deployment uses correct image",
          "verificationScriptFile": "q1_s3_validate_image.sh",
          "expectedOutput": "0",
          "weightage": 1
        }
      ]
    }
    // Add more questions...
  ]
}
```

Each question should include:
- `id`: Unique question identifier
- `namespace`: Kubernetes namespace for the question
- `machineHostname`: The hostname to display for SSH connection
- `question`: The actual task description with formatting:
  - Use `\n` for line breaks to improve readability
  - Put code references, commands, or file paths in backtick (e.g., `nginx:1.19`) which will be highlighted in the UI
  - Structure your question with clear paragraphs separated by blank lines
- `concepts`: Array of concepts/topics covered
- `verification`: Array of verification steps

Each verification step includes:
- `id`: Unique step identifier
- `description`: Human-readable description of what's being checked
- `verificationScriptFile`: Script file path to validate the step (present in /scripts/validation directory)
- `expectedOutput`: Expected return code (usually "0" for success)
- `weightage`: Point value for this verification step

## Step 4: Create Setup and Verification Scripts

The CK-X Simulator uses two types of scripts:

### Setup Scripts

Create setup scripts in the `scripts/setup/` directory to prepare the environment for each question. These scripts run before the student starts the exam to ensure the necessary resources are available.

Example setup script (`scripts/setup/q1_setup.sh`):

```bash
#!/bin/bash
# Setup environment for Question 1

# Create namespace if it doesn't exist
kubectl create namespace default --dry-run=client -o yaml | kubectl apply -f -

# Create any prerequisite resources
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: default
data:
  nginx.conf: |
    server {
      listen 80;
      server_name localhost;
      location / {
        root /usr/share/nginx/html;
        index index.html;
      }
    }
EOF

echo "Environment setup complete for Question 1"
exit 0
```

### Verification Scripts

Create verification scripts in the `scripts/validation/` directory to validate student solutions. Each script should:

1. Check a specific aspect of the solution
2. Return exit code 0 for success, non-zero for failure
3. Output useful information for student feedback

Example verification script (`scripts/validation/q1_s1_validate_deployment.sh`):

```bash
#!/bin/bash
# Check if deployment exists

DEPLOYMENT_NAME="nginx-deploy"
NAMESPACE="default"

kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE &> /dev/null
if [ $? -eq 0 ]; then
  echo "✅ Deployment '$DEPLOYMENT_NAME' exists in namespace '$NAMESPACE'"
  exit 0
else
  echo "❌ Deployment '$DEPLOYMENT_NAME' not found in namespace '$NAMESPACE'"
  exit 1
fi
```

## Step 5: Create Answers File

Create an `answers.md` file containing solutions to your questions. This file will be displayed directly to students when they view the exam answers.

Focus on providing clear, educational solutions with detailed explanations. The file is rendered as standard Markdown, so you can use all Markdown formatting features. Include complete solution commands, explanations of why certain approaches work, and any relevant tips or best practices.

For each question, provide the question text as a heading followed by a comprehensive solution that would help someone understand not just what to do but why that approach is correct.

## Step 6: Category

There is no registry to edit: the facilitator discovers the labs when the webapp asks for them. Every directory under `assets/exams/` that has a `category.json` is a category, and every subdirectory of it with a `config.json` is a lab (a lab without a `lab` id is skipped with a warning in the facilitator log).

```json
{
  "name": "CKS - Reddit",
  "order": 30
}
```

- `name`: category shown in the webapp (defaults to the directory name)
- `order`: position of the category and of its labs in the lists (lower first)

To add a new category, create its directory with a `category.json`; to add a lab to an existing category, add its directory. Nothing else needs to change (rebuild the facilitator image, since the assets are baked into it).

## Best Practices

1. **Realistic Scenarios**: Design questions that mimic real certification exam tasks
2. **Clear Instructions**: Write concise, unambiguous question descriptions
3. **Thorough Verification**: Create scripts that verify all aspects of the solution
4. **Comprehensive Answers**: Provide complete, educational solutions
5. **Progressive Difficulty**: Arrange questions from simple to complex
6. **Namespaces**: Use separate namespaces for different questions to avoid conflicts
7. **Resource Requirements**: Keep resource requirements reasonable

## Testing Your Lab

Before submitting your lab:

1. Build and deploy the simulator with your new lab
2. Go through each question as a student would
3. Verify that all verification scripts work correctly
4. Ensure the answers solve the questions as expected
5. Check that scoring and evaluation work properly

## Contribution Process

1. Fork the CK-X Simulator repository
2. Add your lab following these guidelines
3. Test thoroughly
4. Submit a pull request with a description of your lab

Thank you for contributing to the CK-X community! 