# setup_environment.ps1
# Script to set up development environment with Python, pip, Node.js, npm, and n8n

# Set execution policy to allow script to run
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Function to check if command exists
function Test-CommandExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    
    $exists = $null -ne (Get-Command -Name $Command -ErrorAction SilentlyContinue)
    return $exists
}

# Create a temporary directory for downloads
$tempDir = Join-Path $env:TEMP "installer_temp"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

Write-Host "========== Environment Setup Script ==========" -ForegroundColor Cyan
Write-Host "This script will install the following:" -ForegroundColor Cyan
Write-Host "- Python (latest version if not installed)" -ForegroundColor Cyan
Write-Host "- pip (if not installed)" -ForegroundColor Cyan
Write-Host "- Python packages from requirements.txt" -ForegroundColor Cyan
Write-Host "- Node.js (latest version)" -ForegroundColor Cyan
Write-Host "- npm (latest version)" -ForegroundColor Cyan
Write-Host "- n8n workflow automation tool" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check and install Python if needed
Write-Host "Checking Python installation..." -ForegroundColor Yellow
if (-not (Test-CommandExists python)) {
    Write-Host "Python not found. Installing latest version..." -ForegroundColor Magenta
    
    # Download Python installer
    $pythonUrl = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
    $pythonInstaller = Join-Path $tempDir "python_installer.exe"
    
    try {
        Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller
        
        # Install Python with pip and add to PATH
        Start-Process -FilePath $pythonInstaller -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1", "Include_pip=1" -Wait
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        Write-Host "Python installed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install Python: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
else {
    $pythonVersion = python --version
    Write-Host "Python is already installed: $pythonVersion" -ForegroundColor Green
}

# Step 2: Check and install pip if needed
Write-Host "Checking pip installation..." -ForegroundColor Yellow
if (-not (Test-CommandExists pip)) {
    Write-Host "pip not found. Installing..." -ForegroundColor Magenta
    
    # Download get-pip.py
    $getPipUrl = "https://bootstrap.pypa.io/get-pip.py"
    $getPipScript = Join-Path $tempDir "get-pip.py"
    
    try {
        Invoke-WebRequest -Uri $getPipUrl -OutFile $getPipScript
        python $getPipScript
        Write-Host "pip installed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install pip: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "pip is already installed." -ForegroundColor Green
}

# Step 3: Install packages from requirements.txt if it exists
Write-Host "Looking for requirements.txt..." -ForegroundColor Yellow
if (Test-Path "requirements.txt") {
    Write-Host "Installing Python packages from requirements.txt..." -ForegroundColor Magenta
    try {
        python -m pip install -r requirements.txt
        Write-Host "Python packages installed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install Python packages: $($_.Exception.Message)" -ForegroundColor Red
    }
}
else {
    Write-Host "requirements.txt not found in current directory." -ForegroundColor Yellow
    Write-Host "Skipping Python packages installation." -ForegroundColor Yellow
}

# Step 4: Install Node.js and npm
Write-Host "Checking Node.js installation..." -ForegroundColor Yellow
if (-not (Test-CommandExists node)) {
    Write-Host "Node.js not found. Installing latest version..." -ForegroundColor Magenta
    
    # Download Node.js installer
    $nodeUrl = "https://nodejs.org/dist/v20.12.2/node-v20.12.2-x64.msi"
    $nodeInstaller = Join-Path $tempDir "node_installer.msi"
    
    try {
        Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $nodeInstaller, "/quiet", "/norestart" -Wait
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        Write-Host "Node.js installed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install Node.js: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
else {
    $nodeVersion = node --version
    Write-Host "Node.js is already installed: $nodeVersion" -ForegroundColor Green
}

# Step 5: Check npm version and update if needed
Write-Host "Checking npm installation..." -ForegroundColor Yellow
if (Test-CommandExists npm) {
    $npmVersion = npm --version
    Write-Host "npm is installed: $npmVersion" -ForegroundColor Green
    
    # Update npm to latest
    Write-Host "Updating npm to latest version..." -ForegroundColor Magenta
    try {
        npm install -g npm@latest
        $newNpmVersion = npm --version
        Write-Host "npm updated to version: $newNpmVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to update npm: $($_.Exception.Message)" -ForegroundColor Red
    }
}
else {
    Write-Host "npm should have been installed with Node.js. Something went wrong." -ForegroundColor Red
}

# Step 6: Install n8n
Write-Host "Installing n8n..." -ForegroundColor Yellow
try {
    npm install -g n8n
    Write-Host "n8n installed successfully!" -ForegroundColor Green
    
    # Verify n8n installation
    if (Test-CommandExists n8n) {
        $n8nVersion = n8n --version
        Write-Host "n8n version: $n8nVersion" -ForegroundColor Green
    }
    else {
        Write-Host "n8n command not found. Installation may have failed." -ForegroundColor Red
    }
}
catch {
    Write-Host "Failed to install n8n: $($_.Exception.Message)" -ForegroundColor Red
}

# Clean up temporary files
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Installation summary:" -ForegroundColor Cyan

# Display final versions
if (Test-CommandExists python) {
    $pythonFinalVersion = python --version
    Write-Host "Python: $pythonFinalVersion" -ForegroundColor Green
}
else {
    Write-Host "Python: Not installed" -ForegroundColor Red
}

if (Test-CommandExists pip) {
    $pipFinalVersion = pip --version
    Write-Host "pip: Installed" -ForegroundColor Green
}
else {
    Write-Host "pip: Not installed" -ForegroundColor Red
}

if (Test-CommandExists node) {
    $nodeFinalVersion = node --version
    Write-Host "Node.js: $nodeFinalVersion" -ForegroundColor Green
}
else {
    Write-Host "Node.js: Not installed" -ForegroundColor Red
}

if (Test-CommandExists npm) {
    $npmFinalVersion = npm --version
    Write-Host "npm: $npmFinalVersion" -ForegroundColor Green
}
else {
    Write-Host "npm: Not installed" -ForegroundColor Red
}

if (Test-CommandExists n8n) {
    $n8nFinalVersion = n8n --version
    Write-Host "n8n: $n8nFinalVersion" -ForegroundColor Green
    Write-Host ""
    Write-Host "To start n8n, open a new terminal and run: n8n start" -ForegroundColor Cyan
}
else {
    Write-Host "n8n: Not installed" -ForegroundColor Red
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Setup complete!" -ForegroundColor Cyan
