/**
 * Container Orchestrator - Per-Session Infrastructure Provisioning
 *
 * Creates isolated VNC desktop and terminal containers for each exam session.
 * Ensures session isolation: each user gets their own desktop environment.
 *
 * Containers are placed on the same Docker network (ckx-network) so CKX webapp
 * can resolve them by container name via Docker DNS.
 */
const Docker = require('dockerode');

const docker = new Docker({ socketPath: '/var/run/docker.sock' });

// Configuration
const NETWORK_NAME = process.env.CKX_DOCKER_NETWORK || 'ckx-network';
const VNC_IMAGE = process.env.CKX_VNC_IMAGE || 'nishanb/ck-x-simulator-remote-desktop:latest';
const TERMINAL_IMAGE = process.env.CKX_TERMINAL_IMAGE || 'nishanb/ck-x-simulator-remote-terminal:latest';
const VNC_PORT = 6901;
const SSH_PORT = 22;

// How long to wait for container readiness (ms)
const READINESS_TIMEOUT_MS = parseInt(process.env.CKX_CONTAINER_READY_TIMEOUT || '30000', 10);
const READINESS_POLL_INTERVAL_MS = 1000;

// On macOS (Docker Desktop), host can't reach container IPs directly.
// We need to publish ports and use localhost. Detect via platform or env override.
const PUBLISH_PORTS = process.env.CKX_PUBLISH_PORTS === 'true' || process.platform === 'darwin';

// Container naming: deterministic from sessionId, safe for Docker
const containerName = (sessionId, type) => `ckx-${type}-${sessionId.slice(0, 12)}`;

/**
 * Check if Docker is available and the network exists
 */
async function checkDockerAvailable() {
  try {
    await docker.ping();
    const networks = await docker.listNetworks({ filters: { name: [NETWORK_NAME] } });
    if (networks.length === 0) {
      console.warn(`[ContainerOrchestrator] Docker available but network '${NETWORK_NAME}' not found`);
      return false;
    }
    return true;
  } catch (err) {
    console.warn('[ContainerOrchestrator] Docker not available:', err.message);
    return false;
  }
}

/**
 * Provision isolated containers for a session.
 * Idempotent: if containers already exist and are running, returns their info.
 *
 * @param {string} sessionId - Unique session identifier (UUID)
 * @param {object} credentials - Session-specific credentials from generateSessionCredentials()
 * @returns {Promise<{vnc: {host, port, password}, ssh: {host, port, username, password}}>}
 */
async function provisionSessionContainers(sessionId, credentials) {
  const shortId = sessionId.slice(0, 12);
  const vncName = containerName(sessionId, 'vnc');
  const terminalName = containerName(sessionId, 'terminal');

  console.log(`[ContainerOrchestrator] Provisioning containers for session ${shortId}`);

  // Check if containers already exist (idempotent)
  const existingVnc = await findContainer(vncName);
  const existingTerminal = await findContainer(terminalName);

  if (existingVnc && existingTerminal) {
    // Ensure they're running
    if (existingVnc.State !== 'running') {
      await docker.getContainer(existingVnc.Id).start();
    }
    if (existingTerminal.State !== 'running') {
      await docker.getContainer(existingTerminal.Id).start();
    }
    console.log(`[ContainerOrchestrator] Reusing existing containers for session ${shortId}`);
    return await buildRuntimeResponse(vncName, terminalName, credentials);
  }

  // Clean up any partial state (one exists but not the other)
  if (existingVnc && !existingTerminal) {
    await removeContainer(vncName);
  }
  if (!existingVnc && existingTerminal) {
    await removeContainer(terminalName);
  }

  const vncPassword = credentials?.vnc?.password || 'bakku-the-wizard';
  const sshUsername = credentials?.ssh?.username || 'candidate';
  const sshPassword = credentials?.ssh?.password || 'password';

  // Create and start VNC container
  const vncContainer = await createVncContainer(vncName, shortId, vncPassword);
  await vncContainer.start();

  // Create and start Terminal container
  const terminalContainer = await createTerminalContainer(terminalName, shortId);
  await terminalContainer.start();

  console.log(`[ContainerOrchestrator] Containers started for session ${shortId}, waiting for readiness...`);

  // Wait for containers to be ready using direct inspect (listContainers has timing issues on Docker Desktop)
  await waitForContainerReady(vncContainer, vncName, READINESS_TIMEOUT_MS);
  await waitForContainerReady(terminalContainer, terminalName, READINESS_TIMEOUT_MS);

  console.log(`[ContainerOrchestrator] Containers ready for session ${shortId}`);

  return await buildRuntimeResponse(vncName, terminalName, credentials);
}

/**
 * Get container connection info (host + port).
 * On macOS (PUBLISH_PORTS=true): returns localhost + published port
 * On Linux: returns container IP + internal port
 * Fallback: returns container name (works if caller is in Docker network)
 */
