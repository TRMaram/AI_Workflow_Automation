@echo off
setlocal enabledelayedexpansion

:: Streamlit & n8n Automated Setup Script for Windows
:: This batch script sets up Streamlit and n8n on Windows 10+ systems

:: Show header
echo ==========================================================
echo 🚀 Streamlit ^& n8n Automated Setup Script for Windows
echo 🔧 Running in current directory mode
echo 🔶 Using local n8n installation (npm) instead of Docker
echo ==========================================================

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo ✅ Running with administrator privileges.
) else (
    echo ⚠️ This script is not running with administrator privileges.
    echo ⚠️ Some operations may fail. Consider restarting as administrator.
    set /p continueAnyway="🔄 Continue anyway? (y/n): "
    if /i not "!continueAnyway!"=="y" exit /b
)

:: Check Python installation
echo 📋 Checking Python installation...
where python >nul 2>&1
if %errorLevel% == 0 (
    set pythonCommand=python
    goto :pythonFound
)

where python3 >nul 2>&1
if %errorLevel% == 0 (
    set pythonCommand=python3
    goto :pythonFound
)

where py >nul 2>&1
if %errorLevel% == 0 (
    set pythonCommand=py
    goto :pythonFound
)

:: Python not found
echo ❌ Python not found.
set /p installChoice="📥 Would you like to install Python now? (y/n): "
if /i "!installChoice!"=="y" (
    echo 📥 Opening Python download page...
    start https://www.python.org/downloads/
    echo ℹ️ Please install Python 3.9-3.11 and make sure to check 'Add Python to PATH'
    echo ℹ️ After installation, please restart this script.
    exit /b
) else (
    echo ❌ Python is required to continue. Exiting script.
    exit /b 1
)

:pythonFound
echo ✅ Python found: %pythonCommand%

:: Check Python version
for /f "tokens=2" %%i in ('%pythonCommand% --version 2^>^&1') do (
    set pythonVersion=%%i
)
echo ✅ Python %pythonVersion% found

:: Check if Python version is compatible (3.9-3.11 recommended for Streamlit)
for /f "tokens=1,2 delims=." %%a in ("!pythonVersion!") do (
    set pythonMajor=%%a
    set pythonMinor=%%b
)

if !pythonMajor! EQU 3 (
    if !pythonMinor! GEQ 9 (
        if !pythonMinor! LEQ 11 (
            echo ✅ Python !pythonVersion! is compatible with Streamlit.
            goto :pythonVersionOk
        )
    )
)

echo ⚠️ Python !pythonVersion! may not be fully compatible with Streamlit.
echo ℹ️ Recommended version is Python 3.9-3.11.
set /p continueChoice="🔄 Continue anyway? (y/n): "
if /i not "!continueChoice!"=="y" exit /b

:pythonVersionOk

:: Check pip installation
where pip >nul 2>&1
if %errorLevel% == 0 (
    set pipCommand=pip
    echo ✅ pip is installed.
    goto :pipFound
)

where pip3 >nul 2>&1
if %errorLevel% == 0 (
    set pipCommand=pip3
    echo ✅ pip3 is installed.
    goto :pipFound
)

:: Try to install pip
echo ❌ pip is not installed.
echo 📥 Attempting to install pip...
%pythonCommand% -m ensurepip

where pip >nul 2>&1
if %errorLevel% == 0 (
    set pipCommand=pip
    echo ✅ pip installed successfully.
    goto :pipFound
)

where pip3 >nul 2>&1
if %errorLevel% == 0 (
    set pipCommand=pip3
    echo ✅ pip installed successfully.
    goto :pipFound
)

:: Try get-pip.py
echo ❌ Failed to install pip.
echo 📥 Downloading get-pip.py...
curl -o get-pip.py https://bootstrap.pypa.io/get-pip.py
%pythonCommand% get-pip.py

where pip >nul 2>&1
if %errorLevel% == 0 (
    set pipCommand=pip
    echo ✅ pip installed successfully.
    goto :pipFound
)

where pip3 >nul 2>&1
if %errorLevel% == 0 (
    set pipCommand=pip3
    echo ✅ pip installed successfully.
    goto :pipFound
)

