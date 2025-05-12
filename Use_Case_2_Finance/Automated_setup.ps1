# PowerShell Script for Streamlit & n8n Setup on Windows
# This script sets up Streamlit and n8n on Windows 10+ systems
# Run this script with admin privileges for best results

# Show header
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "🚀 Streamlit & n8n Automated Setup Script for Windows" -ForegroundColor Cyan
Write-Host "🔧 Running in current directory mode" -ForegroundColor Cyan
Write-Host "🔶 Using local n8n installation (npm) instead of Docker" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Function to check if a command exists
function Test-CommandExists {
    param (
        [string]$Command
    )
    
    try {
        if (Get-Command $Command -ErrorAction Stop) {
            return $true
        }
    }
    catch {
        return $false
    }
    return $false
}

# Function to check if a port is in use
function Test-PortInUse {
    param (
        [int]$Port
    )
    
    $inUse = $false
    $connections = Get-NetTCPConnection -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -eq $Port }
    
    if ($connections) {
        $inUse = $true
    }
    
    return $inUse
}

# Function to prompt user and install if needed
function Check-AndInstall {
    param (
        [string]$Tool,
        [string]$InstallCmd,
        [string]$CheckCmd = $Tool
    )
    
    Write-Host "📋 Checking if $Tool is installed..." -ForegroundColor Yellow
    if (Test-CommandExists $CheckCmd) {
        Write-Host "✅ $Tool is already installed." -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "❌ $Tool is not installed." -ForegroundColor Red
        $installChoice = Read-Host "📥 Would you like to install $Tool now? (y/n)"
        if ($installChoice -eq "y" -or $installChoice -eq "Y") {
            Write-Host "📦 Installing $Tool..." -ForegroundColor Yellow
            try {
                Invoke-Expression $InstallCmd
                
                # Verify installation succeeded
                if (Test-CommandExists $CheckCmd) {
                    Write-Host "✅ $Tool was successfully installed." -ForegroundColor Green
                    return $true
                }
                else {
                    Write-Host "❌ $Tool installation failed. Please install manually and run this script again." -ForegroundColor Red
                    return $false
                }
            }
            catch {
                Write-Host "❌ Error installing $Tool: $_" -ForegroundColor Red
                return $false
            }
        }
        else {
            Write-Host "⚠️ $Tool is required to continue. Exiting script." -ForegroundColor Red
            return $false
        }
    }
}

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "⚠️ This script is not running with administrator privileges." -ForegroundColor Yellow
    Write-Host "⚠️ Some operations may fail. Consider restarting as administrator." -ForegroundColor Yellow
    $continueAnyway = Read-Host "🔄 Continue anyway? (y/n)"
    if ($continueAnyway -ne "y" -and $continueAnyway -ne "Y") {
        exit
    }
}

# Check Python installation
Write-Host "📋 Checking Python installation..." -ForegroundColor Yellow
$pythonCommand = $null

# Try possible Python commands
if (Test-CommandExists "python") {
    $pythonCommand = "python"
}
elseif (Test-CommandExists "python3") {
    $pythonCommand = "python3"
}
elseif (Test-CommandExists "py") {
    $pythonCommand = "py"
}

