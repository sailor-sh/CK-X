#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root_dir/facilitator/assets/exams" || exit 1

fail=0
while IFS= read -r -d '' cfg; do
  rel_cfg="${cfg#./}"
  answers_path=$(jq -r '.answers // empty' "$cfg" 2>/dev/null || echo "")
  if [[ -z "$answers_path" ]]; then
    echo "[ERROR] No 'answers' key in $rel_cfg"
    fail=1
    continue
  fi
  full_path="$root_dir/$answers_path"
  if [[ ! -f "$full_path" ]]; then
    echo "[ERROR] Missing answers file: $answers_path (referenced by $rel_cfg)"
    fail=1
  else
    echo "[OK] ${answers_path}"
  fi
done < <(find . -type f -name config.json -print0)

exit $fail

