# Kubelingo: Exam Development and Testing

This directory contains the tools and assets for creating, managing, and testing exams for the CK-X simulator.

## 1. Folder Structure

- **/CKAD-exam3_113025**: Staging and development area for the CKAD Exam 3. Contains the original PDF, Python scripts for question generation, and test files. This is a temporary development directory and its contents should be considered volatile.
- **/facilitator/assets/exams/ckad/003**: The final, canonical location for the CKAD Exam 3 assets. This includes the `assessment.json`, `config.json`, and the `setup` and `validation` scripts.
- **/out**: A directory for generated output, not checked into version control.

## 2. Exam Architecture: CKAD Exam 3 (`ckad-003`)

- **Namespace Isolation:** To prevent resource collisions in the single-cluster environment, each question is isolated in its own namespace (e.g., `ckad-q01`, `ckad-q02`, etc.).
- **Setup Scripts:** Located in `facilitator/assets/exams/ckad/003/scripts/setup/`. These scripts are responsible for seeding the environment for each question (e.g., creating resources, namespaces).
- **Validation Scripts:** Located in `facilitator/assets/exams/ckad/003/scripts/validation/`. These scripts are used to verify that a question has been answered correctly.
- **`assessment.json`**: The core of the exam, defining each question, its namespace, the question text, and linking to the corresponding validation script.

## 3. How to Add a New Exam

1.  **Create a Development Directory:** Create a new directory under `kubelingo` for your exam (e.g., `CKAD-exam4_YYYYMMDD`).
2.  **Generate Questions:** Use Python scripts (like `generate_exam3_questions.py` as a template) to create the `qXX.yaml` or similar question definition files.
3.  **Create `assessment.json`:** Generate the main `assessment.json` file with the question text, namespaces, and links to validation scripts.
4.  **Write Setup and Validation Scripts:** Create the necessary setup and validation shell scripts. Place them in the appropriate `facilitator/assets/exams/<exam_name>/<version>/scripts/` directory.
5.  **Register the Exam:** Add a new entry for your exam in `facilitator/assets/exams/labs.json`.

## 4. How to Test an Exam

The primary testing scripts are located in `kubelingo/CKAD-exam3_113025/exam3-testing_113025/`.

- **`test_exam3.sh`**: Runs the full automated test suite, checking for YAML generation, namespace creation, directory structure, and more.
- **`test_question.sh <question_number>`**: Runs a specific set of validation checks for an individual question.

**Example Test Workflow:**

1.  **Start the Simulator:** Ensure the CK-X simulator is running.
2.  **Start the Exam in the UI:** Open `http://localhost:30080`, select your exam, and click "Start". This will automatically run the necessary setup scripts.
3.  **Simulate User Actions:** For each question, manually perform the required actions (e.g., creating files, running `kubectl` commands).
4.  **Run Validation:** Execute the validation script for the question to check your work:
    ```bash
    bash facilitator/assets/exams/ckad/003/scripts/validation/q1_validate.sh
    ```

## 5. Agent Roles and Collaboration

- **Codex (Main Agent):** Responsible for implementing new exams, creating setup/validation scripts, and defining the `assessment.json`.
- **Gemini (Testing Agent):** Responsible for verifying the work of Codex by running tests, checking for inconsistencies, and ensuring the exam works as expected from a user's perspective.

All agent-related planning and status updates should be logged in the root `GEMINI.md` file.