if ($pythonCommand) {
    Write-Host "✅ Python found: $pythonCommand" -ForegroundColor Green
    
    # Check Python version
    $pythonVersion = & $pythonCommand --version 2>&1
    if ($pythonVersion -is [string]) {
        $pythonVersion = $pythonVersion.Split(" ")[1]
    }
    else {
        $pythonVersion = $pythonVersion.ToString().Split(" ")[1]
    }
    
    Write-Host "✅ Python $pythonVersion found" -ForegroundColor Green
    
    # Check if Python version is compatible (3.9-3.11 recommended for Streamlit)
    $pythonMajor = [int]($pythonVersion.Split(".")[0])
    $pythonMinor = [int]($pythonVersion.Split(".")[1])
    
    if ($pythonMajor -eq 3 -and $pythonMinor -ge 9 -and $pythonMinor -le 11) {
        Write-Host "✅ Python $pythonVersion is compatible with Streamlit." -ForegroundColor Green
    }
    else {
        Write-Host "⚠️ Python $pythonVersion may not be fully compatible with Streamlit." -ForegroundColor Yellow
        Write-Host "ℹ️ Recommended version is Python 3.9-3.11." -ForegroundColor Yellow
        $continueChoice = Read-Host "🔄 Continue anyway? (y/n)"
        if ($continueChoice -ne "y" -and $continueChoice -ne "Y") {
            exit
        }
    }
}
else {
    Write-Host "❌ Python not found." -ForegroundColor Red
    $installChoice = Read-Host "📥 Would you like to install Python now? (y/n)"
    if ($installChoice -eq "y" -or $installChoice -eq "Y") {
        Write-Host "📥 Opening Python download page..." -ForegroundColor Yellow
        Start-Process "https://www.python.org/downloads/"
        Write-Host "ℹ️ Please install Python 3.9-3.11 and make sure to check 'Add Python to PATH'" -ForegroundColor Yellow
        Write-Host "ℹ️ After installation, please restart this script." -ForegroundColor Yellow
        exit
    }
    else {
        Write-Host "❌ Python is required to continue. Exiting script." -ForegroundColor Red
        exit
    }
}

# Check pip installation
$pipCommand = $null
if (Test-CommandExists "pip") {
    $pipCommand = "pip"
}
elseif (Test-CommandExists "pip3") {
    $pipCommand = "pip3"
}

if ($pipCommand) {
    Write-Host "✅ $pipCommand is installed." -ForegroundColor Green
}
else {
    Write-Host "❌ pip is not installed." -ForegroundColor Red
    Write-Host "📥 Attempting to install pip..." -ForegroundColor Yellow
    
    # Try to install pip
    & $pythonCommand -m ensurepip
    
    # Check if pip was installed
    if (Test-CommandExists "pip") {
        $pipCommand = "pip"
        Write-Host "✅ pip installed successfully." -ForegroundColor Green
    }
    elseif (Test-CommandExists "pip3") {
        $pipCommand = "pip3"
        Write-Host "✅ pip installed successfully." -ForegroundColor Green
    }
    else {
        Write-Host "❌ Failed to install pip." -ForegroundColor Red
        Write-Host "📥 Downloading get-pip.py..." -ForegroundColor Yellow
        
        Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile "get-pip.py"
        & $pythonCommand get-pip.py
        
        # Check if pip was installed
        if (Test-CommandExists "pip") {
            $pipCommand = "pip"
            Write-Host "✅ pip installed successfully." -ForegroundColor Green
        }
        elseif (Test-CommandExists "pip3") {
            $pipCommand = "pip3"
            Write-Host "✅ pip installed successfully." -ForegroundColor Green
        }
        else {
            Write-Host "❌ Failed to install pip. Please install it manually." -ForegroundColor Red
            exit
        }
    }
}

# Use current directory as project folder
Write-Host "📂 Using current directory as project folder" -ForegroundColor Yellow
$projectFolder = "."

$streamlitScript = Read-Host "📄 Enter the name of your Streamlit script file (e.g., app.py)"
if ([string]::IsNullOrEmpty($streamlitScript)) {
    $streamlitScript = "app.py"
    Write-Host "ℹ️ Using default name: $streamlitScript" -ForegroundColor Yellow
}

$workflowJson = Read-Host "📄 Enter the path to your n8n workflow JSON file (or leave empty if none)"
if (-not [string]::IsNullOrEmpty($workflowJson) -and -not (Test-Path $workflowJson)) {
    Write-Host "⚠️ n8n workflow file not found at: $workflowJson" -ForegroundColor Yellow
    $continueChoice = Read-Host "🔄 Continue without workflow file? (y/n)"
    if ($continueChoice -ne "y" -and $continueChoice -ne "Y") {
        exit
    }
    $workflowJson = ""
}

# Already in the project folder
Write-Host "📍 Working directory: $(Get-Location)" -ForegroundColor Yellow

# Check and create virtual environment
Write-Host "🔧 Setting up Python virtual environment..." -ForegroundColor Yellow

