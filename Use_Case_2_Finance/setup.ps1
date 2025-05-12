# AI Workflow Automation Setup Script
# This script sets up the environment for AI Workflow Automation

# Set UTF-8 as the output encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Function to check if a command exists
function Test-CommandExists {
    param (
        [string]$Command
    )
    return [bool](Get-Command -Name $Command -ErrorAction SilentlyContinue)
}

# Function to install a required tool
function Install-RequiredTool {
    param (
        [string]$Tool,
        [string]$InstallCommand,
        [string]$CheckCommand
    )
    
    if (-not (Test-CommandExists $CheckCommand)) {
        Write-Host "Installing $Tool..." -ForegroundColor Yellow
        try {
            Invoke-Expression $InstallCommand
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ $Tool installed successfully" -ForegroundColor Green
            } else {
                Write-Host "❌ Error installing $Tool" -ForegroundColor Red
                return $false
            }
        } catch {
            Write-Host "❌ Error installing $Tool: $_" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "✅ $Tool is already installed" -ForegroundColor Green
    }
    return $true
}

# Create a directory for the project if it doesn't exist
$projectDir = Join-Path $PSScriptRoot "finance_automation"
if (-not (Test-Path $projectDir)) {
    New-Item -ItemType Directory -Path $projectDir | Out-Null
    Write-Host "✅ Created project directory: $projectDir" -ForegroundColor Green
} else {
    Write-Host "✅ Project directory already exists: $projectDir" -ForegroundColor Green
}

# Check for required tools
$requiredTools = @(
    @{
        Name = "Git"
        InstallCommand = 'winget install --id Git.Git -e --source winget'
        CheckCommand = "git"
    },
    @{
        Name = "Node.js"
        InstallCommand = 'winget install --id OpenJS.NodeJS -e --source winget'
        CheckCommand = "node"
    },
    @{
        Name = "Docker Desktop"
        InstallCommand = 'winget install --id Docker.DockerDesktop -e --source winget'
        CheckCommand = "docker"
    }
)

$allToolsInstalled = $true

foreach ($tool in $requiredTools) {
    if (-not (Test-CommandExists $tool.CheckCommand)) {
        Write-Host "$($tool.Name) is not installed." -ForegroundColor Yellow
        $installChoice = Read-Host "Do you want to install $($tool.Name)? (y/n)"
        
        if ($installChoice -eq "y" -or $installChoice -eq "Y") {
            $success = Install-RequiredTool -Tool $tool.Name -InstallCommand $tool.InstallCommand -CheckCommand $tool.CheckCommand
            if (-not $success) {
                $allToolsInstalled = $false
            }
        } else {
            Write-Host "⚠️ $($tool.Name) is required but will not be installed. Setup may fail." -ForegroundColor Red
            $allToolsInstalled = $false
        }
    } else {
        Write-Host "✅ $($tool.Name) is already installed" -ForegroundColor Green
    }
}

# Check for Python
$pythonCommand = $null
$pythonCommands = @("python", "python3")

foreach ($cmd in $pythonCommands) {
    if (Test-CommandExists $cmd) {
        $pythonVersion = & $cmd --version
        if ($pythonVersion -match "Python 3") {
            $pythonCommand = $cmd
            Write-Host "✅ Found Python: $pythonVersion" -ForegroundColor Green
            break
        }
    }
}

