# Simple AI Workflow Automation Setup Script
# This script sets up the environment for AI Workflow Automation

# Set UTF-8 as the output encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Create a directory for the project
$projectDir = Join-Path $PSScriptRoot "finance_automation"
if (-not (Test-Path $projectDir)) {
    New-Item -ItemType Directory -Path $projectDir | Out-Null
    Write-Host "Created project directory: $projectDir"
} else {
    Write-Host "Project directory already exists: $projectDir"
}

# Check for Python
$pythonCommand = $null
$pythonCommands = @("python", "python3")

foreach ($cmd in $pythonCommands) {
    try {
        $pythonVersion = Invoke-Expression "$cmd --version" 2>&1
        if ($pythonVersion -match "Python 3") {
            $pythonCommand = $cmd
            Write-Host "Found Python: $pythonVersion"
            break
        }
    } catch {
        # Command not found, continue to next
    }
}

if ($pythonCommand -eq $null) {
    Write-Host "Python 3 not found. Please install Python 3 and try again."
    exit 1
}

# Create Python virtual environment
$venvPath = Join-Path $projectDir "venv"
if (-not (Test-Path $venvPath)) {
    Write-Host "Creating Python virtual environment..."
    & $pythonCommand -m venv $venvPath
    Write-Host "Created Python virtual environment"
} else {
    Write-Host "Python virtual environment already exists"
}

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
Write-Host "Created requirements.txt file"

# Create .env file
$envPath = Join-Path $projectDir ".env"
@"
# n8n Configuration
N8N_PORT=5678
N8N_WEBHOOK_URL=http://localhost:5678/webhook/

# Streamlit Configuration
STREAMLIT_PORT=8501
"@ | Out-File -FilePath $envPath -Encoding utf8
Write-Host "Created .env file"

# Create docker-compose.yml
$dockerComposePath = Join-Path $projectDir "docker-compose.yml"
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
Write-Host "Created docker-compose.yml file"

# Create Streamlit script
$streamlitScript = Join-Path $projectDir "app.py"
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
Write-Host "Created Streamlit application script"

Write-Host "`nSetup completed successfully!"
Write-Host "`nNext steps:"
Write-Host "1. Navigate to the project directory: cd $projectDir"
Write-Host "2. Activate the virtual environment: ./venv/Scripts/Activate.ps1"
Write-Host "3. Install Python packages: pip install -r requirements.txt"
Write-Host "4. Start n8n with Docker: docker-compose up"
Write-Host "5. Start Streamlit: streamlit run app.py"
