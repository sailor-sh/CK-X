# Exam 3 (ckad-003) — Developer Guide

This guide explains how to run CKAD Exam 3 locally, reset cleanly between runs, and what to check if something is off.

## Quick Start

Start the simulator and take CKAD-003:

- `docker compose up -d`
- Open http://localhost:30080 → Start Exam → “CKAD Comprehensive Lab - 3”

## Reset and pull fresh (one command)

If you need a clean slate and fresh images:

- `./scripts/reset_and_pull_exam3.sh`

This stops the stack, removes volumes, forces fresh image pulls, and starts everything again.

## Where the exam lives

- `facilitator/assets/exams/ckad/003/` contains `assessment.json`, `config.json`, setup and validation scripts, and `answers.md`.

## Starting Exam 3 in the UI

1. Visit http://localhost:30080
2. Click “Start Exam” → choose “CKAD Comprehensive Lab - 3”
3. The prep will run:
   - Clean/re-create the k3d cluster at port 6443
   - Generate kubeconfig for siblings (mounted to SSH terminal)
   - Run Exam 3 setup scripts

## Using kubectl (SSH panel)

- Use the SSH terminal panel for kubectl.
- It’s preconfigured with:
  - `kubectl` installed
  - `KUBECONFIG=/home/candidate/.kube/kubeconfig` (mounted from the cluster container)
- Quick checks:
  - `kubectl cluster-info` (should show `https://k8s-api-server:6443`)
  - `kubectl get nodes` (server Ready)
  - `kubectl get ns`

## File outputs and validation

- Write all files under `/opt/course/exam3/qXX/`.
- That path is a shared volume; validators on the jumphost will see your files.
  - Example (Q1): `mkdir -p /opt/course/exam3/q01 && kubectl get ns > /opt/course/exam3/q01/namespaces`

## Resizing the UI

- Drag the thin vertical divider to resize panels.
- Or use “Exam Interface” → Maximize Questions / Maximize VNC / Reset Layout.
- Long lines in question text wrap automatically.

## Troubleshooting

Problem: “Preparing Your Lab Environment” never finishes
- Check logs:
  - `docker compose logs facilitator | tail -n 200`
  - `docker compose logs jumphost | tail -n 200`
- Try a clean reset: `./scripts/reset_and_pull_exam3.sh`

Problem: kubectl connection refused
- In SSH panel:
  - `echo $KUBECONFIG` → `/home/candidate/.kube/kubeconfig`
  - `grep server $KUBECONFIG` → `https://k8s-api-server:6443`
  - `kubectl cluster-info` and `kubectl get nodes` should work
- If not, reset clean: `./scripts/reset_and_pull_exam3.sh`

Problem: File-based validations fail to see my files
- Use the SSH panel and write under `/opt/course/exam3/qXX/`.
- That directory is shared to the validator.

## Notes

- The labs list is served by: `http://localhost:30080/facilitator/api/v1/assessments/`.
- We’ve kept a legacy alias `/facilitator/api/v1/assements/` for compatibility.
- This environment uses `k3d` (not `kind`). The API server is fixed at `6443` and kubeconfig is rewritten to use `https://k8s-api-server:6443` for sibling container access.
