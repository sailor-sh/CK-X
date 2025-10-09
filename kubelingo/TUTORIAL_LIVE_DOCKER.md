Kubelingo Live Docker Walk‑Through (Safe, Isolated)

Objective
- Generate a new lab in isolation, install it into a running CK-X stack without code changes, run it end-to-end, and clean up.

Prerequisites
- Docker + Docker Compose installed
- This repository checked out locally
- No local changes in CK-X (we operate only under `kubelingo/`)

Step 1 — Generate a New Lab (Isolated)
1) Create the lab in deterministic mode (no AI):
   - `python3 -m kubelingo.create_lab --lab-category ckad --lab-id 003 --topic deployment --difficulty medium --hostname ckad9999 --mock --non-interactive`
2) Verify output:
   - Check `kubelingo/out/facilitator/assets/exams/ckad/003/` for `config.json`, `assessment.json`, `answers.md`, and `scripts/{setup,validation}/*`.
3) Validate structure and references:
   - `python3 kubelingo/validate_lab.py --root kubelingo/out --lab-category ckad --lab-id 003`

Notes:
- The generator writes validation script references as a filename only (e.g., `q1_validate.sh`), which CK-X expects under `scripts/validation`.
- Deterministic output ensures stable setup and testable validation.

Step 2 — Bring Up CK-X Locally
1) From the repo root:
   - `docker compose up -d`
2) Confirm services are healthy (especially `facilitator`, `nginx`, `webapp`).

Step 3 — Install the Generated Lab into Facilitator
Important: the facilitator tar-process deletes the `scripts/` folder after packaging. Avoid bind mounts to `/usr/src/app/assets/exams`. Use `docker cp` instead.

1) Capture facilitator container id:
   - `FID=$(docker compose ps -q facilitator)`
2) Copy lab directory into container:
   - `docker cp kubelingo/out/facilitator/assets/exams/ckad/003 "$FID":/usr/src/app/assets/exams/ckad/`
3) Merge the new lab into labs.json so the UI can list it:
   - `docker cp "$FID":/usr/src/app/assets/exams/labs.json kubelingo/out/labs.base.json`
   - `python3 kubelingo/merge_labs.py --root kubelingo/out --lab-category ckad --lab-id 003 --existing kubelingo/out/labs.base.json --out kubelingo/out/labs.merged.json`
   - `docker cp kubelingo/out/labs.merged.json "$FID":/usr/src/app/assets/exams/labs.json`
4) Restart facilitator so it packs the `scripts/` as `assets.tar.gz`:
   - `docker compose restart facilitator`

Alternative: Use the Helper Script
- `chmod +x kubelingo/install_lab.sh`
- `./kubelingo/install_lab.sh --category ckad --id 003`

Step 4 — Run the Lab in the Web App
1) Open the CK-X UI (via nginx, typically `http://localhost:30080`).
2) The new lab should appear in the assessments list (e.g., “CKAD Practice Lab 003”).
3) Start the exam and wait for warm‑up to reach `READY`.
4) Use the terminal/desktop to implement the solution.
5) Click Evaluate — the facilitator executes the validation script(s) on the jumphost and computes the score. View results as usual.

Step 5 — Cleanup (Optional)
1) Remove the test lab from the container:
   - `docker exec "$FID" rm -rf /usr/src/app/assets/exams/ckad/003`
2) Restore/merge labs.json without the lab entry, then restart facilitator:
   - Option A: re‑merge a base labs.json copy excluding the entry.
   - `docker compose restart facilitator`

Appendix A — Using the Kubelingo Modules
- `kubelingo/create_lab.py`: Generates labs (isolated by default to `kubelingo/out`). Use `--mock` for deterministic output; use `--no-mock` later with a provider adapter.
- `kubelingo/validate_lab.py`: Ensures files exist, verification filenames are correct, and scripts are present under `scripts/validation`.
- `kubelingo/merge_labs.py`: Safely merges a generated lab entry into an existing `labs.json` from the running facilitator.
- Docs: `kubelingo/USAGE.md` (quick guide), `kubelingo/INTEGRATION.md` (deep guide).

Appendix B — Optional AI‑Backed Generation (Deferred)
1) Implement a provider adapter under `kubelingo/` (e.g., `provider_adapter.py`) and a question schema normalizer.
2) Export credentials via env vars (kept out of CK-X). Example variables: `KUBELINGO_LLM_PROVIDER=...` plus provider keys.
3) Run: `python3 kubelingo/create_lab.py --lab-category ckad --lab-id 004 --topic networking --difficulty hard --no-mock`
4) Keep approval gates (omit `--non-interactive`); review the generated content before finalizing.
5) Install the lab using the same docker cp + merge process.

Appendix C — Troubleshooting
- Lab not visible: ensure labs.json in the container includes your lab entry; restart facilitator.
- Validation fails unexpectedly: open the validation script in the container under `/usr/src/app/assets/exams/<cat>/<id>/scripts/validation/…` and verify resource names/namespaces.
- Assets not found on jumphost: confirm facilitator started after the lab was copied (it tars scripts on startup); restarting facilitator rebuilds `assets.tar.gz`.
Appendix D — Overwriting an Existing Lab
- To refresh a lab with the same ID (e.g., ckad-003):
  1. Regenerate locally with the same ID:
     - `python3 -m kubelingo.create_lab --lab-category ckad --lab-id 003 --topic deployment --difficulty medium --hostname ckad9999 --mock --non-interactive`
     - Validate: `python3 kubelingo/validate_lab.py --root kubelingo/out --lab-category ckad --lab-id 003`
  2. Copy into the facilitator and restart:
     - `./kubelingo/install_lab.sh --category ckad --id 003`
  3. Reopen the UI and run the lab; your updated verification steps and hostname will apply.
