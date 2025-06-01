
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

## Community & Support

- Join our [Discord Community](https://discord.gg/kbeggn9b) for discussions and support
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
