
![Master Kubernetes the Right Way (2)](https://github.com/user-attachments/assets/16edd8d8-5f96-4422-8659-3bb490b77204)

# CK-X Simulator 🚀


A powerful Kubernetes certification practice environment that provides a realistic exam-like experience for kubernetess exam preparation.

## Major Features

- **Realistic exam environment** with web-based interface and remote desktop support
- Comprehensive practice labs for **CKAD, CKA, CKS**, and other Kubernetes certifications
- **Smart evaluation system** with real-time solution verification
- **Docker-based deployment** for easy setup and consistent environment
- **Timed exam mode** with real exam-like conditions and countdown timer 


## 

Watch live demo video showcasing the CK-X Simulator in action:

[![CK-X Simulator Demo](https://img.youtube.com/vi/EQVGhF8x7R4/0.jpg)](https://www.youtube.com/watch?v=EQVGhF8x7R4&ab_channel=NishanB)

## Installation

#### Linux & macOS
```bash
curl -fsSL https://raw.githubusercontent.com/nishanb/ck-x/master/scripts/install.sh | bash
```

#### Windows ( make sure WSL2 is enabled in the docker desktop )
```powershell
irm https://raw.githubusercontent.com/nishanb/ck-x/master/scripts/install.ps1 | iex
```

### Manual Installation
For detailed installation instructions, please refer to our [Deployment Guide](scripts/COMPOSE-DEPLOY.md).

Note on local builds: images in `docker-compose.yaml` use prebuilt tags. If you choose to build locally, ensure each Node.js service includes a `package-lock.json` and uses `npm ci --only=production` for deterministic builds.

## Community & Support

- Join our [Discord Community](https://discord.gg/6FPQMXNgG9) for discussions and support
- Feature requests and pull requests are welcome

## Adding New Labs

Check our [Lab Creation Guide](docs/how-to-add-new-labs.md) for instructions on adding new labs.

## Kubelingo Labs (Lab Generation)

If you want to generate and test custom labs without modifying CK-X, use the tools under `kubelingo/`:
- Quick usage: `kubelingo/USAGE.md`
- Detailed integration and E2E test plan: `kubelingo/INTEGRATION.md`
- Live Docker walk‑through (generate, install, run, cleanup): `kubelingo/TUTORIAL_LIVE_DOCKER.md`


## CKAD Exam 3 (ckad-003)

Run the simulator and take the single added exam (ckad-003):
- Use prebuilt, multi-arch images via the single `docker-compose.yaml`; it reads `.env` for image namespace/version/platform.
- Configure `.env` (copy `.env.example` → `.env`) to pin image namespace, version, and optional platform.
  - `CKX_IMAGE_NS` (default `je01`), `CKX_VERSION` (e.g., `exam3-v2`), optional `CKX_PLATFORM`.
- If you need independent service versions, set per-service overrides (full image:tag):
  - `REMOTE_DESKTOP_IMAGE`, `WEBAPP_IMAGE`, `NGINX_IMAGE`, `JUMPHOST_IMAGE`, `REMOTE_TERMINAL_IMAGE`, `CLUSTER_IMAGE`, `FACILITATOR_IMAGE`.
- Apple Silicon hosts should set `CKX_PLATFORM=linux/arm64`; x86_64 hosts may set `CKX_PLATFORM=linux/amd64` to avoid accidental cross-arch builds.
- Verify answers are present before starting: `bash scripts/check_answers.sh`.
- Start services with a single compose file:
  - `docker compose up -d`
- Open the UI: http://localhost:30080 → Start Exam → “CKAD Comprehensive Lab - 3”.

If you want to reset and pull images fresh before a run:
- `make reset-up`

Exam assets live under `facilitator/assets/exams/ckad/003/`.

Preferred commands (Makefile)
- `make up` — start all services
- `make down` — stop services
- `make pull` — pull images
- `make reset` — down + remove volumes, then pull fresh images
- `make check-answers` — verify all labs have an answers file
- `DOCKERHUB_NAMESPACE=<ns> VERSION=<tag> make release-exam3` — build/push multi-arch images for exam3


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
