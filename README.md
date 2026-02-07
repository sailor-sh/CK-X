
![Master Kubernetes the Right Way (2)](https://github.com/user-attachments/assets/16edd8d8-5f96-4422-8659-3bb490b77204)

# CK-X Simulator 🚀

A powerful Kubernetes certification practice environment that provides a realistic exam-like experience for Kubernetes exam preparation.

## Major Features

- **Realistic exam environment** with web-based interface and remote desktop support
- Comprehensive practice labs for **CKAD, CKA, CKS**, and other Kubernetes certifications
- **Smart evaluation system** with real-time solution verification
- **Docker-based deployment** for easy setup and consistent environment
- **Timed exam mode** with real exam-like conditions and countdown timer 

## Demo

Watch live demo video showcasing the CK-X Simulator in action:

[![CK-X Simulator Demo](https://img.youtube.com/vi/EQVGhF8x7R4/0.jpg)](https://www.youtube.com/watch?v=EQVGhF8x7R4&ab_channel=NishanB)

---

## Prerequisites

Before installing CK-X, ensure you have:

- **Docker Desktop** (v20.10+) with at least **8GB RAM** allocated
- **Docker Compose** (v2.0+)
- For Windows: **WSL2** enabled in Docker Desktop settings

### System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| RAM | 8 GB | 16 GB |
| CPU | 4 cores | 8 cores |
| Disk | 20 GB | 50 GB |

---

## Quick Installation

### Linux & macOS

```bash
curl -fsSL https://raw.githubusercontent.com/nishanb/ck-x/master/scripts/install.sh | bash
```

### Windows (PowerShell as Administrator)

```powershell
irm https://raw.githubusercontent.com/nishanb/ck-x/master/scripts/install.ps1 | iex
```

After installation, open your browser and navigate to: **http://localhost:30080**

---

## Manual Installation with Docker Compose

### 1. Clone the Repository

```bash
git clone https://github.com/nishanb/ck-x.git
cd ck-x
```

### 2. Start All Services

```bash
docker compose up -d
```

This will start the following services:
- **nginx** - Reverse proxy (exposed on port 30080)
- **webapp** - CKX web application
- **facilitator** - Exam orchestration service
- **remote-desktop** - VNC-based remote desktop
- **remote-terminal** - SSH terminal service
- **jumphost** - Kubernetes cluster access point
- **kind-cluster** - Kubernetes cluster (K3D)
- **redis** - Session and cache storage

### 3. Verify Services are Running

```bash
docker compose ps
```

All services should show as "running" or "healthy".

### 4. Access the Application

Open your browser and go to: **http://localhost:30080**

### 5. Stop Services

```bash
docker compose down
```

To remove all data (including Kubernetes cluster state):

```bash
docker compose down -v
```

---

## Local Development Setup

For developing CKX components locally while using Docker for infrastructure services:

### 1. Start Infrastructure Services

```bash
docker compose up -d remote-desktop remote-terminal jumphost kind-cluster redis facilitator
```

### 2. Run the Web Application Locally

```bash
cd app
npm install
VNC_SERVICE_HOST=localhost npm run dev
```

The app will be available at: **http://localhost:3000**

### 3. Environment Variables for Local Development

| Variable | Description | Default |
|----------|-------------|---------|
| `VNC_SERVICE_HOST` | VNC server hostname | `remote-desktop` |
| `VNC_SERVICE_PORT` | VNC server port | `6901` |
| `VNC_PASSWORD` | VNC password | `bakku-the-wizard` |
| `SSH_HOST` | SSH server hostname | `remote-terminal` |
| `SSH_PORT` | SSH server port | `22` |
| `FACILITATOR_URL` | Facilitator service URL | `http://localhost:3004` |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Browser                               │
│                   http://localhost:30080                     │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                     Nginx (Reverse Proxy)                    │
│                        Port 30080                            │
└─────┬─────────────────────┬─────────────────────┬───────────┘
      │                     │                     │
┌─────▼─────┐    ┌─────────▼─────────┐    ┌─────▼─────┐
│  Webapp   │    │   Facilitator     │    │  Remote   │
│  (CKX UI) │    │ (Exam Orchestration)│   │  Desktop  │
│  Port 3000│    │     Port 3000      │    │ Port 6901 │
└───────────┘    └─────────┬──────────┘    └───────────┘
                           │
              ┌────────────▼────────────┐
              │       Jumphost          │
              │   (SSH to K8s cluster)  │
              └────────────┬────────────┘
                           │
              ┌────────────▼────────────┐
              │    Kind-Cluster (K3D)   │
              │   Kubernetes Cluster    │
              └─────────────────────────┘
```

---

## Troubleshooting

### Services fail to start

```bash
# Check service logs
docker compose logs -f <service-name>

# Restart all services
docker compose restart
```

### VNC connection fails

1. Ensure the remote-desktop container is running:
   ```bash
   docker compose up -d remote-desktop
   ```

2. For local development, use `VNC_SERVICE_HOST=localhost`:
   ```bash
   VNC_SERVICE_HOST=localhost npm run dev
   ```

### Exam preparation fails (stuck at PREPARATION_FAILED)

1. Check facilitator logs:
   ```bash
   docker compose logs -f facilitator
   ```

2. Clear the failed exam from Redis:
   ```bash
   docker exec ck-x-redis-1 redis-cli DEL current_exam_id
   ```

3. Restart and try again:
   ```bash
   docker compose restart facilitator jumphost
   ```

### Port conflicts

If ports 30080, 3000, or 6901 are already in use:

```bash
# Find and kill processes using the port
lsof -ti:30080 | xargs kill -9

# Or change ports in docker-compose.yaml
```

### Reset everything

```bash
# Stop all containers and remove volumes
docker compose down -v

# Remove all CKX images (optional)
docker images | grep ck-x | awk '{print $3}' | xargs docker rmi

# Start fresh
docker compose up -d
```

---

## Additional Documentation

- [Deployment Guide](scripts/COMPOSE-DEPLOY.md) - Detailed deployment instructions
- [Lab Creation Guide](docs/how-to-add-new-labs.md) - How to add new practice labs
- [Architecture Contract](docs/ARCHITECTURE-CONTRACT.md) - System architecture details
- [Local Setup Guide](docs/local-setup-guide.md) - Development environment setup

## Community & Support

- Join our [Discord Community](https://discord.gg/6FPQMXNgG9) for discussions and support
- Feature requests and pull requests are welcome

## Adding New Labs

Check our [Lab Creation Guide](docs/how-to-add-new-labs.md) for instructions on adding new labs.

## Contributing

We welcome contributions! Whether you want to:
- Add new practice labs
- Improve existing features
- Fix bugs
- Enhance documentation

## Buy Me a Coffee ☕

If you find CK-X Simulator helpful, consider [buying me a coffee](https://buymeacoffee.com/nishan.b) to support the project.

## Disclaimer

CK-X is an independent tool, not affiliated with CNCF, Linux Foundation, or PSI. We do not guarantee exam success. Please read our [Privacy Policy](docs/PRIVACY_POLICY.md) and [Terms of Service](docs/TERMS_OF_SERVICE.md) for more details about data collection, usage, and limitations.

## Acknowledgments

- [DIND](https://www.docker.com/)
- [K3D](https://k3d.io/stable/)
- [Node](https://nodejs.org/en)
- [Nginx](https://nginx.org/)
- [ConSol-Vnc](https://github.com/ConSol/docker-headless-vnc-container/)

## License

This project is licensed under the MIT License - see the LICENSE file for details. 
