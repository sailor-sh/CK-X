# CKX Multi-Session Execution Model — Design Spec

This document defines how CKX supports **multiple concurrent exam sessions** with strict isolation. It is a design specification only; no code refactors are implied.

**Alignment:** This design respects the [Architecture Contract](ARCHITECTURE-CONTRACT.md). CKX remains stateless at the API boundary (sessionId-driven); session state is **runtime state** (provisioned resources), not business state (users, payments, or access rules).

---

## 1. Requirements (Invariants)

| # | Requirement |
|---|--------------|
| R1 | CKX supports **multiple concurrent** exam sessions. |
| R2 | Each session is **isolated** at **filesystem**, **process**, and **Kubernetes/Docker** level. |
| R3 | **No shared globals**: no single global terminal, VNC server, or cluster shared across sessions. |
| R4 | **No shared volumes** between sessions. |
| R5 | **No shared terminals**: each session has its own SSH/pty and VNC instances. |
| R6 | **sessionId is mandatory** in all execution paths (API, routing, provisioning, cleanup). |

---

## 2. Session Lifecycle States

A session is a first-class entity with a well-defined state machine. All transitions are driven by CKX internal logic or by Sailor API (e.g. "end session"); CKX does not interpret user or payment state.

### 2.1 State Diagram (Conceptual)

```
                    +------------------+
                    |   REQUESTED      |  (session create requested; not yet provisioning)
                    +--------+--------+
                             |
                             v
                    +------------------+
                    |  PROVISIONING    |  (allocating namespace, containers, volumes, lab)
                    +--------+--------+
                             |
              +--------------+--------------+
              |              |              |
              v              v              v
     +-------------+  +------------+  +-----------+
     |   READY     |  |  FAILED    |  | CANCELLED |
     +------+------+  +------------+  +-----------+
            |                (terminal; no retry without new session)
            |  (session active; exam can run)
            |
            v
     +-------------+
     |   ACTIVE    |  (at least one client connected or exam content loaded)
     +------+------+
            |
     +------+------+
     |             |
     v             v
+----------+  +-----------+
| ENDING   |  | EXPIRED   |  (time-based or Sailor API signal)
+----+-----+  +-----------+
     |
     v
+----------+
| RELEASED |  (resources torn down; sessionId may be retained for audit only)
+----------+
```

### 2.2 State Definitions

| State | Description | Session resources |
|-------|-------------|-------------------|
| **REQUESTED** | Create received; session record created; provisioning not started. | None. Only in-memory or minimal store (sessionId, createdAt). |
| **PROVISIONING** | CKX is allocating namespace, containers, volumes, and lab (K8s cluster or namespace, VNC, terminal). | Partial; some resources may exist. |
| **READY** | Lab and runtime are ready; no client activity yet. | Full set allocated; session can accept traffic. |
| **ACTIVE** | Session is in use (client connected and/or exam content served). | Same as READY. |
| **FAILED** | Provisioning or health check failed. No retry on same session. | Best-effort cleanup; no stable resources. |
| **CANCELLED** | Session create or start was cancelled before READY. | Best-effort cleanup. |
| **ENDING** | Tear-down requested (by Sailor API or expiry); cleanup in progress. | Resources being removed. |
| **EXPIRED** | Session reached its TTL or was marked expired; will transition to ENDING. | Same as ACTIVE until cleanup. |
| **RELEASED** | Resources torn down. sessionId may remain for idempotency or audit. | None. |

### 2.3 Allowed Transitions

| From | To | Trigger |
|------|-----|--------|
| REQUESTED | PROVISIONING | Start provisioning. |
| REQUESTED | CANCELLED | Cancel before provisioning. |
| PROVISIONING | READY | All resources up and health checks pass. |
| PROVISIONING | FAILED | Provisioning or health check failed. |
| PROVISIONING | CANCELLED | Cancel during provisioning. |
| READY | ACTIVE | First use (e.g. get runtime info or connect). |
| ACTIVE | ENDING | Sailor API "end session" or client-triggered end. |
| ACTIVE | EXPIRED | TTL reached (CKX enforces only if configured; Sailor API may own policy). |
| READY | ENDING | End before any use. |
| EXPIRED | ENDING | CKX starts teardown. |
| ENDING | RELEASED | Teardown complete. |
| FAILED, CANCELLED | — | Terminal; no further transitions. |

---

## 3. Required Session Metadata

CKX maintains **only** what is needed for execution and isolation. No user id, tenant id, or payment fields.

### 3.1 Mandatory (per session)

