# Local Setup Guide for CK-X Simulator

## Quick Setup

1. Clone the repository:
```bash
git clone https://github.com/@nishanb/CK-X.git
cd ck-x
```

2. Start the services:
```bash
docker compose up -d
```

Then navigate to `http://localhost:30080` in your browser and select “CKAD Comprehensive Lab - 3”.

The script will deploy all services locally and open the application in your browser.

To force fresh images and a clean state between runs, use:
```bash
./scripts/reset_and_pull_exam3.sh
```

This setup has been tested on Mac and Linux environments. 