try {
    & $pythonCommand -m venv --help | Out-Null
    $venvAvailable = $true
}
catch {
    $venvAvailable = $false
}

if (-not $venvAvailable) {
    Write-Host "❌ Python venv module not available." -ForegroundColor Red
    Write-Host "📥 Attempting to install virtualenv..." -ForegroundColor Yellow
    & $pipCommand install virtualenv
    
    if (-not (Test-CommandExists "virtualenv")) {
        Write-Host "❌ Failed to install virtualenv. Please install it manually." -ForegroundColor Red
        Write-Host "ℹ️ Run: pip install virtualenv" -ForegroundColor Yellow
        exit
    }
}

# Create virtual environment
Write-Host "🔧 Creating Python virtual environment..." -ForegroundColor Yellow
if (Test-Path "venv") {
    Write-Host "⚠️ A virtual environment already exists." -ForegroundColor Yellow
    $recreateVenv = Read-Host "🔄 Recreate virtual environment? (y/n)"
    if ($recreateVenv -eq "y" -or $recreateVenv -eq "Y") {
        Remove-Item -Recurse -Force "venv"
        if ($venvAvailable) {
            & $pythonCommand -m venv venv
        }
        else {
            & virtualenv venv
        }
        Write-Host "✅ Virtual environment recreated." -ForegroundColor Green
    }
    else {
        Write-Host "✅ Using existing virtual environment." -ForegroundColor Green
    }
}
else {
    if ($venvAvailable) {
        & $pythonCommand -m venv venv
    }
    else {
        & virtualenv venv
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to create virtual environment." -ForegroundColor Red
        exit
    }
    Write-Host "✅ Virtual environment created." -ForegroundColor Green
}

# Activate virtual environment
Write-Host "🔌 Activating virtual environment..." -ForegroundColor Yellow
$activateScript = ".\venv\Scripts\Activate.ps1"
if (Test-Path $activateScript) {
    . $activateScript
    Write-Host "✅ Virtual environment activated." -ForegroundColor Green
}
else {
    Write-Host "❌ Failed to activate virtual environment." -ForegroundColor Red
    Write-Host "ℹ️ Try running: .\venv\Scripts\Activate.ps1" -ForegroundColor Yellow
    exit
}

# Create requirements.txt if it doesn't exist
if (-not (Test-Path "requirements.txt")) {
    Write-Host "📝 Creating requirements.txt..." -ForegroundColor Yellow
    @"
streamlit>=1.24.0
requests>=2.28.0
pandas>=1.5.0
"@ | Out-File -FilePath "requirements.txt" -Encoding utf8
    Write-Host "✅ Created requirements.txt with basic dependencies" -ForegroundColor Green
}
else {
    Write-Host "✅ Using existing requirements.txt" -ForegroundColor Green
    
    # Check if streamlit is in requirements.txt
    $requirementsContent = Get-Content "requirements.txt"
    if (-not ($requirementsContent -match "streamlit")) {
        Write-Host "⚠️ Streamlit not found in requirements.txt" -ForegroundColor Yellow
        $addStreamlit = Read-Host "📥 Add streamlit to requirements.txt? (y/n)"
        if ($addStreamlit -eq "y" -or $addStreamlit -eq "Y") {
            "streamlit>=1.24.0" | Out-File -FilePath "requirements.txt" -Append -Encoding utf8
            Write-Host "✅ Added streamlit to requirements.txt" -ForegroundColor Green
        }
    }
}

# Install dependencies
Write-Host "📦 Installing Python dependencies..." -ForegroundColor Yellow
& $pipCommand install -r requirements.txt

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install dependencies." -ForegroundColor Red
    $continueChoice = Read-Host "🔄 Continue anyway? (y/n)"
    if ($continueChoice -ne "y" -and $continueChoice -ne "Y") {
        exit
    }
}
else {
    Write-Host "✅ Dependencies installed successfully." -ForegroundColor Green
    
    # Verify streamlit installation
    if (-not (Test-CommandExists "streamlit")) {
        Write-Host "❌ Streamlit installation not found in PATH." -ForegroundColor Red
        Write-Host "⚠️ You might need to install it manually or restart your terminal." -ForegroundColor Yellow
        $installStreamlit = Read-Host "📥 Install streamlit directly? (y/n)"
        if ($installStreamlit -eq "y" -or $installStreamlit -eq "Y") {
            & $pipCommand install streamlit
            if (Test-CommandExists "streamlit") {
                Write-Host "✅ Streamlit installed successfully." -ForegroundColor Green
            }
            else {
                Write-Host "❌ Streamlit installation failed." -ForegroundColor Red
                exit
            }
        }
    }
    else {
        Write-Host "✅ Streamlit is available." -ForegroundColor Green
    }
}