| Field | Type | Purpose |
|-------|------|--------|
| **sessionId** | string (opaque, unique) | Identity in all paths; required in every API call and internal routing. |
| **state** | enum | One of the lifecycle states in §2. |
| **createdAt** | timestamp | When the session was created (for TTL and audit). |
| **expiresAt** | timestamp (optional) | When CKX must treat the session as expired; if present, CKX may transition to EXPIRED → ENDING. |

### 3.2 Execution / Isolation (set at provisioning, used for routing and cleanup)

| Field | Type | Purpose |
|-------|------|---------|
| **namespace** | string | K8s namespace name for this session (e.g. `ckx-session-<sessionId-sanitized>`). |
| **runtimeId** | string (optional) | Id of the runtime stack (e.g. Docker Compose project name, or K8s namespace). Used to target teardown. |
| **vncEndpoint** | object (optional) | Host/port/path for VNC for this session (or URL only; no credentials in metadata if possible). |
| **terminalEndpoint** | object (optional) | Host/port for SSH/terminal for this session. |
| **clusterRef** | string (optional) | K3d cluster name or in-cluster namespace; used for lab isolation. |

### 3.3 Content / Config (provided by Sailor API at create or before READY)

| Field | Type | Purpose |
|-------|------|---------|
| **durationMinutes** | number (optional) | Exam duration for timer; CKX may use for local display only. |
| **questions** | array (optional) | Exam content for this session; may be loaded later via API. |
| **labSpec** | object (optional) | e.g. node count, image; used by provisioning. |

### 3.4 What CKX does NOT store

- User identifier, tenant identifier, or any auth token.
- Payment or entitlement flags.
- Business "exam id" or "product id" except as optional labels for operational correlation (no logic on them).

---

## 4. How Isolation Is Enforced

Isolation is enforced at **namespace**, **container**, and **volume** level so that one session cannot see or affect another.

### 4.1 Kubernetes / Cluster Isolation

| Mechanism | Description |
|-----------|-------------|
| **Per-session namespace** | Each session gets a dedicated Kubernetes namespace (e.g. `ckx-<sessionId-hash>`). All session lab workloads (pods, services, configmaps) live in that namespace. No cross-namespace access for session workloads. |
| **Optional per-session cluster** | For maximum isolation, each session can get its own K3d/Kind cluster (e.g. `k3d-ckx-<sessionId-hash>`). Cluster lifecycle is created at provisioning and deleted at RELEASED. This avoids shared API server and etcd. |
| **Namespace-scoped kubeconfig** | If using a shared cluster, the jumphost (or equivalent) for the session receives a kubeconfig that is restricted to that session’s namespace only (e.g. via RBAC). No shared `kube-config` volume across sessions. |

**Decision (design time):** Either "one namespace per session in a shared cluster" or "one cluster per session." The spec requires that **at least one** of these is used so that no two sessions share the same cluster scope (when using shared cluster, namespace separation is mandatory).

### 4.2 Container / Process Isolation

| Mechanism | Description |
|-----------|-------------|
| **Per-session VNC container** | Each session has its own VNC server container (or pod). No shared `remote-desktop` instance. Containers are named or labeled with sessionId (e.g. `ckx-vnc-<sessionId-hash>`). |
| **Per-session terminal container** | Each session has its own SSH/terminal container (or pod). No shared `remote-terminal` instance. Same naming/labeling with sessionId. |
| **Per-session jumphost (if used)** | If CKX uses a jumphost for lab setup, it is either a dedicated container per session or an isolated process/namespace (e.g. container) so that `prepare-exam-env` and `cleanup-exam-env` run in a session-scoped context. No shared jumphost process. |
| **Webapp / gateway** | The webapp (or API gateway) is **stateless**: it does not hold session-specific connections in process globals. It routes every request by sessionId to the correct VNC/terminal/backend (e.g. via routing table or sidecar). |

### 4.3 Volume / Filesystem Isolation

| Mechanism | Description |
|-----------|-------------|
| **No shared volumes** | No volume is mounted into more than one session’s containers. The current single `kube-config` volume shared by jumphost and kind-cluster is **not** allowed in multi-session mode. |
| **Per-session volumes** | Each session gets its own volumes (e.g. Docker named volumes `ckx-<sessionId-hash>-kubeconfig`, or K8s PVCs in the session namespace). |
| **Per-session scratch space** | Paths like `/tmp/exam-assets`, `/tmp/exam-env` are session-scoped (e.g. `/tmp/sessions/<sessionId>/exam-assets`). No global `/tmp/exam-*` shared across sessions. |

