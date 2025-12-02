Kubelingo: Isolated Lab Generation (No CK-X Changes)

Overview
- Generate high‑quality, single‑question or small labs in an isolated folder without touching CK-X.
- Default output root: `kubelingo/out`.
- Optional: manually install a generated lab into CK-X when you’re ready.

Quick Start (Isolated)
- Generate a mock, deterministic lab (single question with setup + validation scripts):
  - `python3 -m kubelingo.create_lab --lab-category ckad --lab-id 003 --topic deployment --difficulty medium --hostname ckad9999 --mock --non-interactive`
- Output will be under: `kubelingo/out/facilitator/assets/exams/ckad/003/`
  - Files: `config.json`, `assessment.json`, `answers.md`, `scripts/…`
- Validate the lab structure and references:
  - `python3 kubelingo/validate_lab.py --root kubelingo/out --lab-category ckad --lab-id 003`

Install Into a Running Facilitator (Helper Script)
- Make the helper executable and run:
  - `chmod +x kubelingo/install_lab.sh`
  - `./kubelingo/install_lab.sh --category ckad --id 003`
- This script will:
  - Ensure the stack is up
  - Copy the lab into the facilitator container
  - Merge labs.json (using kubelingo/merge_labs.py)
  - Restart facilitator so `assets.tar.gz` is rebuilt

Troubleshooting
- See `kubelingo/TROUBLESHOOTING.md` for fixes to common issues (empty container ID, wrong paths, visibility in UI, etc.).

What Gets Generated
- Setup script: cleans namespace(s) and prepares resources deterministically.
- Validation script: checks resource existence and key fields (replicas, images, selectors, probes, ports).
- Assessment: references validation script using filename only (CK-X compatible convention).
- Answers: contains the question and suggested manifest.

Installing Into CK-X (Manual, Optional)
1) Copy the generated lab into CK-X assets:
   - From `kubelingo/out/facilitator/assets/exams/<category>/<id>/` to `facilitator/assets/exams/<category>/<id>/`.
2) Update `facilitator/assets/exams/labs.json` to include the new entry:
   - `{ "id": "<category>-<id>", "assetPath": "assets/exams/<category>/<id>", "name": "…", "category": "<CATEGORY>", "description": "…", "warmUpTimeInSeconds": 60, "difficulty": "medium" }`
3) Restart the facilitator so it tars the `scripts/` folder into `assets.tar.gz` on startup.

Notes
- By default, this workflow does not write to `facilitator/` or alter CK-X behavior.
- For exam-003 specifics, refer to `exam-003/` at the repo root (consolidated guide + generator).
