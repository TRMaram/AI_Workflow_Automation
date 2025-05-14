# setup_environment.ps1
# Script to set up development environment with Python, pip, Node.js, npm, n8n and setup a virtual environment to run Streamlit app

# Set execution policy to allow script to run
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Project folder path (current directory by default)
$projectFolder = (Get-Location).Path
$venvName = "venv"
$venvPath = Join-Path $projectFolder $venvName
$streamlitAppName = "test2.py"
$streamlitAppPath = Join-Path $projectFolder $streamlitAppName

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
Write-Host "- Create Python virtual environment in project folder" -ForegroundColor Cyan
Write-Host "- Install Python packages from requirements.txt in virtual environment" -ForegroundColor Cyan
Write-Host "- Setup to run Streamlit app (test2.py)" -ForegroundColor Cyan
Write-Host "- Node.js (latest version)" -ForegroundColor Cyan
Write-Host "- npm (latest version)" -ForegroundColor Cyan
Write-Host "- n8n workflow automation tool" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check and install Python if needed
Write-Host "Checking Python installation..." -ForegroundColor Yellow

# Function to validate Python installation
function Test-PythonInstallation {
    try {
        # Try to execute Python and get version - this is more reliable than just checking if the command exists
        $pythonVersion = (python --version 2>&1)
        
        # If Python returns a version string that starts with "Python ", it's working correctly
        if ($pythonVersion -match "^Python \d+\.\d+\.\d+") {
            Write-Host "Python is installed and working: $pythonVersion" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Python command exists but may not be functioning properly" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "Python is not installed or not working correctly" -ForegroundColor Yellow
        return $false
    }
}

# More thorough check for Python functionality
$pythonWorking = Test-PythonInstallation

if (-not $pythonWorking) {
    Write-Host "Python not working correctly. Installing latest version..." -ForegroundColor Magenta
    
    # Download Python installer
    $pythonUrl = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
    $pythonInstaller = Join-Path $tempDir "python_installer.exe"
    
    try {
        # Create temp directory if it doesn't exist
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        
        Write-Host "Downloading Python installer from $pythonUrl" -ForegroundColor Cyan
        Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller
        
        # Check if the installer was downloaded correctly
        if (-not (Test-Path $pythonInstaller)) {
            Write-Host "Failed to download Python installer" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "Running Python installer..." -ForegroundColor Cyan
        # Install Python with pip and add to PATH with more aggressive options
        $installArgs = @(
            "/quiet", 
            "InstallAllUsers=1", 
            "PrependPath=1", 
            "Include_pip=1", 
            "Include_test=0",
            "AssociateFiles=1",
            "CompileAll=1"
        )
        
        # Run the installer with explicit process tracking
        $process = Start-Process -FilePath $pythonInstaller -ArgumentList $installArgs -PassThru -Wait
        
        if ($process.ExitCode -ne 0) {
            Write-Host "Python installer exited with code $($process.ExitCode)" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "Python installation completed. Updating PATH..." -ForegroundColor Cyan
        
        # Refresh PATH from both machine and user environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        
        # Explicitly add common Python installation locations to PATH
        $potentialPythonPaths = @(
            "C:\Python312",
            "C:\Python312\Scripts",
            "C:\Program Files\Python312",
            "C:\Program Files\Python312\Scripts",
            "C:\Program Files (x86)\Python312",
            "C:\Program Files (x86)\Python312\Scripts",
            "${env:LOCALAPPDATA}\Programs\Python\Python312",
            "${env:LOCALAPPDATA}\Programs\Python\Python312\Scripts"
        )
        
        foreach ($path in $potentialPythonPaths) {
            if (Test-Path $path) {
                $env:Path = "$path;$env:Path"
                Write-Host "Added $path to PATH" -ForegroundColor Cyan
            }
        }
        
        # Verify Python installation by checking version again
        $pythonWorking = Test-PythonInstallation
        
        if ($pythonWorking) {
            Write-Host "Python installed and verified successfully!" -ForegroundColor Green
        } else {
            Write-Host "Python installation completed but verification failed." -ForegroundColor Red
            Write-Host "You may need to restart your computer and run this script again." -ForegroundColor Yellow
            
            # Ask if user wants to continue anyway
            $continue = Read-Host "Do you want to continue with the script anyway? (Y/N)"
            if ($continue -ne "Y" -and $continue -ne "y") {
                exit 1
            }
        }
    }
    catch {
        Write-Host "Failed to install Python: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
else {
    $pythonVersion = python --version
    Write-Host "Python is installed and working: $pythonVersion" -ForegroundColor Green
}

# Step 2: Check and install pip if needed
Write-Host "Checking pip installation..." -ForegroundColor Yellow

# Function to validate pip installation
function Test-PipInstallation {
    try {
        # Try to execute pip and get version
        $pipOutput = (pip --version 2>&1)
        if ($pipOutput -match "pip \d+\.\d+") {
            Write-Host "pip is installed and working: $pipOutput" -ForegroundColor Green
            return $true
        } else {
            Write-Host "pip command exists but may not be functioning properly" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "pip is not installed or not working correctly" -ForegroundColor Yellow
        return $false
    }
}

$pipWorking = Test-PipInstallation

if (-not $pipWorking) {
    Write-Host "pip not working correctly. Installing..." -ForegroundColor Magenta
    
    # Try multiple methods to install pip
    try {
        # Method 1: Use ensurepip module
        Write-Host "Trying to install pip using ensurepip module..." -ForegroundColor Cyan
        python -m ensurepip --upgrade
        
        # Method 2: If that fails, download get-pip.py
        if (-not (Test-PipInstallation)) {
            Write-Host "Using alternative method to install pip..." -ForegroundColor Cyan
            $getPipUrl = "https://bootstrap.pypa.io/get-pip.py"
            $getPipScript = Join-Path $tempDir "get-pip.py"
            
            Invoke-WebRequest -Uri $getPipUrl -OutFile $getPipScript
            python $getPipScript --no-warn-script-location
            
            # Add pip Scripts location to PATH if it's not already there
            $pythonLocation = (python -c "import sys; print(sys.executable)") | Split-Path -Parent
            $pipScriptsLocation = Join-Path $pythonLocation "Scripts"
            
            if (Test-Path $pipScriptsLocation) {
                $env:Path = "$pipScriptsLocation;$env:Path"
                Write-Host "Added $pipScriptsLocation to PATH" -ForegroundColor Cyan
            }
        }
        
        # Verify pip installation
        $pipWorking = Test-PipInstallation
        
        if ($pipWorking) {
            Write-Host "pip installed and verified successfully!" -ForegroundColor Green
        } else {
            Write-Host "pip installation failed after multiple attempts" -ForegroundColor Red
            Write-Host "You may need to restart your computer and run this script again." -ForegroundColor Yellow
            
            # Ask if user wants to continue anyway
            $continue = Read-Host "Do you want to continue with the script anyway? (Y/N)"
            if ($continue -ne "Y" -and $continue -ne "y") {
                exit 1
            }
        }
    }
    catch {
        Write-Host "Failed to install pip: $($_.Exception.Message)" -ForegroundColor Red
        
        # Ask if user wants to continue anyway
        $continue = Read-Host "Do you want to continue with the script anyway? (Y/N)"
        if ($continue -ne "Y" -and $continue -ne "y") {
            exit 1
        }
    }
}
else {
    Write-Host "pip is already installed and working." -ForegroundColor Green
}

# Step 3: Create and setup virtual environment
Write-Host "Setting up Python virtual environment..." -ForegroundColor Yellow

# Create virtual environment using Python's built-in venv module
if (-not (Test-Path $venvPath)) {
    Write-Host "Creating virtual environment in $venvPath..." -ForegroundColor Magenta
    try {
        # Use Python's built-in venv module instead of virtualenv
        python -m venv $venvPath
        
        # Check if venv was created successfully
        if (Test-Path (Join-Path $venvPath "Scripts\python.exe")) {
            Write-Host "Virtual environment created successfully!" -ForegroundColor Green
        } else {
            Write-Host "Virtual environment creation may have failed. Python executable not found in expected location." -ForegroundColor Red
            
            # Fallback to virtualenv if venv fails
            Write-Host "Attempting fallback to virtualenv..." -ForegroundColor Yellow
            python -m pip install virtualenv --quiet
            python -m virtualenv $venvPath
            
            # Verify again
            if (Test-Path (Join-Path $venvPath "Scripts\python.exe")) {
                Write-Host "Virtual environment created successfully with virtualenv!" -ForegroundColor Green
            } else {
                Write-Host "Failed to create virtual environment with both methods." -ForegroundColor Red
                exit 1
            }
        }
    }
    catch {
        Write-Host "Failed to create virtual environment: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "Virtual environment already exists at $venvPath" -ForegroundColor Green
    
    # Verify that the existing venv is valid
    if (-not (Test-Path (Join-Path $venvPath "Scripts\python.exe"))) {
        Write-Host "Existing virtual environment appears to be invalid. Recreating..." -ForegroundColor Yellow
        Remove-Item -Path $venvPath -Recurse -Force
        python -m venv $venvPath
    }
}

# Determine the path to the activation script and Python executable in venv
$activateScript = Join-Path $venvPath "Scripts\Activate.ps1"
$venvPython = Join-Path $venvPath "Scripts\python.exe"
$venvPip = Join-Path $venvPath "Scripts\pip.exe"

# Check if the activation script exists
if (Test-Path $activateScript) {
    Write-Host "Activating virtual environment..." -ForegroundColor Magenta
    try {
        # Use direct paths to executables instead of relying on PATH modification
        # This is more reliable in script contexts
        Write-Host "Virtual environment ready to use!" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to activate virtual environment: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "Could not find virtual environment activation script at $activateScript" -ForegroundColor Red
    exit 1
}

# Step 4: Install packages from requirements.txt in the virtual environment
Write-Host "Looking for requirements.txt..." -ForegroundColor Yellow
if (Test-Path "requirements.txt") {
    Write-Host "Installing Python packages from requirements.txt into virtual environment..." -ForegroundColor Magenta
    try {
        # Use the pip executable directly from the virtual environment
        & $venvPip install -r requirements.txt
        
        # Verify streamlit is installed in the virtual environment
        $streamlitInstalled = & $venvPython -c "import pkgutil; print('streamlit' if pkgutil.find_loader('streamlit') else 'not_found')"
        if ($streamlitInstalled -eq "streamlit") {
            Write-Host "Streamlit is installed in the virtual environment!" -ForegroundColor Green
        } else {
            Write-Host "Warning: Streamlit doesn't appear to be installed. Make sure it's listed in requirements.txt" -ForegroundColor Yellow
            Write-Host "Attempting to install Streamlit..." -ForegroundColor Yellow
            & $venvPip install streamlit
        }
        
        Write-Host "Python packages installed successfully in virtual environment!" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install Python packages: $($_.Exception.Message)" -ForegroundColor Red
    }
}
else {
    Write-Host "requirements.txt not found in current directory." -ForegroundColor Yellow
    Write-Host "Installing basic packages including Streamlit..." -ForegroundColor Yellow
    & $venvPip install streamlit
    Write-Host "Basic packages installed." -ForegroundColor Green
}

# Step 4: Install Node.js and npm
Write-Host "Checking Node.js installation..." -ForegroundColor Yellow
if (-not (Test-CommandExists node)) {
    Write-Host "Node.js not found. Installing latest version..." -ForegroundColor Magenta
    
    # Download Node.js installer
    $nodeUrl = "https://nodejs.org/dist/latest/node-v20.11.1-x64.msi"
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

# Create a startup script for running the Streamlit app
$runStreamlitScript = Join-Path $projectFolder "run_streamlit_app.ps1"
$runStreamlitContent = @"
# Run Streamlit app script
# This script activates the virtual environment and runs the Streamlit app

# Path to the virtual environment and app
`$venvPath = "$venvPath"
`$streamlitAppPath = "$streamlitAppPath"

# Check if virtual environment exists
if (-not (Test-Path `$venvPath)) {
    Write-Host "Virtual environment not found at `$venvPath" -ForegroundColor Red
    Write-Host "Please run the setup script first." -ForegroundColor Red
    exit 1
}

# Activate virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Cyan
& "`$venvPath\Scripts\Activate.ps1"

# Check if activation was successful (looking for the virtual env prefix in prompt)
if (-not (`$env:VIRTUAL_ENV -eq `$venvPath)) {
    Write-Host "Virtual environment activation may have failed." -ForegroundColor Yellow
    # Try direct paths anyway
}

# Check if Streamlit app exists
if (-not (Test-Path `$streamlitAppPath)) {
    Write-Host "Streamlit app not found at `$streamlitAppPath" -ForegroundColor Red
    Write-Host "Please make sure the app file exists." -ForegroundColor Red
    exit 1
}

# Run Streamlit app
Write-Host "Starting Streamlit app: `$([System.IO.Path]::GetFileName(`$streamlitAppPath))..." -ForegroundColor Cyan
& "`$venvPath\Scripts\streamlit.exe" run "`$streamlitAppPath"

# If the direct path doesn't work, try using the activated environment
if (`$LASTEXITCODE -ne 0) {
    Write-Host "Trying alternative method to run Streamlit..." -ForegroundColor Yellow
    streamlit run "`$streamlitAppPath"
}
"@

# Write the startup script
Set-Content -Path $runStreamlitScript -Value $runStreamlitContent
Write-Host "Created Streamlit startup script: $runStreamlitScript" -ForegroundColor Green

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

# Virtual environment info
if (Test-Path $venvPath) {
    # Extra validation of virtual environment
    $venvPythonExists = Test-Path (Join-Path $venvPath "Scripts\python.exe")
    $venvPipExists = Test-Path (Join-Path $venvPath "Scripts\pip.exe")
    
    if ($venvPythonExists -and $venvPipExists) {
        Write-Host "Virtual Environment: Created and verified at $venvPath" -ForegroundColor Green
        
        # Test if streamlit is installed in the virtual environment
        $streamlitExe = Join-Path $venvPath "Scripts\streamlit.exe"
        if (Test-Path $streamlitExe) {
            Write-Host "Streamlit: Successfully installed in virtual environment" -ForegroundColor Green
        } else {
            Write-Host "Streamlit: Not found in virtual environment" -ForegroundColor Yellow
            Write-Host "  - You may need to add streamlit to your requirements.txt" -ForegroundColor Yellow
        }
        
        # Check if Streamlit app exists
        if (Test-Path $streamlitAppPath) {
            Write-Host "Streamlit App: Found at $streamlitAppPath" -ForegroundColor Green
            Write-Host ""
            Write-Host "To run your Streamlit app, open a new terminal and run: .\run_streamlit_app.ps1" -ForegroundColor Cyan
        }
        else {
            Write-Host "Streamlit App: $streamlitAppName not found in project directory" -ForegroundColor Yellow
            Write-Host "  - Create a file named $streamlitAppName with your Streamlit application code" -ForegroundColor Yellow
            Write-Host "  - Then run: .\run_streamlit_app.ps1" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Virtual Environment: Found at $venvPath but appears incomplete" -ForegroundColor Red
        Write-Host "  - Python executable exists: $venvPythonExists" -ForegroundColor Red
        Write-Host "  - Pip executable exists: $venvPipExists" -ForegroundColor Red
        Write-Host "  - Try deleting the venv folder and running this script again" -ForegroundColor Yellow
    }
}
else {
    Write-Host "Virtual Environment: Failed to create at $venvPath" -ForegroundColor Red
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Setup complete!" -ForegroundColor Cyan