async function getContainerEndpoint(containerName, internalPort) {
  try {
    const container = docker.getContainer(containerName);
    const info = await container.inspect();

    if (PUBLISH_PORTS) {
      // Get the dynamically assigned host port
      const portKey = `${internalPort}/tcp`;
      const bindings = info.NetworkSettings?.Ports?.[portKey];
      if (bindings && bindings.length > 0) {
        const hostPort = parseInt(bindings[0].HostPort, 10);
        console.log(`[ContainerOrchestrator] ${containerName}:${internalPort} -> localhost:${hostPort}`);
        return { host: 'localhost', port: hostPort };
      }
    }

    // Try container IP (works on Linux, not macOS)
    const ip = info.NetworkSettings?.Networks?.[NETWORK_NAME]?.IPAddress;
    if (ip) {
      console.log(`[ContainerOrchestrator] ${containerName} -> ${ip}:${internalPort}`);
      return { host: ip, port: internalPort };
    }
  } catch (err) {
    console.warn(`[ContainerOrchestrator] Could not get endpoint for ${containerName}:`, err.message);
  }

  // Fallback to container name (works if caller is also in Docker network)
  return { host: containerName, port: internalPort };
}

/**
 * Build the runtime response object.
 * On macOS: uses localhost + published ports
 * On Linux: uses container IPs
 */
async function buildRuntimeResponse(vncName, terminalName, credentials) {
  const [vncEndpoint, sshEndpoint] = await Promise.all([
    getContainerEndpoint(vncName, VNC_PORT),
    getContainerEndpoint(terminalName, SSH_PORT),
  ]);

  return {
    vnc: {
      host: vncEndpoint.host,
      port: vncEndpoint.port,
      password: credentials?.vnc?.password || 'bakku-the-wizard',
    },
    ssh: {
      host: sshEndpoint.host,
      port: sshEndpoint.port,
      username: credentials?.ssh?.username || 'candidate',
      password: credentials?.ssh?.password || 'password',
    },
  };
}

/**
 * Create a VNC desktop container.
 * Each session gets a unique hostname to avoid Docker DNS conflicts.
 * On macOS, publishes port to localhost for host access.
 */
async function createVncContainer(name, shortId, password) {
  console.log(`[ContainerOrchestrator] Creating VNC container: ${name} (publish_ports=${PUBLISH_PORTS})`);

  const hostConfig = {
    NetworkMode: NETWORK_NAME,
    Memory: 1024 * 1024 * 1024, // 1GB
    NanoCpus: 1000000000, // 1 CPU
    AutoRemove: false,
    // Share kube-config volume so VNC desktop can access kubectl
    Binds: ['kube-config:/home/candidate/.kube:ro'],
  };

  // On macOS, publish VNC port to a random localhost port for host access
  if (PUBLISH_PORTS) {
    hostConfig.PortBindings = {
      '6901/tcp': [{ HostIp: '127.0.0.1', HostPort: '' }], // Empty = auto-assign
    };
  }

  const container = await docker.createContainer({
    Image: VNC_IMAGE,
    name,
    Hostname: name,
    Env: [
      `VNC_PW=${password}`,
      `VNC_PASSWORD=${password}`,
      'VNC_VIEW_ONLY=false',
      'VNC_RESOLUTION=1280x800',
    ],
    ExposedPorts: {
      '5901/tcp': {},
      '6901/tcp': {},
    },
    HostConfig: hostConfig,
    Labels: {
      'ckx.managed': 'true',
      'ckx.type': 'vnc',
      'ckx.session': shortId,
    },
  });

  return container;
}

/**
 * Create a terminal (SSH) container.
 * On macOS, publishes SSH port to localhost for host access.
 */
async function createTerminalContainer(name, shortId) {
  console.log(`[ContainerOrchestrator] Creating terminal container: ${name} (publish_ports=${PUBLISH_PORTS})`);

  const hostConfig = {
    NetworkMode: NETWORK_NAME,
    Memory: 512 * 1024 * 1024, // 512MB
    NanoCpus: 500000000, // 0.5 CPU
    AutoRemove: false,
  };

  // On macOS, publish SSH port to a random localhost port for host access
  if (PUBLISH_PORTS) {
    hostConfig.PortBindings = {
      '22/tcp': [{ HostIp: '127.0.0.1', HostPort: '' }], // Empty = auto-assign
    };
  }

  const container = await docker.createContainer({
    Image: TERMINAL_IMAGE,
    name,
    Hostname: name,
    ExposedPorts: {
      '22/tcp': {},
    },
    HostConfig: hostConfig,
    Labels: {
      'ckx.managed': 'true',
      'ckx.type': 'terminal',
      'ckx.session': shortId,
    },
  });

  return container;
}

/**
 * Wait for a container to be running.
 * Uses container.inspect() directly — listContainers has timing/caching
 * issues on Docker Desktop macOS that cause false "not found" results.
 */