### 4.4 Network Isolation (Optional but Recommended)

| Mechanism | Description |
|-----------|-------------|
| **Per-session network** | Each session’s containers can be attached to a dedicated Docker network (e.g. `ckx-network-<sessionId-hash>`) or use K8s network policies in the session namespace so that session traffic does not cross to other sessions. |
| **No cross-session DNS** | Service discovery (e.g. `remote-desktop`, `remote-terminal`) resolves only to the session’s own containers; no shared hostnames across sessions. |

### 4.5 sessionId in All Execution Paths

| Path | Requirement |
|------|-------------|
| **API** | Every CKX API operation includes sessionId (path, query, or header). No operation is performed without a valid sessionId. |
| **Routing** | Internal routing (webapp → VNC, webapp → terminal, proxy → backend) uses sessionId to select the session’s endpoint. |
| **Provisioning** | Prepare scripts and orchestrator receive sessionId; all created resources are tagged/labeled with it. |
| **Cleanup** | Teardown uses sessionId (or runtimeId derived from it) to delete only that session’s namespace, containers, and volumes. |
| **Logging / metrics** | All logs and metrics are tagged with sessionId for traceability; no global "current session" variable. |

---

## 5. Session Expiry and Termination Behavior

### 5.1 When a Session Expires (TTL Reached)

- **Definition:** `expiresAt` is in the past (or a configured TTL from `createdAt` has elapsed).
- **CKX behavior:**
  1. Transition session state to **EXPIRED** (if not already ENDING/RELEASED).
  2. Transition to **ENDING** and start teardown (same as §5.2).
  3. Do **not** accept new requests for this sessionId (return 410 Gone or 404).
  4. Existing connections (VNC, terminal) may be closed by CKX during teardown; clients receive connection loss.

### 5.2 When a Session Is Terminated (Sailor API or Client "End Session")

- **Trigger:** Sailor API calls CKX "end/release session" with sessionId, or client signals end (via Sailor API).
- **CKX behavior:**
  1. Transition session state to **ENDING**.
  2. **Teardown sequence:**
     - Stop accepting new connections for this sessionId.
     - Run session-scoped cleanup (e.g. `cleanup-exam-env` in the session’s jumphost/context with sessionId).
     - Delete session’s K8s namespace (or delete session’s K3d cluster).
     - Stop and remove session’s containers (VNC, terminal, jumphost if per-session).
     - Remove session’s volumes.
     - Remove session from routing table (if any).
  3. Set state to **RELEASED**.
  4. Optionally retain a minimal record (sessionId, state=RELEASED, releasedAt) for idempotency (e.g. "end session" again returns success) and audit.

### 5.3 Idempotency

- **End session** with sessionId already in RELEASED (or FAILED/CANCELLED): return success, no-op.
- **Get runtime / content** for sessionId in ENDING, EXPIRED, or RELEASED: return 410 Gone (or 404) with no resource usage.

### 5.4 Orphan Prevention

- A **session reaper** (background process or cron) should periodically list sessions in READY or ACTIVE and compare `expiresAt` (and optionally last activity). Sessions past expiry are transitioned to EXPIRED → ENDING → RELEASED.
- Sessions stuck in PROVISIONING beyond a timeout should transition to FAILED and trigger best-effort cleanup.

---

## 6. Summary Table: Isolation and sessionId

| Layer | Isolation mechanism | sessionId usage |
|-------|---------------------|------------------|
| API | All operations take sessionId | Mandatory in request; used for lookup and authz (session exists and is active). |
| Kubernetes | Per-session namespace or per-session cluster | Namespace/cluster name derived from sessionId. |
| Containers | Per-session VNC, terminal, jumphost | Container names/labels include sessionId. |
| Volumes | Per-session volumes only | Volume names include sessionId (or runtimeId). |
| Filesystem | Per-session paths (e.g. /tmp/sessions/<sessionId>/...) | All scratch and assets under session path. |
| Network | Per-session network or namespace isolation | No shared DNS/hostnames across sessions. |
| Process / app | No global "current session" | Stateless routing by sessionId only. |

---

## 7. Out of Scope for This Spec

- Concrete API URLs, request/response schemas, or wire format.
- Implementation choice: one cluster + many namespaces vs. many clusters.
- Sailor API contract details (already in ARCHITECTURE-CONTRACT.md).
- Capacity limits, quotas, or scheduling (how many sessions per node).
- Persistence of session metadata (DB vs. in-memory vs. distributed store).

This document is the **design spec** for the CKX multi-session execution model. Future implementation work must adhere to it.