if ($pythonCommand) {
    # Install Python dependencies
    Write-Host "Setting up Python virtual environment..." -ForegroundColor Yellow
    
    # Create virtual environment
    $venvPath = Join-Path $projectDir "venv"
    if (-not (Test-Path $venvPath)) {
        & $pythonCommand -m venv $venvPath
        Write-Host "✅ Created Python virtual environment" -ForegroundColor Green
    } else {
        Write-Host "✅ Python virtual environment already exists" -ForegroundColor Green
    }
    
    # Activate virtual environment
    $activateScript = Join-Path $venvPath "Scripts\Activate.ps1"
    if (Test-Path $activateScript) {
        & $activateScript
        Write-Host "✅ Activated Python virtual environment" -ForegroundColor Green
        
        # Create requirements.txt file
        $requirementsPath = Join-Path $projectDir "requirements.txt"
        @"
streamlit==1.27.0
pandas==2.1.0
matplotlib==3.7.3
plotly==5.16.1
python-dotenv==1.0.0
requests==2.31.0
"@ | Out-File -FilePath $requirementsPath -Encoding utf8
        Write-Host "✅ Created requirements.txt file" -ForegroundColor Green
        
        # Install Python packages
        Write-Host "Installing Python packages..." -ForegroundColor Yellow
        & pip install -r $requirementsPath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Installed Python packages" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to install Python packages" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Failed to find virtual environment activation script" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Python 3 is not installed. Please install Python 3 and run this script again." -ForegroundColor Red
    $allToolsInstalled = $false
}

# Clone or update n8n repository
$n8nDir = Join-Path $projectDir "n8n"
if (-not (Test-Path $n8nDir)) {
    Write-Host "Cloning n8n repository..." -ForegroundColor Yellow
    git clone https://github.com/n8n-io/n8n.git $n8nDir
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Cloned n8n repository" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to clone n8n repository" -ForegroundColor Red
    }
} else {
    Write-Host "Updating n8n repository..." -ForegroundColor Yellow
    Push-Location $n8nDir
    git pull
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Updated n8n repository" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to update n8n repository" -ForegroundColor Red
    }
    Pop-Location
}

# Create .env file
$envPath = Join-Path $projectDir ".env"
if (-not (Test-Path $envPath)) {
    @"
# n8n Configuration
N8N_PORT=5678
N8N_WEBHOOK_URL=http://localhost:5678/webhook/

# Streamlit Configuration
STREAMLIT_PORT=8501
"@ | Out-File -FilePath $envPath -Encoding utf8
    Write-Host "✅ Created .env file" -ForegroundColor Green
} else {
    Write-Host "✅ .env file already exists" -ForegroundColor Green
}

# Create docker-compose.yml
$dockerComposePath = Join-Path $projectDir "docker-compose.yml"
if (-not (Test-Path $dockerComposePath)) {
    @"
version: '3'

services:
  n8n:
    image: n8nio/n8n
    ports:
      - "\${N8N_PORT}:5678"
    volumes:
      - n8n_data:/home/node/.n8n
    environment:
      - N8N_HOST=n8n
      - NODE_ENV=production
      - WEBHOOK_URL=http://localhost:\${N8N_PORT}/
    restart: always

volumes:
  n8n_data:
"@ | Out-File -FilePath $dockerComposePath -Encoding utf8
    Write-Host "✅ Created docker-compose.yml file" -ForegroundColor Green
} else {
    Write-Host "✅ docker-compose.yml file already exists" -ForegroundColor Green
}

# Create Streamlit script
$streamlitScript = Join-Path $projectDir "app.py"
if (-not (Test-Path $streamlitScript)) {
    @"
import streamlit as st
import pandas as pd
import requests
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()
N8N_WEBHOOK_URL = os.getenv('N8N_WEBHOOK_URL')

# Set page configuration
st.set_page_config(page_title="n8n Workflow Trigger", page_icon="📊")

def main():
    st.title("Finance Data Processing with n8n")
    st.write("Upload financial data to process through your n8n workflow")
    
    # Input for n8n webhook URL
    webhook_url = st.text_input("n8n Webhook URL", value=N8N_WEBHOOK_URL)
    
    # File uploader
    uploaded_file = st.file_uploader("Upload your financial data CSV", type=["csv"])
    
    if uploaded_file is not None:
        # Read and show the data
        df = pd.read_csv(uploaded_file)
        st.write("Preview of uploaded data:")
        st.dataframe(df.head())
        
        # Process button
        if st.button("Process Data"):
            with st.spinner("Processing data through n8n workflow..."):
                try:
                    # Convert DataFrame to JSON
                    data = df.to_dict(orient="records")
                    
                    # Send to n8n webhook
                    response = requests.post(
                        webhook_url, 
                        json={"data": data}
                    )
                    
                    if response.status_code == 200:
                        st.success("Data successfully processed!")
                        # Display the result from n8n if available
                        try:
                            result = response.json()
                            st.json(result)
                        except:
                            st.write("Process completed.")
                    else:
                        st.error(f"Error: {response.status_code}")
                        st.write(response.text)
                except Exception as e:
                    st.error(f"An error occurred: {e}")

if __name__ == "__main__":
    main()
"@ | Out-File -FilePath $streamlitScript -Encoding utf8
    Write-Host "✅ Created Streamlit application script" -ForegroundColor Green
} else {
    Write-Host "✅ Streamlit application script already exists" -ForegroundColor Green
}

