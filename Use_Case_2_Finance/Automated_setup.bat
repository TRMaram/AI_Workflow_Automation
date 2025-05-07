@echo off
echo ==========================================================
echo 🚀 Streamlit ^& n8n Automated Setup Script for Windows
echo ==========================================================

REM Check Python installation
echo 📋 Checking Python installation...
python --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ Python not found. Please install Python 3.9-3.11 from python.org
    exit /b 1
)

python --version
pip --version

REM Prompt for project details
set /p zip_file=📂 Enter the path to your zip file (e.g., Use_Case_2_Finance.zip): 
set /p project_folder=📂 Enter the name for your project folder: 
set /p streamlit_script=📄 Enter the name of your Streamlit script file (e.g., test2.py): 
set /p workflow_json=📄 Enter the path to your n8n workflow JSON file (or leave empty if none): 

REM Create and set up project
echo 📦 Setting up project folder...
mkdir "%project_folder%" 2>nul

if exist "%zip_file%" (
    echo 📂 Unzipping project files...
    powershell -command "Expand-Archive -Path '%zip_file%' -DestinationPath '%project_folder%' -Force"
) else (
    echo ⚠️ Zip file not found. Creating empty project folder.
)

cd "%project_folder%"
echo 📍 Working directory: %CD%

REM Create virtual environment
echo 🔧 Creating Python virtual environment...
python -m venv venv

REM Activate virtual environment
echo 🔌 Activating virtual environment...
call venv\Scripts\activate.bat

REM Create requirements.txt if it doesn't exist
if not exist "requirements.txt" (
    echo 📝 Creating requirements.txt...
    (
        echo streamlit>=1.24.0
        echo requests>=2.28.0
        echo pandas>=1.5.0
    ) > requirements.txt
    echo ✅ Created requirements.txt with basic dependencies
)

REM Install dependencies
echo 📦 Installing Python dependencies...
pip install -r requirements.txt

REM Create Streamlit webhook integration if it doesn't exist
if not exist "%streamlit_script%" (
    echo 📝 Creating Streamlit webhook integration script...
    (
        echo import streamlit as st
        echo import requests
        echo.
        echo # Page configuration
        echo st.set_page_config^(page_title="n8n Workflow Trigger", page_icon="🔄"^)
        echo.
        echo st.title^("n8n Workflow Trigger"^)
        echo st.write^("Click the button below to trigger your n8n workflow via webhook"^)
        echo.
        echo # Replace this with your actual n8n webhook URL
        echo N8N_WEBHOOK_URL = "http://localhost:5678/webhook/your-webhook-path"
        echo.
        echo # Function to trigger the webhook
        echo def trigger_n8n_webhook^(^):
        echo     try:
        echo         # Display a spinner while making the request
        echo         with st.spinner^("Triggering n8n workflow..."^):
        echo             response = requests.post^(N8N_WEBHOOK_URL^)
        echo         
        echo         # Check if the request was successful
        echo         if response.status_code in [200, 201]:
        echo             st.success^(f"Workflow triggered successfully! Status code: {response.status_code}"^)
        echo             
        echo             # Display the response from n8n if there is one
        echo             if response.text:
        echo                 with st.expander^("Response details"^):
        echo                     try:
        echo                         st.json^(response.json^(^)^)
        echo                     except:
        echo                         st.text^(response.text^)
        echo         else:
        echo             st.error^(f"Failed to trigger workflow. Status code: {response.status_code}"^)
        echo             st.error^(f"Response: {response.text}"^)
        echo     
        echo     except requests.exceptions.RequestException as e:
        echo         st.error^(f"Error connecting to n8n: {str^(e^)}"^)
        echo     except Exception as e:
        echo         st.error^(f"An unexpected error occurred: {str^(e^)}"^)
        echo.
        echo # Create a prominent button to trigger the webhook
        echo if st.button^("🚀 Trigger n8n Workflow", type="primary", use_container_width=True^):
        echo     trigger_n8n_webhook^(^)
        echo.
        echo # Add some helpful information
        echo with st.expander^("How to set up your n8n webhook"^):
        echo     st.markdown^("""
        echo     1. In n8n, add a **Webhook node** as a trigger for your workflow
        echo     2. Configure it as a webhook ^(rather than test webhook^)
        echo     3. Copy the webhook URL from n8n
        echo     4. Paste it in the \`N8N_WEBHOOK_URL\` variable in this code
        echo     5. Run this Streamlit app and click the button to trigger your workflow
        echo     """^)
        echo.
        echo # Display the current webhook URL ^(for debugging^)
        echo st.caption^(f"Current webhook URL: {N8N_WEBHOOK_URL}"^)
    ) > "%streamlit_script%"
    echo ✅ Created Streamlit script: %streamlit_script%
)

REM Check if Docker is installed for n8n setup
echo 📋 Checking for Docker installation...
docker --version >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo ✅ Docker is installed
    
    REM Prompt to start n8n in Docker
    set /p start_n8n=🐳 Do you want to start n8n using Docker? (y/n): 
    if /i "%start_n8n%"=="y" (
        echo 🐳 Creating Docker start script for n8n...
        echo ℹ️ n8n will be available at http://localhost:5678
        
        REM Create a batch file to run Docker
        (
            echo @echo off
            echo echo Starting n8n in Docker...
            echo docker run -it --rm -p 5678:5678 -v %USERPROFILE%\.n8n:/home/node/.n8n n8nio/n8n
        ) > start_n8n_docker.bat
        
        REM Instructions for importing workflow
        if not "%workflow_json%"=="" if exist "%workflow_json%" (
            echo 📋 n8n workflow found: %workflow_json%
            echo ℹ️ After n8n starts, import the workflow at http://localhost:5678
            echo ℹ️ Click the gear icon (top right) → 'Import Workflow'
            echo ℹ️ Select the file: %workflow_json%
        )
    )
) else (
    echo ⚠️ Docker not installed. Alternative n8n installation:
    echo ℹ️ 1. Install Node.js from https://nodejs.org/
    echo ℹ️ 2. Run: npm install n8n -g
    echo ℹ️ 3. Start n8n by running: n8n
)

REM Create a start script for convenience
(
    echo @echo off
    echo REM Script to start both Streamlit and n8n
    echo.
    echo REM Start n8n (if using Docker)
    echo if exist "start_n8n_docker.bat" (
    echo     echo Starting n8n in Docker...
    echo     start "n8n" call start_n8n_docker.bat
    echo     echo n8n will be available at http://localhost:5678
    echo     REM Give n8n time to start
    echo     timeout /t 5
    echo ) else (
    echo     echo Please start n8n manually before continuing
    echo     echo Run 'n8n' if installed via npm, or use Docker
    echo )
    echo.
    echo REM Activate virtual environment
    echo call venv\Scripts\activate.bat
    echo.
    echo REM Start Streamlit app
    echo echo Starting Streamlit app...
    echo streamlit run %streamlit_script%
) > start_apps.bat

echo ==========================================================
echo ✅ Setup complete!
echo ==========================================================
echo 📋 To start your applications:
echo    1. Run: start_apps.bat
echo    - Streamlit will be available at: http://localhost:8501
echo    - n8n will be available at: http://localhost:5678
echo.
echo ℹ️ Remember to update the N8N_WEBHOOK_URL in your Streamlit script
echo    with the actual webhook URL from your n8n workflow.
echo ==========================================================

REM Ask if they want to start the applications now
set /p start_now=🚀 Do you want to start the applications now? (y/n): 
if /i "%start_now%"=="y" (
    call start_apps.bat
) else (
    echo 👋 You can start the applications later by running: start_apps.bat
)
