# CKAD Exam 3 (ckad-003)

This lab replicates a third CKAD practice exam adapted from Killer Shell content, aligned to the CK‑X single‑cluster simulator. To prevent collisions, each question runs in its own namespace.

Namespaces
- Questions: `ckad-q01` … `ckad-q22`
- Previews mapped to Q20..Q22: `ckad-p1`, `ckad-p2`, `ckad-p3`
- Special for Q7: `ckad-q07-source` and `ckad-q07-target`

Outputs
- All files under `/opt/course/exam3/qXX/` (or `/opt/course/exam3/p{1..3}/`).

Files
- `config.json` — lab metadata
- `assessment.json` — 22 questions, each with namespace and validation steps
- `scripts/setup/` — optional per‑question or shared setup scripts
- `scripts/validation/` — validation scripts returning 0 on success

Notes
- Helm and container registry steps are environment dependent. See AGENTS.md and GEMINI.md for guidance.
- Initial validators only check the namespace exists (scaffold); expand per question as implementation proceeds.
