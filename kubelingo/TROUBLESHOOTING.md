Kubelingo Troubleshooting

Common Issues and Fixes

1) “must specify at least one container source” during docker cp
- Cause: empty facilitator container ID variable; Docker treats both paths as host paths.
- Fix:
  - Ensure you’re in the CK-X repo root (where docker-compose.yaml lives): `cd /path/to/CK-X`
  - Start services: `docker compose up -d` (or `docker-compose up -d`)
  - Capture container ID:
    - `FID=$(docker compose ps -q facilitator); echo "$FID"`
    - If empty: `FID=$(docker ps --filter "name=facilitator" -q | head -n1); echo "$FID"`
  - Ensure destination exists: `docker exec "$FID" mkdir -p /usr/src/app/assets/exams/ckad`
  - Retry copy: `docker cp kubelingo/out/facilitator/assets/exams/ckad/003 "$FID":/usr/src/app/assets/exams/ckad/`

2) merge_labs.py: “missing config.json for lab …”
- Cause: you ran merge_labs.py from a different working directory, so `--root` pointed to the wrong path.
- Fix (use absolute paths):
  - Generate the lab if needed:
    - `python3 -m kubelingo.create_lab --root /ABS/PATH/CK-X/kubelingo/out --lab-category ckad --lab-id 003 --topic deployment --difficulty medium --mock --non-interactive`
  - Merge using absolute paths:
    - `python3 /ABS/PATH/CK-X/kubelingo/merge_labs.py \
        --root /ABS/PATH/CK-X/kubelingo/out \
        --lab-category ckad \
        --lab-id 003 \
        --existing /ABS/PATH/CK-X/kubelingo/out/labs.base.json \
        --out /ABS/PATH/CK-X/kubelingo/out/labs.merged.json`

3) New lab not visible in web UI
- Ensure you copied the lab directory into the facilitator container.
- Ensure you merged labs.json and copied it back into the container.
- Restart facilitator: `docker compose restart facilitator`

4) Assets/validation not running on jumphost
- Facilitator tars the `scripts/` folder into `assets.tar.gz` at startup and removes `scripts/` on disk.
- If you copied a lab while facilitator was already running, you must restart the facilitator so the tar is created for the new lab.

5) docker compose vs docker-compose
- Use `docker compose` if available. If not, use `docker-compose` and adapt any scripts accordingly.

6) Verifying the generated lab locally
- Run the validator:
  - `python3 kubelingo/validate_lab.py --root kubelingo/out --lab-category ckad --lab-id 003`
- Inspect validation script:
  - `kubelingo/out/facilitator/assets/exams/<cat>/<id>/scripts/validation/q*_validate.sh`