# Create a startup script
$startupScript = Join-Path $projectDir "start.ps1"
if (-not (Test-Path $startupScript)) {
    @"
# Start the Finance Automation Environment

# Load .env file
`$envFile = Join-Path `$PSScriptRoot ".env"
Get-Content `$envFile | ForEach-Object {
    if (`$_ -match '(.+)=(.+)') {
        `$key = `$Matches[1]
        `$value = `$Matches[2]
        [Environment]::SetEnvironmentVariable(`$key, `$value, [EnvironmentVariableTarget]::Process)
    }
}

# Function to start a process in a new window
function Start-ProcessInNewWindow {
    param (
        [string] `$Command,
        [string] `$WorkingDirectory,
        [string] `$Title
    )
    
    Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "& {Set-Location '`$WorkingDirectory'; `$host.UI.RawUI.WindowTitle='`$Title'; `$Command}"
}

# Start Docker containers for n8n
Write-Host "Starting n8n..." -ForegroundColor Yellow
Start-ProcessInNewWindow -Command "docker-compose up" -WorkingDirectory `$PSScriptRoot -Title "n8n Docker"

# Wait for n8n to start
Write-Host "Waiting for n8n to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Activate Python virtual environment and start Streamlit
`$venvActivate = Join-Path `$PSScriptRoot "venv\Scripts\Activate.ps1"
`$streamlitPort = [Environment]::GetEnvironmentVariable("STREAMLIT_PORT")
Write-Host "Starting Streamlit on port `$streamlitPort..." -ForegroundColor Yellow

Start-ProcessInNewWindow -Command ". '`$venvActivate'; streamlit run app.py --server.port=`$streamlitPort" -WorkingDirectory `$PSScriptRoot -Title "Streamlit App"

# Open the browser
Start-Sleep -Seconds 3
Start-Process "http://localhost:`$streamlitPort"

Write-Host "✅ Environment started successfully!" -ForegroundColor Green
Write-Host "n8n is running at: http://localhost:`$env:N8N_PORT" -ForegroundColor Cyan
Write-Host "Streamlit is running at: http://localhost:`$streamlitPort" -ForegroundColor Cyan
"@ | Out-File -FilePath $startupScript -Encoding utf8
    Write-Host "✅ Created startup script" -ForegroundColor Green
} else {
    Write-Host "✅ Startup script already exists" -ForegroundColor Green
}

# Display completion message and next steps
if ($allToolsInstalled) {
    Write-Host "`n✅ Setup completed successfully!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Navigate to the project directory: cd $projectDir" -ForegroundColor White
    Write-Host "2. Run the startup script: ./start.ps1" -ForegroundColor White
    Write-Host "3. Configure your n8n workflows at http://localhost:5678/" -ForegroundColor White
    Write-Host "4. Use the Streamlit interface at http://localhost:8501/" -ForegroundColor White
} else {
    Write-Host "`n⚠️ Setup completed with warnings." -ForegroundColor Yellow
    Write-Host "Please install the missing dependencies and run the script again." -ForegroundColor Yellow
}