# Create Streamlit webhook integration if it doesn't exist
if (-not (Test-Path $streamlitScript)) {
    Write-Host "📝 Creating Streamlit webhook integration script..." -ForegroundColor Yellow
    @"
import streamlit as st
import requests
import json
import os

# Page configuration
st.set_page_config(page_title="n8n Workflow Trigger", page_icon="🔄")

st.title("n8n Workflow Trigger")
st.write("Click the button below to trigger your n8n workflow via webhook")

# Get webhook URL from environment variable or use default
N8N_WEBHOOK_URL = os.environ.get("N8N_WEBHOOK_URL", "http://localhost:5678/webhook/your-webhook-path")

# Allow user to set the webhook URL in the UI
with st.sidebar:
    st.header("Configuration")
    webhook_url = st.text_input("n8n Webhook URL", value=N8N_WEBHOOK_URL)
    
    if st.button("Save webhook URL", key="save_url"):
        N8N_WEBHOOK_URL = webhook_url
        st.success("Webhook URL updated!")

# Function to trigger the webhook
def trigger_n8n_webhook():
    try:
        # Get any user input
        with st.expander("Webhook Parameters (Optional)", expanded=False):
            param_input = st.text_area("JSON Parameters:", 
                                     value='{\n  "example": "value"\n}',
                                     height=150,
                                     help="Add parameters to send to n8n in JSON format")
            
            # Parse the JSON parameters
            try:
                params = json.loads(param_input)
            except json.JSONDecodeError:
                st.warning("Invalid JSON. Using empty parameter set.")
                params = {}
        
        # Display a spinner while making the request
        with st.spinner("Triggering n8n workflow..."):
            response = requests.post(webhook_url, json=params)
        
        # Check if the request was successful
        if response.status_code in [200, 201]:
            st.success(f"Workflow triggered successfully! Status code: {response.status_code}")
            
            # Display the response from n8n if there is one
            if response.text:
                with st.expander("Response details"):
                    try:
                        st.json(response.json())
                    except:
                        st.text(response.text)
        else:
            st.error(f"Failed to trigger workflow. Status code: {response.status_code}")
            st.error(f"Response: {response.text}")
    
    except requests.exceptions.RequestException as e:
        st.error(f"Error connecting to n8n: {str(e)}")
        st.info("Make sure n8n is running and accessible.")
    except Exception as e:
        st.error(f"An unexpected error occurred: {str(e)}")

# Create a prominent button to trigger the webhook
if st.button("🚀 Trigger n8n Workflow", type="primary", use_container_width=True):
    trigger_n8n_webhook()

# Add some helpful information
with st.expander("How to set up your n8n webhook"):
    st.markdown("""
    1. In n8n, add a **Webhook node** as a trigger for your workflow
    2. Configure it as a webhook (rather than test webhook)
    3. Copy the webhook URL from n8n
    4. Paste it in the **n8n Webhook URL** field in the sidebar
    5. Click "Save webhook URL"
    6. Click the "Trigger n8n Workflow" button to execute your workflow
    """)

# Connection status check
with st.sidebar:
    if st.button("Check n8n connection", key="check_connection"):
        try:
            # Just check if the n8n server is reachable
            base_url = webhook_url.split('/webhook/')[0]
            response = requests.get(f"{base_url}/healthz", timeout=5)
            if response.status_code == 200:
                st.success(f"✅ n8n server is reachable!")
            else:
                st.warning(f"⚠️ n8n server returned status code: {response.status_code}")
        except requests.exceptions.RequestException as e:
            st.error(f"❌ Cannot connect to n8n: {str(e)}")
            st.info("Make sure n8n is running at the correct URL.")

# Display the current webhook URL
st.caption(f"Current webhook URL: {webhook_url}")
"@ | Out-File -FilePath $streamlitScript -Encoding utf8
    Write-Host "✅ Created Streamlit script: $streamlitScript" -ForegroundColor Green
}
else {
    Write-Host "✅ Using existing Streamlit script: $streamlitScript" -ForegroundColor Green
}