echo ❌ Failed to install pip. Please install it manually.
exit /b 1

:pipFound

:: Use current directory as project folder
echo 📂 Using current directory as project folder
set projectFolder=.

set /p streamlitScript="📄 Enter the name of your Streamlit script file (e.g., app.py): "
if "!streamlitScript!"=="" (
    set streamlitScript=app.py
    echo ℹ️ Using default name: !streamlitScript!
)

set /p workflowJson="📄 Enter the path to your n8n workflow JSON file (or leave empty if none): "
if not "!workflowJson!"=="" (
    if not exist "!workflowJson!" (
        echo ⚠️ n8n workflow file not found at: !workflowJson!
        set /p continueChoice="🔄 Continue without workflow file? (y/n): "
        if /i not "!continueChoice!"=="y" exit /b
        set workflowJson=
    )
)

:: Working directory info
echo 📍 Working directory: %cd%

:: Check and create virtual environment
echo 🔧 Setting up Python virtual environment...

:: Check if venv module is available
%pythonCommand% -m venv --help >nul 2>&1
if %errorLevel% == 0 (
    set venvAvailable=1
) else (
    set venvAvailable=0
    echo ❌ Python venv module not available.
    echo 📥 Attempting to install virtualenv...
    %pipCommand% install virtualenv
    
    where virtualenv >nul 2>&1
    if %errorLevel% NEQ 0 (
        echo ❌ Failed to install virtualenv. Please install it manually.
        echo ℹ️ Run: pip install virtualenv
        exit /b 1
    )
)

:: Create virtual environment
echo 🔧 Creating Python virtual environment...
if exist venv (
    echo ⚠️ A virtual environment already exists.
    set /p recreateVenv="🔄 Recreate virtual environment? (y/n): "
    if /i "!recreateVenv!"=="y" (
        rmdir /s /q venv
        if !venvAvailable! EQU 1 (
            %pythonCommand% -m venv venv
        ) else (
            virtualenv venv
        )
        echo ✅ Virtual environment recreated.
    ) else (
        echo ✅ Using existing virtual environment.
    )
) else (
    if !venvAvailable! EQU 1 (
        %pythonCommand% -m venv venv
    ) else (
        virtualenv venv
    )
    
    if %errorLevel% NEQ 0 (
        echo ❌ Failed to create virtual environment.
        exit /b 1
    )
    echo ✅ Virtual environment created.
)

:: Activate virtual environment
echo 🔌 Activating virtual environment...
if exist venv\Scripts\activate.bat (
    call venv\Scripts\activate.bat
    echo ✅ Virtual environment activated.
) else (
    echo ❌ Failed to activate virtual environment.
    echo ℹ️ Try running: venv\Scripts\activate.bat
    exit /b 1
)

:: Create requirements.txt if it doesn't exist
if not exist requirements.txt (
    echo 📝 Creating requirements.txt...
    (
        echo streamlit^>=1.24.0
        echo requests^>=2.28.0
        echo pandas^>=1.5.0
    ) > requirements.txt
    echo ✅ Created requirements.txt with basic dependencies
) else (
    echo ✅ Using existing requirements.txt
    
    :: Check if streamlit is in requirements.txt
    findstr /i /c:"streamlit" requirements.txt >nul
    if %errorLevel% NEQ 0 (
        echo ⚠️ Streamlit not found in requirements.txt
        set /p addStreamlit="📥 Add streamlit to requirements.txt? (y/n): "
        if /i "!addStreamlit!"=="y" (
            echo streamlit^>=1.24.0>> requirements.txt
            echo ✅ Added streamlit to requirements.txt
        )
    )
)

:: Install dependencies
echo 📦 Installing Python dependencies...
%pipCommand% install -r requirements.txt

