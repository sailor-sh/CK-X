# CKAD-003 Exam Assets

This directory contains the CKAD practice exam 3 for the CK‑X simulator.

Highlights
- Single-cluster design with namespace isolation per question.
- Outputs are written under `/opt/course/exam3/qXX/` and `/opt/course/exam3/p{1..3}/`.
- Setup scripts are idempotent; validators are namespace-aware.

Namespaces
- Questions use short, memorable names (e.g., `ns-list`, `single-pod`, `jobs`, `helm`, `service-accounts`, `readiness`, `pod-move{,-source,-target}`, `rollout`, `convert-to-deploy`, `services-curl`, `image-logs`, `storage-hostpath`, `pvc-pending`, `secrets-cm`, `configmap-web`, `sidecar-logging`, `init-container`, `svc-fix-endpoints`, `nodeport-30100`).
- Previews: `p1-liveness`, `p2-deploy-svc`, `p3-readiness`
- Special for Q7: `pod-move-source`, `pod-move-target`

Gotchas
- Q4 (Helm): Requires `helm`. Setup seeds releases: `internal-issue-report-apiv1` and `internal-issue-report-apiv2` in `helm`. The task requires deleting `apiv1`, upgrading `apiv2`, and installing a new `internal-issue-report-apache` with 2 replicas. Validators require Helm; no degraded path.
- Q11 (Container tooling + Registry): Requires Docker and a local registry at `localhost:5000`. Validators assert the built/pushed image tag, a running `sun-cipher` container from `localhost:5000/sun-cipher:v1-docker`, and the registry tag presence.
- Q12 (hostPath PV): The PV uses `hostPath: /Volumes/Data` with `type: DirectoryOrCreate` so it works across environments without manual node prep. To prevent the cluster's default StorageClass from being applied, set `storageClassName: ""` (empty) on the PVC. Pods should generally become Ready. Validators only assert that pods are created (not strictly Ready) for broader compatibility.
- Q13 (Storage): PVC may stay `Pending` without a matching provisioner; validators account for this.
- Q18 (Service): Setup is intentionally broken (wrong selector and wrong targetPort). Validators require both endpoints to exist and the endpoint port to be 4444 after the fix.
- Q19 (NodePort): Validators check type and `nodePort=30100`.

Validate Locally
- Prefer `make up` and `make check-answers` workflows.
- Ensure `.env` reflects `CKX_PLATFORM=linux/arm64` and images support arm64.