# Check if Node.js is installed for n8n setup
Write-Host "📋 Checking for Node.js installation..." -ForegroundColor Yellow
if (Test-CommandExists "node") {
    Write-Host "✅ Node.js is installed" -ForegroundColor Green
    
    # Check Node.js version
    $nodeVersion = & node -v
    Write-Host "✅ Node.js version: $nodeVersion" -ForegroundColor Green
    
    # Check if npm is installed
    if (Test-CommandExists "npm") {
        Write-Host "✅ npm is installed" -ForegroundColor Green
        
        # Check if n8n is already installed
        Write-Host "📋 Checking if n8n is installed..." -ForegroundColor Yellow
        if (Test-CommandExists "n8n") {
            Write-Host "✅ n8n is already installed" -ForegroundColor Green
            $n8nVersion = & n8n --version
            Write-Host "✅ n8n version: $n8nVersion" -ForegroundColor Green
        }
        else {
            Write-Host "❌ n8n is not installed" -ForegroundColor Red
            $installN8n = Read-Host "📥 Would you like to install n8n globally? (y/n)"
            if ($installN8n -eq "y" -or $installN8n -eq "Y") {
                Write-Host "📥 Installing n8n globally via npm..." -ForegroundColor Yellow
                
                if ($isAdmin) {
                    npm install n8n -g
                }
                else {
                    Write-Host "⚠️ Not running as administrator. You may need to run as admin for global npm installs." -ForegroundColor Yellow
                    $installAnyway = Read-Host "📥 Try to install anyway? (y/n)"
                    if ($installAnyway -eq "y" -or $installAnyway -eq "Y") {
                        npm install n8n -g
                    }
                    else {
                        Write-Host "❌ n8n installation cancelled." -ForegroundColor Red
                        exit
                    }
                }
                
                if (Test-CommandExists "n8n") {
                    $n8nVersion = & n8n --version
                    Write-Host "✅ n8n installed successfully! Version: $n8nVersion" -ForegroundColor Green
                }
                else {
                    Write-Host "❌ n8n installation failed." -ForegroundColor Red
                    Write-Host "ℹ️ You may need higher permissions to install global packages." -ForegroundColor Yellow
                    Write-Host "ℹ️ Try running this script as administrator." -ForegroundColor Yellow
                    exit
                }
            }
            else {
                Write-Host "❌ n8n is required for this setup." -ForegroundColor Red
                exit
            }
        }
    }
    else {
        Write-Host "❌ npm is not installed." -ForegroundColor Red
        Write-Host "ℹ️ Your Node.js installation may be incomplete or corrupted." -ForegroundColor Yellow
        exit
    }
}
else {
    Write-Host "❌ Node.js is not installed." -ForegroundColor Red
    $installNode = Read-Host "📥 Install Node.js now? (y/n)"
    if ($installNode -eq "y" -or $installNode -eq "Y") {
        Write-Host "📥 Opening Node.js download page..." -ForegroundColor Yellow
        Start-Process "https://nodejs.org/en/download/"
        Write-Host "ℹ️ Please install Node.js LTS version and make sure to check 'Add to PATH'" -ForegroundColor Yellow
        Write-Host "ℹ️ After installation, please restart this script." -ForegroundColor Yellow
        exit
    }
    else {
        Write-Host "❌ Node.js is required for n8n. Exiting script." -ForegroundColor Red
        exit
    }
}

