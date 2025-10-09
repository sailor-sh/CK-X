# Contributing Labs to CK-X Simulator

This guide explains how to create and contribute your own practice labs for the CK-X Simulator. By following these steps, you can create custom assessment scenarios for Kubernetes certification preparation (CKAD, CKA, CKS) or other container-related topics.

## Lab Structure Overview

Each lab in CK-X Simulator consists of:

1. Lab Entry in the main labs registry
2. Configuration File for lab settings
3. Assessment File containing questions and verification steps
4. Setup and Verification Scripts to prepare environments and validate student solutions
5. Answers File with solution documentation

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
- `[category]` is the certification type (e.g., `ckad`, `cka`, `cks`, `other`)
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

## Step 6: Register Your Lab

Finally, add your lab to the main `labs.json` file:

```json
{
  "labs": [
    // ... existing labs ...
    {
      "id": "ckad-003",
      "assetPath": "assets/exams/ckad/003",
      "name": "CKAD Practice Lab - Advanced Deployments",
      "category": "CKAD",
      "description": "Practice advanced deployment patterns and strategies",
      "warmUpTimeInSeconds": 60,
      "difficulty": "medium"
    }
  ]
}
```

Parameters:
- `id`: Unique identifier (should match directory structure)
- `assetPath`: Path to lab resources
- `name`: Display name for the lab
- `category`: Lab category (CKAD, CKA, CKS, etc.)
- `description`: Brief description of the lab content
- `warmUpTimeInSeconds`: Preparation time before exam starts
- `difficulty`: Difficulty level (easy, medium, hard)

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

## Appendix: AI-Powered Interactive Lab Generation

To accelerate the creation of new labs, we provide an interactive, AI-powered script that automates the entire process described above. This script acts as a guided assistant, generating all necessary files and code while pausing at each critical step for your review and approval.

This approach combines the speed of AI generation with the quality assurance of manual oversight, ensuring that the final lab meets our standards.

### How It Works

The script leverages the `question_generator` and `script_generator` libraries, using an AI model to generate content and code. It presents each generated piece to you for approval, allowing you to:

- **Approve:** Accept the generated content and proceed to the next step.
- **Retry:** Discard the content and ask the AI to generate a new version.
- **Edit:** Manually modify the generated content before approving.

### Step-by-Step Guided Generation

The script will guide you through the following gated stages:

**Step 1: Initialize Lab**
- **Action:** The script prompts you for a high-level description of the lab (e.g., "A CKA lab of medium difficulty about creating a Pod that uses a projected volume").
- **AI Generation:** It suggests a unique lab ID, a name, a description, and creates the directory structure.
- **Manual Gate:** You are asked to confirm these initial details. You can edit the name or description before proceeding.

**Step 2: Generate and Approve Question**
- **Action:** Based on your description, the script uses the AI to generate the main question text.
- **AI Generation:** A formatted question is created.
- **Manual Gate:** The generated question is displayed. You can approve, retry, or edit it.

**Step 3: Generate and Approve Verification Steps**
- **Action:** The script sends the approved question to the AI to be broken down into small, verifiable steps.
- **AI Generation:** A list of verification steps is created (e.g., "1. Pod exists", "2. Uses projected volume").
- **Manual Gate:** The list of steps is displayed for your review. You can edit the descriptions or add/remove steps.

**Step 4: Generate and Approve Scripts**
- **Action:** For each approved verification step, the script generates the necessary setup and validation shell scripts.
- **AI Generation:** A `.sh` script is generated for each step.
- **Manual Gate:** Each script is displayed to you one by one. You can review the code, test it if you wish, and then approve, retry, or edit it. This is the most critical review stage.

**Step 5: Generate and Approve Final Documents**
- **Action:** The script generates the content for the `answers.md` file and the `config.json` file.
- **AI Generation:** A detailed, educational answer and a complete JSON configuration are created.
- **Manual Gate:** Both documents are displayed for your final review and approval.

**Step 6: Finalize and Register Lab**
- **Action:** Once all components are approved, the script writes all the content to the correct files within the lab's directory structure. It then adds the new lab to the main `labs.json` registry.
- **Confirmation:** The script confirms that the lab has been successfully created and registered.

### Implementing the Interactive Lab Generation Script

This section provides a high-level guide for creating the `create_lab.py` script.

#### 1. Setup and Dependencies

The script will be a Python application. It should use a library like `click` or `argparse` for command-line interaction and `PyYAML` for handling JSON/YAML files.

**Dependencies:**
- `click`: For creating a clean command-line interface.
- `PyYAML`: For reading and writing `assessment.json` and `config.json`.
- Your existing project libraries: `question_generator`, `script_generator`.

#### 2. Core Structure

A class-based approach is recommended to manage the state of the lab being created.

