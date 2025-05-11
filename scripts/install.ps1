# PowerShell script for installing CK-X Simulator
# Requires PowerShell 5.0 or higher

try {
    # Color definitions for output
    $Red = [System.Console]::ForegroundColor = "Red"
    $Green = [System.Console]::ForegroundColor = "Green"
    $Yellow = [System.Console]::ForegroundColor = "Yellow"
    $Blue = [System.Console]::ForegroundColor = "Blue"
    $Cyan = [System.Console]::ForegroundColor = "Cyan"
    $DefaultColor = [System.Console]::ResetColor()

    # Function to print colored text
    function Write-ColorOutput {
        param (
            [string]$Message,
            [string]$Color
        )
        
        if ($Color -eq "Red") {
            Write-Host $Message -ForegroundColor Red
        } elseif ($Color -eq "Green") {
            Write-Host $Message -ForegroundColor Green
        } elseif ($Color -eq "Yellow") {
            Write-Host $Message -ForegroundColor Yellow
        } elseif ($Color -eq "Blue") {
            Write-Host $Message -ForegroundColor Blue
        } elseif ($Color -eq "Cyan") {
            Write-Host $Message -ForegroundColor Cyan
        } else {
            Write-Host $Message
        }
    }

    # ASCII Art and Description
    function Print-Header {
        Write-ColorOutput "`n" "Blue"
        Write-ColorOutput "░█████╗░██╗░░██╗░░░░░░██╗░░██╗  ░██████╗██╗███╗░░░███╗██╗░░░██╗██╗░░░░░░█████╗░████████╗░█████╗░██████╗░" "Blue"
        Write-ColorOutput "██╔══██╗██║░██╔╝░░░░░░╚██╗██╔╝  ██╔════╝██║████╗░████║██║░░░██║██║░░░░░██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗" "Blue"
        Write-ColorOutput "██║░░╚═╝█████═╝░█████╗░╚███╔╝░  ╚█████╗░██║██╔████╔██║██║░░░██║██║░░░░░███████║░░░██║░░░██║░░██║██████╔╝" "Blue"
        Write-ColorOutput "██║░░██╗██╔═██╗░╚════╝░██╔██╗░  ░╚═══██╗██║██║╚██╔╝██║██║░░░██║██║░░░░░██╔══██║░░░██║░░░██║░░██║██╔══██╗" "Blue"
        Write-ColorOutput "╚█████╔╝██║░╚██╗░░░░░░██╔╝╚██╗  ██████╔╝██║██║░╚═╝░██║╚██████╔╝███████╗██║░░██║░░░██║░░░╚█████╔╝██║░░██║" "Blue"
        Write-ColorOutput "░╚════╝░╚═╝░░╚═╝░░░░░░╚═╝░░╚═╝  ╚═════╝░╚═╝╚═╝░░░░░╚═╝░╚═════╝░╚══════╝╚═╝░░╚═╝░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝" "Blue"
        Write-ColorOutput "`n" "Blue"
        Write-ColorOutput "==============================================================" "Cyan"
        Write-ColorOutput "CK-X Simulator: Kubernetes Certification Exam Simulator" "Cyan"
        Write-ColorOutput "Practice in a realistic environment for CKA, CKAD, and more" "Cyan"
        Write-ColorOutput "==============================================================" "Cyan"
        Write-ColorOutput " Facing any issues? Please report at: https://github.com/nishanb/CK-X/issues" "Cyan"
        Write-Host ""
    }

    # Function to check if running as administrator
    function Test-Administrator {
        $user = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal $user
        return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }

    # Function to check if a command exists
    function Test-Command {
        param($Command)
        return [bool](Get-Command -Name $Command -ErrorAction SilentlyContinue)
    }

    # Function to check if Docker is running
    function Test-DockerRunning {
        try {
            $dockerInfo = docker info 2>&1
            if ($LASTEXITCODE -eq 0) {
                return $true
            } else {
                return $false
            }
        } catch {
            return $false
        }
    }

    # Function to check system requirements
    function Check-Requirements {
        Write-ColorOutput "Checking System Requirements" "Blue"
        Write-ColorOutput "==============================================================" "Cyan"
        
        # Check if running as administrator
        if (-not (Test-Administrator)) {
            Write-ColorOutput "✗ This script must be run as Administrator" "Red"
            Write-ColorOutput "Please right-click PowerShell and select 'Run as Administrator'" "Yellow"
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return $false
        }
        Write-ColorOutput "✓ Running with Administrator privileges" "Green"
        
        # Check Docker Desktop
        if (-not (Test-Command docker)) {
            Write-ColorOutput "✗ Docker is not installed" "Red"
            Write-ColorOutput "Please install Docker Desktop first:" "Yellow"
            Write-ColorOutput "Visit https://docs.docker.com/desktop/windows/install/ for installation instructions." "Cyan"
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return $false
        }
        Write-ColorOutput "✓ Docker is installed" "Green"
        
        # Check if Docker is running
        if (-not (Test-DockerRunning)) {
            Write-ColorOutput "✗ Docker is not running" "Red"
            Write-ColorOutput "Please start Docker and try again:" "Yellow"
            Write-ColorOutput "1. Open Docker Desktop" "Cyan"
            Write-ColorOutput "2. Wait for Docker to start" "Cyan"
            Write-ColorOutput "3. Run this script again" "Cyan"
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return $false
        }
        Write-ColorOutput "" ""
        
        # Check Docker Compose (built into Docker Desktop for Windows)
        $composeTest = docker compose version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "✗ Docker Compose is not installed or not working properly" "Red"
            Write-ColorOutput "Please ensure Docker Desktop is properly installed with Docker Compose" "Yellow"
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return $false
        }
        Write-ColorOutput "✓ Docker Compose is installed" "Green"
        
        # Check curl or equivalent
        if (-not (Test-Command curl) -and -not (Test-Command Invoke-WebRequest)) {
            Write-ColorOutput "✗ Neither curl nor Invoke-WebRequest is available" "Red"
            Write-ColorOutput "Please ensure you have PowerShell 3.0 or higher" "Yellow"
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return $false
        }
        Write-ColorOutput "✓ Download capabilities are available" "Green"
        
        Write-ColorOutput "✓ All system requirements satisfied" "Green"
        Write-Host ""
        return $true
    }

    # Function to check if ports are available
    function Check-Ports {
        $port = 30080
        
        Write-ColorOutput "Checking Port Availability" "Blue"
        Write-ColorOutput "==============================================================" "Cyan"
        
        try {
            # Check if port is in use
            $portInUse = $false
            $connections = Get-NetTCPConnection -ErrorAction SilentlyContinue | Where-Object {$_.LocalPort -eq $port}
            
            if ($connections) {
                $portInUse = $true
            } else {
                # Try to create a TCP listener as a secondary check
                $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $port)
                try {
                    $listener.Start()
                    $listener.Stop()
                } catch {
                    $portInUse = $true
                }
            }
            
            if ($portInUse) {
                Write-ColorOutput "✗ Port $port is already in use" "Red"
                Write-ColorOutput "Please free this port and try again" "Yellow"
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                return $false
            }
            
            Write-ColorOutput "✓ Port $port is available" "Green"
            Write-Host ""
            return $true
        } catch {
            Write-ColorOutput "Warning: Could not reliably check port availability" "Yellow"
            Write-Host ""
            return $true
        }
    }

    # Function to wait for service health
    function Wait-ForService {
        param($Service)
        $maxAttempts = 30
        $attempt = 1
        
        while ($attempt -le $maxAttempts) {
            $health = docker compose ps $Service | Select-String "healthy"
            if ($health) {
                return $true
            }
            Start-Sleep -Seconds 2
            $attempt++
        }
        
        Write-ColorOutput "✗ Timeout waiting for $Service to be ready" "Red"
        return $false
    }

    # Function to open browser
    function Open-Browser {
        $url = "https://play.sailor.sh/"
        Write-ColorOutput "Opening Browser" "Blue"
        Write-ColorOutput "==============================================================" "Cyan"
        
        try {
            Start-Process $url
            Write-ColorOutput "✓ Browser opened successfully" "Green"
            return $true
        } catch {
            try {
                [System.Diagnostics.Process]::Start("cmd", "/c start $url")
                Write-ColorOutput "✓ Browser opened successfully" "Green"
                return $true
            } catch {
                Write-ColorOutput "Could not automatically open browser. Please visit:" "Yellow"
                Write-ColorOutput "https://play.sailor.sh/" "Green"
                return $false
            }
        }
    }

    # Main installation function
    function Install-CKX {
        Print-Header
        
        # Check requirements
        $requirementsCheck = Check-Requirements
        if (-not $requirementsCheck) {
            Write-ColorOutput "Installation cannot proceed due to unmet requirements." "Red"
            return
        }
        
        # Check port
        $portsCheck = Check-Ports
        if (-not $portsCheck) {
            Write-ColorOutput "Installation cannot proceed due to port issues." "Red"
            return
        }
        
        # Create project directory
        Write-ColorOutput "Setting Up Installation" "Blue"
        Write-ColorOutput "==============================================================" "Cyan"
        Write-ColorOutput "Creating project directory..." "Yellow"
        
        $installDir = "ck-x-simulator"
        if (-not (Test-Path $installDir)) {
            New-Item -ItemType Directory -Force -Path $installDir | Out-Null
        }
        Set-Location $installDir
        
        # Download docker-compose.yml
        Write-ColorOutput "Downloading Docker Compose file..." "Yellow"
        $composeUrl = "https://raw.githubusercontent.com/nishanb/ck-x/master/docker-compose.yaml"
        
        if (Test-Command curl) {
            curl.exe -fsSL $composeUrl -o docker-compose.yml
        } else {
            Invoke-WebRequest -Uri $composeUrl -OutFile docker-compose.yml
        }
        
        if (-not (Test-Path "docker-compose.yml")) {
            Write-ColorOutput "✗ Failed to download docker-compose.yml" "Red"
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return
        }
        Write-ColorOutput "✓ Docker Compose file downloaded" "Green"
        
        # Pull images
        Write-ColorOutput "Pulling Docker images..." "Yellow"
        docker compose pull
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "✗ Failed to pull Docker images" "Red"
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return
        }
        Write-ColorOutput "✓ Docker images pulled successfully" "Green"
        
        # Start services
        Write-ColorOutput "Starting CK-X services..." "Yellow"
        docker compose up -d
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "✗ Failed to start services" "Red"
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return
        }
        Write-ColorOutput "✓ Services started" "Green"
        
        # Wait for services
        Write-ColorOutput "Waiting for services to initialize..." "Yellow"
        $webappReady = Wait-ForService "webapp"
        if (-not $webappReady) { 
            Write-ColorOutput "Installation cannot proceed as webapp service is not ready." "Red" 
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return
        }
        
        $facilitatorReady = Wait-ForService "facilitator"
        if (-not $facilitatorReady) { 
            Write-ColorOutput "Installation cannot proceed as facilitator service is not ready." "Red" 
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return
        }
        
        Write-ColorOutput "✓ All services initialized successfully" "Green"
        
        Write-Host ""
        Write-ColorOutput "Installation Complete!" "Blue"
        Write-ColorOutput "==============================================================" "Cyan"
        Write-ColorOutput "✓ CK-X Simulator has been installed successfully" "Green"
        
        # Wait a bit for the service to be fully ready
        Start-Sleep -Seconds 5
        
        # Try to open browser
        Open-Browser
        
        Write-Host ""
        Write-ColorOutput "Useful Commands" "Blue"
        Write-ColorOutput "==============================================================" "Cyan"
        Write-ColorOutput "CK-X Simulator has been installed in: " -NoNewline
        Write-ColorOutput "$(Get-Location), run all below commands from this directory" "Green"
        Write-ColorOutput "To stop CK-X: " -NoNewline
        Write-ColorOutput "docker compose down --volumes --remove-orphans --rmi all" "Green"
        Write-ColorOutput "To Restart CK-X: " -NoNewline
        Write-ColorOutput "docker compose restart" "Green"
        Write-ColorOutput "To clean up all containers and images: " -NoNewline
        Write-ColorOutput "docker system prune -a" "Green"
        Write-ColorOutput "To remove only CK-X images: " -NoNewline
        Write-ColorOutput "docker compose down --rmi all" "Green"
        Write-ColorOutput "To access CK-X Simulator: " -NoNewline
        Write-ColorOutput "https://play.sailor.sh/" "Green"
        Write-Host ""
        Write-ColorOutput "Thank you for installing CK-X Simulator!" "Cyan"
    }

    # Check if running as Administrator
    if (-not (Test-Administrator)) {
        Write-Host "This script requires Administrator privileges. Please re-run as Administrator." -ForegroundColor Red
        Write-Host "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } else {
        # Run the installation
        try {
            Install-CKX
        } catch {
            Write-Host "An error occurred during installation: $_" -ForegroundColor Red
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        } 
    }
} catch {
    # Global error handler
    Write-Host "An unexpected error occurred: $_" -ForegroundColor Red
} finally {
    # Ensure the window stays open even if there's an error
    Write-Host "`n`nPress any key to exit..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} 