# Create n8n startup script
Write-Host "📝 Creating n8n startup script..." -ForegroundColor Yellow
@"
@echo off
echo 🚀 Starting n8n...
echo ℹ️ n8n will be available at http://localhost:5678
n8n start
"@ | Out-File -FilePath "start_n8n.bat" -Encoding utf8
Write-Host "✅ Created n8n startup script." -ForegroundColor Green

# Instructions for importing workflow
if (-not [string]::IsNullOrEmpty($workflowJson) -and (Test-Path $workflowJson)) {
    Write-Host "📋 n8n workflow found: $workflowJson" -ForegroundColor Yellow
    Write-Host "ℹ️ After n8n starts, import the workflow at http://localhost:5678" -ForegroundColor Yellow
    Write-Host "ℹ️ Click the gear icon (top right) → 'Import Workflow'" -ForegroundColor Yellow
    Write-Host "ℹ️ Select the file: $workflowJson" -ForegroundColor Yellow
}

# Create a comprehensive start script
Write-Host "📝 Creating comprehensive start script..." -ForegroundColor Yellow
@"
@echo off
REM Script to start both Streamlit and n8n in the current project directory
set ERRORLEVEL=0

echo ========================================================
echo 🚀 Starting Streamlit and n8n
echo ========================================================

REM Check if ports are in use
powershell -Command "if (Test-NetConnection -ComputerName localhost -Port 8501 -InformationLevel Quiet) { exit 1 } else { exit 0 }"
if %ERRORLEVEL% NEQ 0 (
    echo ⚠️ Port 8501 is already in use. Streamlit may not start correctly.
    choice /C YN /M "🔄 Continue anyway?"
    if %ERRORLEVEL% NEQ 1 goto :EOF
)

powershell -Command "if (Test-NetConnection -ComputerName localhost -Port 5678 -InformationLevel Quiet) { exit 1 } else { exit 0 }"
if %ERRORLEVEL% NEQ 0 (
    echo ⚠️ Port 5678 is already in use. n8n may not start correctly.
    choice /C YN /M "🔄 Continue anyway?"
    if %ERRORLEVEL% NEQ 1 goto :EOF
)

REM Start n8n in a new window
echo 🚀 Starting n8n...
start "n8n" cmd /c "n8n start"
echo ✅ n8n started in a new window
echo ℹ️ n8n will be available at http://localhost:5678

REM Give n8n time to start
echo ⏳ Waiting for n8n to initialize...
timeout /t 10 /nobreak > nul

REM Activate virtual environment
echo 🔌 Activating virtual environment...
call venv\Scripts\activate

REM Check if Streamlit is installed in the virtual environment
where streamlit > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Streamlit not found in the virtual environment.
    echo 📥 Installing Streamlit...
    pip install streamlit
    if %ERRORLEVEL% NEQ 0 (
        echo ❌ Failed to install Streamlit. Please install it manually.
        exit /b 1
    )
)

REM Start Streamlit app
echo 🚀 Starting Streamlit app...
echo ℹ️ Streamlit will be available at: http://localhost:8501
streamlit run $streamlitScript

REM Note: This script doesn't properly handle stopping n8n when Streamlit is stopped
REM If you want to stop n8n, you'll need to close its window manually
"@ | Out-File -FilePath "start_apps.bat" -Encoding utf8

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "📋 To start your applications:" -ForegroundColor Yellow
Write-Host "   1. Run: .\start_apps.bat from this directory" -ForegroundColor Yellow
Write-Host "   - Streamlit will be available at: http://localhost:8501" -ForegroundColor Yellow
Write-Host "   - n8n will be available at: http://localhost:5678" -ForegroundColor Yellow
Write-Host ""
Write-Host "ℹ️ Remember to update the N8N_WEBHOOK_URL in your Streamlit app" -ForegroundColor Yellow
Write-Host "   with the actual webhook URL from your n8n workflow." -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan

# Ask if they want to start the applications now
$startNow = Read-Host "🚀 Do you want to start the applications now? (y/n)"
if ($startNow -eq "y" -or $startNow -eq "Y") {
    & .\start_apps.bat
}
else {
    Write-Host "👋 You can start the applications later by running: .\start_apps.bat" -ForegroundColor Green
}