```python
import click
import yaml
from .question_generator import QuestionGenerator # Assuming relative import
from .script_generator import ScriptGenerator # Assuming relative import

class InteractiveLabBuilder:
    def __init__(self):
        self.lab_data = {}
        self.question_generator = QuestionGenerator()
        self.script_generator = ScriptGenerator()

    def run(self):
        """Main entry point to run the interactive workflow."""
        self.step_1_initialize_lab()
        self.step_2_generate_question()
        self.step_3_define_verification()
        self.step_4_generate_scripts()
        self.step_5_generate_docs()
        self.step_6_finalize()

    # ... methods for each step ...

@click.command()
def create_lab():
    """Interactively builds a new CK-X Simulator lab."""
    builder = InteractiveLabBuilder()
    builder.run()

if __name__ == "__main__":
    create_lab()
```

#### 3. Implementing the Gated Stages

Each step should be a method in the `InteractiveLabBuilder` class. The "gate" can be implemented with a helper function that handles the user interaction loop.

**Helper Function for Manual Gates:**

```python
def prompt_for_approval(self, title: str, content: str) -> tuple[bool, str]:
    """
    Displays content to the user and asks for approval, retry, or edit.
    Returns (is_approved, final_content).
    """
    while True:
        click.secho(f"--- {title} ---", fg="cyan")
        click.echo(content)
        click.secho("--------------------", fg="cyan")
        choice = click.prompt(
            "Please review. [A]pprove, [R]etry, [E]dit?",
            type=click.Choice(['A', 'R', 'E'], case_sensitive=False),
            default='A'
        )

        if choice.upper() == 'A':
            return (True, content)
        elif choice.upper() == 'R':
            click.echo("Retrying generation...")
            return (False, content)
        elif choice.upper() == 'E':
            edited_content = click.edit(content)
            if edited_content is not None:
                content = edited_content
                # Loop again to show the edited content for final approval
            else:
                click.echo("Edit cancelled. Showing original content again.")
```

**Implementation of a Stage (Example: Step 2):**

```python
def step_2_generate_question(self):
    click.echo("\n--- Step 2: Generate Question ---")
    while True:
        # Use the AI to generate the question
        generated_question = self.question_generator.generate(
            topic=self.lab_data['topic'],
            difficulty=self.lab_data['difficulty']
        )
        
        # Present it to the user for approval
        is_approved, final_text = self.prompt_for_approval(
            "Generated Question",
            generated_question['text']
        )
        
        if is_approved:
            self.lab_data['question_content'] = final_text
            # Also store other generated data like concepts
            self.lab_data['concepts'] = generated_question['concepts']
            click.secho("Question approved.", fg="green")
            break
```

#### 4. Script Generation Logic (Step 4)

This is the most complex stage. You will loop through the verification steps approved in Step 3 and generate a script for each one.

```python
def step_4_generate_scripts(self):
    click.echo("\n--- Step 4: Generate Scripts ---")
    self.lab_data['scripts'] = {}
    
    for step in self.lab_data['verification_steps']:
        while True:
            # Use the AI to generate a validation script
            script_code = self.script_generator.generate_validation_script(
                question=self.lab_data['question_content'],
                verification_description=step['description']
            )
            
            script_filename = f"q{self.lab_data['id']}_s{step['id']}_validate.sh"
            
            is_approved, final_code = self.prompt_for_approval(
                f"Generated Script: {script_filename}",
                script_code
            )
            
            if is_approved:
                self.lab_data['scripts'][script_filename] = final_code
                click.secho(f"Script {script_filename} approved.", fg="green")
                break
    
    # Also generate the setup script here
    # ...
```

#### 5. Finalization (Step 6)

In the final step, the script will take all the approved data stored in `self.lab_data` and write it to the file system using standard Python file I/O and the `yaml` library.

```python
def step_6_finalize(self):
    click.echo("\n--- Step 6: Finalizing Lab ---")
    
    # Create directory structure
    # ...
    
    # Write assessment.json
    # ...
    
    # Write config.json
    # ...
    
    # Write answers.md
    # ...
    
    # Write all approved scripts to the scripts/validation/ directory
    # ...
    
    # Update the main labs.json registry
    # ...
    
    click.secho(f"Lab '{self.lab_data['id']}' created successfully!", fg="green")
```

### Testing the Script

The script should be tested to ensure each stage functions correctly. A good approach is to create a mock `QuestionGenerator` and `ScriptGenerator` that return predictable, hard-coded content. This allows you to test the interactive workflow (the approval gates, editing, and retrying) without making actual AI API calls, which can be slow and costly.

A test file, `test_create_lab.py`, could use a library like `pytest` and `click.testing.CliRunner` to simulate user input and verify that the correct files are created at the end of the process.

```
