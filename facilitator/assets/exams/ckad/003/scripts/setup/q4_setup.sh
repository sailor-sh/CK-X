#!/usr/bin/env bash
set -euo pipefail

# Q4 setup: seed Helm releases automatically when Helm + internet are available.
# - Always ensure output dir exists
# - Be idempotent: safe to rerun; don't duplicate resources
# - Do not mark as seeded if Helm/repo unavailable; try again on next run

OUT_DIR=/opt/course/exam3/q04
NS=helm
KCONF="${KUBECONFIG:-/home/candidate/.kube/kubeconfig}"

mkdir -p "$OUT_DIR"

# Ensure namespace exists (no error if already present)
kubectl --kubeconfig "$KCONF" get ns "$NS" >/dev/null 2>&1 || kubectl --kubeconfig "$KCONF" create ns "$NS" >/dev/null 2>&1 || true

# Seed only if helm is present; skip silently otherwise (script is idempotent and can be retried)
if command -v helm >/dev/null 2>&1; then
  # Ensure Bitnami repo exists and is updated
  if ! helm --kubeconfig "$KCONF" repo list 2>/dev/null | awk '{print $1}' | grep -qx "bitnami"; then
    helm --kubeconfig "$KCONF" repo add bitnami https://charts.bitnami.com/bitnami >/dev/null 2>&1 || true
  fi
  helm --kubeconfig "$KCONF" repo update >/dev/null 2>&1 || true

  # Install/upgrade baseline releases in helm namespace
  if ! helm --kubeconfig "$KCONF" -n "$NS" list 2>/dev/null | awk 'NR>1{print $1}' | grep -qx "internal-issue-report-apiv1"; then
    helm --kubeconfig "$KCONF" -n "$NS" upgrade --install internal-issue-report-apiv1 bitnami/nginx >/dev/null 2>&1 || true
  fi
  if ! helm --kubeconfig "$KCONF" -n "$NS" list 2>/dev/null | awk 'NR>1{print $1}' | grep -qx "internal-issue-report-apiv2"; then
    # Seed apiv2 with an older image tag so an upgrade is meaningful
    helm --kubeconfig "$KCONF" -n "$NS" upgrade --install internal-issue-report-apiv2 bitnami/nginx \
      --set image.tag=1.21.6 >/dev/null 2>&1 || true
  fi

fi
