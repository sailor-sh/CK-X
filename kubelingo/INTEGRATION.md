Kubelingo Integration Guide (Safe, Isolated)

Goals
- Keep CK-X code and images unchanged; operate from kubelingo/ only.
- Provide deterministic generation (no AI) and optional AI-backed generation.
- Enable local Docker runs to use generated labs without modifying the repo.
- Offer a clear E2E test plan and rollout path.

Modes
- Offline deterministic (default): `--mock` flag generates a single, manifest-driven question with strong setup/validation scripts. Best for testing repeatability.
- Provider-backed (optional): `--no-mock` uses a pluggable provider. Requires adding provider adapter code and credentials. Do this in kubelingo/ only.

1) Generate a Lab (Isolated)
- Command:
  - `python3 -m kubelingo.create_lab --lab-category ckad --lab-id 003 --topic deployment --difficulty medium --mock --non-interactive`
  - Tip: Set the host shown in the question to `ckad9999` to match the environment:
    - Add `--hostname ckad9999`
- Output:
  - `kubelingo/out/facilitator/assets/exams/ckad/003/`
    - `config.json`, `assessment.json`, `answers.md`, `scripts/{setup,validation}/*`
- Validate:
  - `python3 kubelingo/validate_lab.py --root kubelingo/out --lab-category ckad --lab-id 003`

2) Install Into Running Containers (No Code Changes)
Important: facilitator tars `scripts/` and removes them on startup. Do NOT bind-mount `kubelingo/out` into `/usr/src/app/assets/exams`, as the deletion will propagate back.

- Start CK-X normally:
  - `docker compose up -d`

- Copy lab into the facilitator container:
  - `docker cp kubelingo/out/facilitator/assets/exams/ckad/003 facilitator:/usr/src/app/assets/exams/ckad/`

- Merge labs.json to surface the new lab in the web app:
  - `docker cp facilitator:/usr/src/app/assets/exams/labs.json kubelingo/out/labs.base.json`
  - `python3 kubelingo/merge_labs.py --root kubelingo/out --lab-category ckad --lab-id 003 --existing kubelingo/out/labs.base.json --out kubelingo/out/labs.merged.json`
  - `docker cp kubelingo/out/labs.merged.json facilitator:/usr/src/app/assets/exams/labs.json`

- Restart facilitator to rebuild `assets.tar.gz` for the new lab:
  - `docker compose restart facilitator`

3) Use In Web App
- Open the CK-X UI. The new lab should appear in the assessments list.
  - Select the lab, start the exam, and wait for environment `READY`.
  - Answer the question and trigger evaluation; four distinct criteria will be shown and scored.

4) E2E Test Plan
- Unit-level (local):
  - `validate_lab.py` must pass for each generated lab.
  - Optional pytest (kept under kubelingo/tests) can assert that create_lab wrote expected files and that script names match `assessment.json`.

- Integration (containers):
  1. Generate lab with `--mock` and validate.
  2. `docker compose up -d`.
  3. Copy lab and merged labs.json as above.
  4. Restart facilitator.
  5. In UI, select new lab and start exam; confirm warmup completes.
  6. Click Evaluate; confirm `EVALUATED` status and score distribution.

5) AI-Backed Generation (Optional)
- Approach: provide a provider adapter inside kubelingo/ (e.g., `kubelingo/provider_adapter.py`) and schema normalization (`kubelingo/schema.py`).
- Configure via env vars (kept out of CK-X): e.g., `KUBELINGO_LLM_PROVIDER=openai` plus provider-specific keys.
- Run: `python3 kubelingo/create_lab.py --no-mock …` and keep human approval gates enabled (omit `--non-interactive`).
- Do not wire into facilitator yet; keep generation as an offline step until quality is proven.

6) “On-the-Fly” Generation (Deferred Option)
- Sidecar pattern (no CK-X code changes):
  - Run a separate “kubelingo-generator” container exposing an HTTP endpoint that runs `create_lab.py` with a host-mounted output volume.
  - Operator then uses the install steps above (docker cp and labs.json merge) to make the lab available immediately.
- UI integration (would change CK-X):
  - Add a button to call a new facilitator endpoint that spawns `create_lab.py` and updates labs.json. Keep this behind a feature flag (e.g., `KUBELINGO_MODE=1`) to avoid affecting default users. Defer until after the sidecar approach is vetted.

7) Branching Strategy
- Develop entirely under `kubelingo/` in a dedicated branch (e.g., `feature/kubelingo`).
- If you want a “baked-in” lab for demos, add it under `facilitator/assets/exams/...` and update labs.json in that branch only. Main remains untouched.

8) Container Considerations
- Facilitator removes `scripts/` after tarring. Avoid bind mounts to `assets/exams`.
- For reproducibility, pin images in generated manifests (e.g., `nginx:1.25`).
- Ensure generated scripts use idempotent operations and clean namespaces/resources.
- The jumphost consumes assets via the facilitator’s `/api/v1/exams/:id/assets` endpoint automatically during warmup.

9) Cleaning Up
- To remove a test lab from a running facilitator:
  - `docker exec facilitator rm -rf /usr/src/app/assets/exams/<category>/<id>`
  - Copy back the original labs.json or re-merge without the lab entry, then `docker compose restart facilitator`.

10) Overwriting an Existing Lab
- Regenerate the lab locally with the same ID:
  - `python3 -m kubelingo.create_lab --lab-category <cat> --lab-id <id> --topic <t> --difficulty <d> --hostname ckad9999 --mock --non-interactive`
- Validate and install using `./kubelingo/install_lab.sh --category <cat> --id <id>`.
- Restart facilitator (installer does this) and re-run in the UI.