if %errorLevel% NEQ 0 (
    echo ❌ Failed to install dependencies.
    set /p continueChoice="🔄 Continue anyway? (y/n): "
    if /i not "!continueChoice!"=="y" exit /b
) else (
    echo ✅ Dependencies installed successfully.
    
    :: Verify streamlit installation
    where streamlit >nul 2>&1
    if %errorLevel% NEQ 0 (
        echo ❌ Streamlit installation not found in PATH.
        echo ⚠️ You might need to install it manually or restart your terminal.
        set /p installStreamlit="📥 Install streamlit directly? (y/n): "
        if /i "!installStreamlit!"=="y" (
            %pipCommand% install streamlit
            where streamlit >nul 2>&1
            if %errorLevel% EQU 0 (
                echo ✅ Streamlit installed successfully.
            ) else (
                echo ❌ Streamlit installation failed.
                exit /b 1
            )
        )
    ) else (
        echo ✅ Streamlit is available.
    )
)

:: Create Streamlit webhook integration if it doesn't exist
if not exist %streamlitScript% (
    echo 📝 Creating Streamlit webhook integration script...
    (
        echo import streamlit as st
        echo import requests
        echo import json
        echo import os
        echo.
        echo # Page configuration
        echo st.set_page_config(page_title="n8n Workflow Trigger", page_icon="🔄"^)
        echo.
        echo st.title("n8n Workflow Trigger"^)
        echo st.write("Click the button below to trigger your n8n workflow via webhook"^)
        echo.
        echo # Get webhook URL from environment variable or use default
        echo N8N_WEBHOOK_URL = os.environ.get("N8N_WEBHOOK_URL", "http://localhost:5678/webhook/your-webhook-path"^)
        echo.
        echo # Allow user to set the webhook URL in the UI
        echo with st.sidebar:
        echo     st.header("Configuration"^)
        echo     webhook_url = st.text_input("n8n Webhook URL", value=N8N_WEBHOOK_URL^)
        echo     
        echo     if st.button("Save webhook URL", key="save_url"^):
        echo         N8N_WEBHOOK_URL = webhook_url
        echo         st.success("Webhook URL updated!"^)
        echo.
        echo # Function to trigger the webhook
        echo def trigger_n8n_webhook(^):
        echo     try:
        echo         # Get any user input
        echo         with st.expander("Webhook Parameters (Optional^)", expanded=False^):
        echo             param_input = st.text_area("JSON Parameters:", 
        echo                                      value='{\\n  "example": "value"\\n}',
        echo                                      height=150,
        echo                                      help="Add parameters to send to n8n in JSON format"^)
        echo             
        echo             # Parse the JSON parameters
        echo             try:
        echo                 params = json.loads(param_input^)
        echo             except json.JSONDecodeError:
        echo                 st.warning("Invalid JSON. Using empty parameter set."^)
        echo                 params = {}
        echo         
        echo         # Display a spinner while making the request
        echo         with st.spinner("Triggering n8n workflow..."^):
        echo             response = requests.post(webhook_url, json=params^)
        echo         
        echo         # Check if the request was successful
        echo         if response.status_code in [200, 201]:
        echo             st.success(f"Workflow triggered successfully! Status code: {response.status_code}"^)
        echo             
        echo             # Display the response from n8n if there is one
        echo             if response.text:
        echo                 with st.expander("Response details"^):
        echo                     try:
        echo                         st.json(response.json(^)^)
        echo                     except:
        echo                         st.text(response.text^)
        echo         else:
        echo             st.error(f"Failed to trigger workflow. Status code: {response.status_code}"^)
        echo             st.error(f"Response: {response.text}"^)
        echo     
        echo     except requests.exceptions.RequestException as e:
        echo         st.error(f"Error connecting to n8n: {str(e^)}"^)
        echo         st.info("Make sure n8n is running and accessible."^)
        echo     except Exception as e:
        echo         st.error(f"An unexpected error occurred: {str(e^)}"^)
        echo.
        echo # Create a prominent button to trigger the webhook
        echo if st.button("🚀 Trigger n8n Workflow", type="primary", use_container_width=True^):
        echo     trigger_n8n_webhook(^)
        echo.
        echo # Add some helpful information
        echo with st.expander("How to set up your n8n webhook"^):
        echo     st.markdown("""
        echo     1. In n8n, add a **Webhook node** as a trigger for your workflow
        echo     2. Configure it as a webhook (rather than test webhook^)
        echo     3. Copy the webhook URL from n8n
        echo     4. Paste it in the **n8n Webhook URL** field in the sidebar
        echo     5. Click "Save webhook URL"
        echo     6. Click the "Trigger n8n Workflow" button to execute your workflow
        echo     """^)
        echo.
        echo # Connection status check
        echo with st.sidebar:
        echo     if st.button("Check n8n connection", key="check_connection"^):
        echo         try:
        echo             # Just check if the n8n server is reachable
        echo             base_url = webhook_url.split('/webhook/'^)[0]
        echo             response = requests.get(f"{base_url}/healthz", timeout=5^)
        echo             if response.status_code == 200:
        echo                 st.success(f"✅ n8n server is reachable!"^)
        echo             else:
        echo                 st.warning(f"⚠️ n8n server returned status code: {response.status_code}"^)
        echo         except requests.exceptions.RequestException as e:
        echo             st.error(f"❌ Cannot connect to n8n: {str(e^)}"^)
        echo             st.info("Make sure n8n is running at the correct URL."^)
        echo.
        echo # Display the current webhook URL
        echo st.caption(f"Current webhook URL: {webhook_url}"^)
    ) > %streamlitScript%
    echo ✅ Created Streamlit script: %streamlitScript%
) else (
    echo ✅ Using existing Streamlit script: %streamlitScript%
)