async function waitForContainerReady(container, name, timeoutMs) {
  const deadline = Date.now() + timeoutMs;

  while (Date.now() < deadline) {
    try {
      const info = await container.inspect();
      if (info.State.Running) {
        return true;
      }
      if (info.State.Status === 'exited' || info.State.Status === 'dead') {
        throw new Error(`Container ${name} exited with code ${info.State.ExitCode}`);
      }
    } catch (err) {
      if (err.message.includes('exited with code')) throw err;
      // Container not ready yet, keep polling
    }
    await sleep(READINESS_POLL_INTERVAL_MS);
  }

  throw new Error(`Container ${name} did not become ready within ${timeoutMs}ms`);
}

/**
 * Find a container by exact name.
 * Docker listContainers name filter is prefix-based, so we verify exact match.
 */
async function findContainer(name) {
  try {
    const containers = await docker.listContainers({
      all: true,
      filters: { name: [name] },
    });
    // Docker name filter is a prefix match; verify exact name
    return containers.find(c => c.Names.includes(`/${name}`)) || null;
  } catch (err) {
    return null;
  }
}

/**
 * Cleanup containers for a session. Idempotent.
 * @param {string} sessionId - Session identifier (UUID)
 */
async function cleanupSessionContainers(sessionId) {
  const shortId = sessionId.slice(0, 12);
  const vncName = containerName(sessionId, 'vnc');
  const terminalName = containerName(sessionId, 'terminal');

  console.log(`[ContainerOrchestrator] Cleaning up containers for session ${shortId}`);

  // Run both removals in parallel
  await Promise.allSettled([
    removeContainer(vncName),
    removeContainer(terminalName),
  ]);

  console.log(`[ContainerOrchestrator] Cleanup complete for session ${shortId}`);
}

/**
 * Remove a container by name (stop + remove). Idempotent.
 */
async function removeContainer(name) {
  try {
    const containerInfo = await findContainer(name);
    if (!containerInfo) return;

    const container = docker.getContainer(containerInfo.Id);

    if (containerInfo.State === 'running') {
      console.log(`[ContainerOrchestrator] Stopping container ${name}`);
      try {
        await container.stop({ t: 5 });
      } catch (stopErr) {
        // Container may have stopped between check and stop call
        if (!stopErr.message.includes('is not running')) {
          console.warn(`[ContainerOrchestrator] Stop warning for ${name}:`, stopErr.message);
        }
      }
    }

    console.log(`[ContainerOrchestrator] Removing container ${name}`);
    await container.remove({ force: true });
  } catch (err) {
    console.error(`[ContainerOrchestrator] Error removing container ${name}:`, err.message);
  }
}

/**
 * List all CKX-managed containers
 */
async function listManagedContainers() {
  try {
    const containers = await docker.listContainers({
      all: true,
      filters: { label: ['ckx.managed=true'] },
    });
    return containers.map(c => ({
      id: c.Id.slice(0, 12),
      name: c.Names[0].replace('/', ''),
      state: c.State,
      type: c.Labels['ckx.type'],
      session: c.Labels['ckx.session'],
      created: new Date(c.Created * 1000),
    }));
  } catch (err) {
    console.error('[ContainerOrchestrator] Error listing containers:', err.message);
    return [];
  }
}

/**
 * Cleanup orphaned containers — containers whose session short-ID
 * is not in the set of active session IDs.
 * Called periodically from the session cleanup routine.
 */
async function cleanupOrphanedContainers(activeSessionIds) {
  try {
    const managed = await listManagedContainers();
    const activeSet = new Set(activeSessionIds.map(id => id.slice(0, 12)));

    const orphaned = managed.filter(c => !activeSet.has(c.session));
    if (orphaned.length === 0) return 0;

    console.log(`[ContainerOrchestrator] Found ${orphaned.length} orphaned containers`);

    await Promise.allSettled(
      orphaned.map(c => removeContainer(c.name))
    );

    return orphaned.length;
  } catch (err) {
    console.error('[ContainerOrchestrator] Error cleaning orphaned containers:', err.message);
    return 0;
  }
}

/**
 * Get container status for a session
 */
async function getSessionContainerStatus(sessionId) {
  const vncName = containerName(sessionId, 'vnc');
  const terminalName = containerName(sessionId, 'terminal');

  const [vncInfo, terminalInfo] = await Promise.all([
    findContainer(vncName),
    findContainer(terminalName),
  ]);

  return {
    vnc: vncInfo ? { state: vncInfo.State, name: vncName } : null,
    terminal: terminalInfo ? { state: terminalInfo.State, name: terminalName } : null,
    healthy: vncInfo?.State === 'running' && terminalInfo?.State === 'running',
  };
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

module.exports = {
  checkDockerAvailable,
  provisionSessionContainers,
  cleanupSessionContainers,
  listManagedContainers,
  cleanupOrphanedContainers,
  getSessionContainerStatus,
  NETWORK_NAME,
  VNC_PORT,
  SSH_PORT,
};