:: Check if Node.js is installed for n8n setup
echo 📋 Checking for Node.js installation...
where node >nul 2>&1
if %errorLevel% EQU 0 (
    echo ✅ Node.js is installed
    
    :: Check Node.js version
    for /f "tokens=*" %%i in ('node -v') do set nodeVersion=%%i
    echo ✅ Node.js version: !nodeVersion!
    
    :: Check if npm is installed
    where npm >nul 2>&1
    if %errorLevel% EQU 0 (
        echo ✅ npm is installed
        
        :: Check if n8n is already installed
        echo 📋 Checking if n8n is installed...
        where n8n >nul 2>&1
        if %errorLevel% EQU 0 (
            echo ✅ n8n is already installed
            for /f "tokens=*" %%i in ('n8n --version') do set n8nVersion=%%i
            echo ✅ n8n version: !n8nVersion!
        ) else (
            echo ❌ n8n is not installed
            set /p installN8n="📥 Would you like to install n8n globally? (y/n): "
            if /i "!installN8n!"=="y" (
                echo 📥 Installing n8n globally via npm...
                
                net session >nul 2>&1
                if %errorLevel% EQU 0 (
                    npm install n8n -g
                ) else (
                    echo ⚠️ Not running as administrator. You may need to run as admin for global npm installs.
                    set /p installAnyway="📥 Try to install anyway? (y/n): "
                    if /i "!installAnyway!"=="y" (
                        npm install n8n -g
                    ) else (
                        echo ❌ n8n installation cancelled.
                        exit /b 1
                    )
                )
                
                where n8n >nul 2>&1
                if %errorLevel% EQU 0 (
                    for /f "tokens=*" %%i in ('n8n --version') do set n8nVersion=%%i
                    echo ✅ n8n installed successfully! Version: !n8nVersion!
                ) else (
                    echo ❌ n8n installation failed.
                    echo ℹ️ You may need higher permissions to install global packages.
                    echo ℹ️ Try running this script as administrator.
                    exit /b 1
                )
            ) else (
                echo ❌ n8n is required for this setup.
                exit /b 1
            )
        )
    ) else (
        echo ❌ npm is not installed.
        echo ℹ️ Your Node.js installation may be incomplete or corrupted.
        exit /b 1
    )
) else (
    echo ❌ Node.js is not installed.
    set /p installNode="📥 Install Node.js now? (y/n): "
    if /i "!installNode!"=="y" (
        echo 📥 Opening Node.js download page...
        start https://nodejs.org/en/download/
        echo ℹ️ Please install Node.js LTS version and make sure to check 'Add to PATH'
        echo ℹ️ After installation, please restart this script.
        exit /b
    ) else (
        echo ❌ Node.js is required for n8n. Exiting script.
        exit /b 1
    )
)

:: Create n8n startup script
echo 📝 Creating n8n startup script...
(
    echo @echo off
    echo echo 🚀 Starting n8n...
    echo echo ℹ️ n8n will be available at http://localhost:5678
    echo n8n start
) > start_n8n.bat
echo ✅ Created n8n startup script.

:: Instructions for importing workflow
if not "!workflowJson!"=="" if exist "!workflowJson!" (
    echo 📋 n8n workflow found: !workflowJson!
    echo ℹ️ After n8n starts, import the workflow at http://localhost:5678
    echo ℹ️ Click the gear icon (top right^) ^> 'Import Workflow'
    echo ℹ️ Select the file: !workflowJson!
)

:: Create a comprehensive start script
echo 📝 Creating comprehensive start script...
(
    echo @echo off
    echo REM Script to start both Streamlit and n8n in the current project directory
    echo set ERRORLEVEL=0
    echo.
    echo echo ========================================================
    echo echo 🚀 Starting Streamlit and n8n
    echo echo ========================================================
    echo.
    echo REM Check if ports are in use
    echo netstat -ano | findstr :8501 >nul
    echo if %%ERRORLEVEL%% EQU 0 (
    echo     echo ⚠️ Port 8501 is already in use. Streamlit may not start correctly.
    echo     choice /C YN /M "🔄 Continue anyway?"
    echo     if %%ERRORLEVEL%% NEQ 1 goto :EOF
    echo ^)
    echo.
    echo netstat -ano | findstr :5678 >nul
    echo if %%ERRORLEVEL%% EQU 0 (
    echo     echo ⚠️ Port 5678 is already in use. n8n may not start correctly.
    echo     choice /C YN /M "🔄 Continue anyway?"
    echo     if %%ERRORLEVEL%% NEQ 1 goto :EOF
    echo ^)
    echo.
    echo REM Start n8n in a new window
    echo echo 🚀 Starting n8n...
    echo start "n8n" cmd /c "n8n start"
    echo echo ✅ n8n started in a new window
    echo echo ℹ️ n8n will be available at http://localhost:5678
    echo.
    echo REM Give n8n time to start
    echo echo ⏳ Waiting for n8n to initialize...
    echo timeout /t 10 /nobreak ^> nul
    echo.
    echo REM Activate virtual environment
    echo echo 🔌 Activating virtual environment...
    echo call venv\Scripts\activate.bat
    echo.
    echo REM Check if Streamlit is installed in the virtual environment
    echo where streamlit ^> nul 2^>^&1
    echo if %%ERRORLEVEL%% NEQ 0 (
    echo     echo ❌ Streamlit not found in the virtual environment.
    echo     echo 📥 Installing Streamlit...
    echo     pip install streamlit
    echo     if %%ERRORLEVEL%% NEQ 0 (
    echo         echo ❌ Failed to install Streamlit. Please install it manually.
    echo         exit /b 1
    echo     ^)
    echo ^)
    echo.
    echo REM Start Streamlit app
    echo echo 🚀 Starting Streamlit app...
    echo echo ℹ️ Streamlit will be available at: http://localhost:8501
    echo streamlit run %streamlitScript%
    echo.
    echo REM Note: This script doesn't properly handle stopping n8n when Streamlit is stopped
    echo REM If you want to stop n8n, you'll need to close its window manually
) > start_apps.bat

echo ======================================================== 
echo ✅ Setup complete!
echo ========================================================
echo 📋 To start your applications:
echo    1. Run: .\start_apps.bat from this directory
echo    - Streamlit will be available at: http://localhost:8501
echo    - n8n will be available at: http://localhost:5678
echo.
echo ℹ️ Remember to update the N8N_WEBHOOK_URL in your Streamlit app
echo    with the actual webhook URL from your n8n workflow.
echo ========================================================

:: Ask if they want to start the applications now
set /p startNow="🚀 Do you want to start the applications now? (y/n): "
if /i "!startNow!"=="y" (
    call .\start_apps.bat
) else (
    echo 👋 You can start the applications later by running: .\start_apps.bat
)

endlocal
