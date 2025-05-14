#!/bin/bash

# Exit on error
set -e

echo "=========================================================="
echo "🚀 Streamlit & n8n Automated Setup Script"
echo "🔧 Running in current directory mode"
echo "🔶 Using local n8n installation (npm) instead of Docker"
echo "=========================================================="

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to prompt user and install if needed
check_and_install() {
  local tool=$1
  local install_cmd=$2
  local check_cmd=${3:-$tool}
  
  echo "📋 Checking if $tool is installed..."
  if command_exists "$check_cmd"; then
    echo "✅ $tool is already installed."
    return 0
  else
    echo "❌ $tool is not installed."
    read -p "📥 Would you like to install $tool now? (y/n): " install_choice
    if [[ $install_choice == "y" || $install_choice == "Y" ]]; then
      echo "📦 Installing $tool..."
      eval "$install_cmd"
      
      # Verify installation succeeded
      if command_exists "$check_cmd"; then
        echo "✅ $tool was successfully installed."
        return 0
      else
        echo "❌ $tool installation failed. Please install manually and run this script again."
        return 1
      fi
    else
      echo "⚠️ $tool is required to continue. Exiting script."
      return 1
    fi
  fi
}

# Check Python installation
if check_and_install "Python" "echo 'Please install Python 3.9-3.11 from python.org and run this script again.'; exit 1" "python3"; then
  if command_exists python3; then
    python_cmd="python3"
  else
    python_cmd="python"
  fi
  
  # Check Python version
  python_version=$($python_cmd --version | cut -d ' ' -f 2)
  echo "✅ Python $python_version found"
  
  # Check if Python version is compatible (3.9-3.11 recommended for Streamlit)
  python_major=$(echo $python_version | cut -d. -f1)
  python_minor=$(echo $python_version | cut -d. -f2)
  
  if [[ "$python_major" -eq 3 && "$python_minor" -ge 9 && "$python_minor" -le 11 ]]; then
    echo "✅ Python $python_version is compatible with Streamlit."
  else
    echo "⚠️ Python $python_version may not be fully compatible with Streamlit."
    echo "ℹ️ Recommended version is Python 3.9-3.11."
    read -p "🔄 Continue anyway? (y/n): " continue_choice
    if [[ $continue_choice != "y" && $continue_choice != "Y" ]]; then
      exit 1
    fi
  fi
else
  exit 1
fi

# Check pip installation
if check_and_install "pip" "$python_cmd -m ensurepip || curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && $python_cmd get-pip.py" "pip3"; then
  if command_exists pip3; then
    pip_cmd="pip3"
  elif command_exists pip; then
    pip_cmd="pip"
  fi
  echo "✅ $pip_cmd is installed."
else
  exit 1
fi

# Use current directory as project folder
echo "📂 Using current directory as project folder"
project_folder="."

read -p "📄 Enter the name of your Streamlit script file (e.g., app.py): " streamlit_script
if [[ -z "$streamlit_script" ]]; then
  streamlit_script="app.py"
  echo "ℹ️ Using default name: $streamlit_script"
fi

read -p "📄 Enter the path to your n8n workflow JSON file (or leave empty if none): " workflow_json
if [[ -n "$workflow_json" && ! -f "$workflow_json" ]]; then
  echo "⚠️ n8n workflow file not found at: $workflow_json"
  read -p "🔄 Continue without workflow file? (y/n): " continue_choice
  if [[ $continue_choice != "y" && $continue_choice != "Y" ]]; then
    exit 1
  fi
  workflow_json=""
fi

# Already in the project folder
echo "📍 Working directory: $(pwd)"

# Check and create virtual environment
echo "🔧 Setting up Python virtual environment..."
if ! $python_cmd -m venv --help &>/dev/null; then
  echo "❌ Python venv module not available."
  echo "📥 Attempting to install venv module..."
  
  # Different installation methods based on system
  if command_exists apt-get; then
    echo "🐧 Debian/Ubuntu system detected"
    sudo apt-get update
    # Try to install python3-venv
    if ! sudo apt-get install -y python3-venv; then
      echo "⚠️ Unable to install python3-venv via apt-get"
      # Alternative installation via pip
      echo "📥 Attempting installation via pip..."
      $pip_cmd install virtualenv
    fi
  elif command_exists yum; then
    echo "🐧 RHEL/CentOS/Fedora system detected"
    sudo yum install -y python3-devel python3-virtualenv
  elif command_exists dnf; then
    echo "🐧 Fedora system detected"
    sudo dnf install -y python3-devel python3-virtualenv
  elif command_exists brew; then
    echo "🍎 macOS system detected"
    brew install pyenv-virtualenv
  else
    echo "📥 Attempting installation via pip..."
    $pip_cmd install virtualenv
  fi
  
  # Check if installation succeeded
  if ! $python_cmd -m venv --help &>/dev/null && ! command_exists virtualenv; then
    echo "❌ Unable to install venv or virtualenv"
    echo "ℹ️ Manual installation required. Options:"
    echo "   - For Debian/Ubuntu: sudo apt-get install python3-venv"
    echo "   - For RHEL/CentOS: sudo yum install python3-devel"
    echo "   - For all systems with pip: pip install virtualenv"
    exit 1
  fi
fi

# Create virtual environment
echo "🔧 Creating Python virtual environment..."
if [[ -d "venv" ]]; then
  echo "⚠️ A virtual environment already exists."
  read -p "🔄 Recreate virtual environment? (y/n): " recreate_venv
  if [[ $recreate_venv == "y" || $recreate_venv == "Y" ]]; then
    rm -rf venv
    if $python_cmd -m venv --help &>/dev/null; then
      $python_cmd -m venv venv
    elif command_exists virtualenv; then
      virtualenv venv
    fi
    echo "✅ Virtual environment recreated."
  else
    echo "✅ Using existing virtual environment."
  fi
else
  if $python_cmd -m venv --help &>/dev/null; then
    $python_cmd -m venv venv
  elif command_exists virtualenv; then
    virtualenv venv
  fi
  
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to create virtual environment."
    exit 1
  fi
  echo "✅ Virtual environment created."
fi

# Activate virtual environment
echo "🔌 Activating virtual environment..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  source venv/Scripts/activate
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to activate virtual environment on Windows."
    exit 1
  fi
else
  source venv/bin/activate
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to activate virtual environment."
    exit 1
  fi
fi
echo "✅ Virtual environment activated."

# Create requirements.txt if it doesn't exist
if [ ! -f "requirements.txt" ]; then
  echo "📝 Creating requirements.txt..."
  cat > requirements.txt << EOF
streamlit>=1.24.0
requests>=2.28.0
pandas>=1.5.0
EOF
  echo "✅ Created requirements.txt with basic dependencies"
else
  echo "✅ Using existing requirements.txt"
  
  # Check if streamlit is in requirements.txt
  if ! grep -q "streamlit" requirements.txt; then
    echo "⚠️ Streamlit not found in requirements.txt"
    read -p "📥 Add streamlit to requirements.txt? (y/n): " add_streamlit
    if [[ $add_streamlit == "y" || $add_streamlit == "Y" ]]; then
      echo "streamlit>=1.24.0" >> requirements.txt
      echo "✅ Added streamlit to requirements.txt"
    fi
  fi
fi

# Install dependencies
echo "📦 Installing Python dependencies..."
$pip_cmd install -r requirements.txt
if [[ $? -ne 0 ]]; then
  echo "❌ Failed to install dependencies."
  read -p "🔄 Continue anyway? (y/n): " continue_choice
  if [[ $continue_choice != "y" && $continue_choice != "Y" ]]; then
    exit 1
  fi
else
  echo "✅ Dependencies installed successfully."
  
  # Verify streamlit installation
  if ! command_exists streamlit; then
    echo "❌ Streamlit installation not found in PATH."
    echo "⚠️ You might need to install it manually or restart your terminal."
    read -p "📥 Install streamlit directly? (y/n): " install_streamlit
    if [[ $install_streamlit == "y" || $install_streamlit == "Y" ]]; then
      $pip_cmd install streamlit
      if command_exists streamlit; then
        echo "✅ Streamlit installed successfully."
      else
        echo "❌ Streamlit installation failed."
        exit 1
      fi
    fi
  else
    echo "✅ Streamlit is available."
  fi
fi

# Create Streamlit webhook integration if it doesn't exist
if [ ! -f "$streamlit_script" ]; then
  echo "📝 Creating Streamlit webhook integration script..."
  cat > "$streamlit_script" << EOF
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
EOF
  echo "✅ Created Streamlit script: $streamlit_script"
else
  echo "✅ Using existing Streamlit script: $streamlit_script"
fi

# Check if Node.js is installed for n8n setup
echo "📋 Checking for Node.js installation..."
if command_exists node; then
  echo "✅ Node.js is installed"
  
  # Check Node.js version
  node_version=$(node -v)
  echo "✅ Node.js version: $node_version"
  
  # Check if npm is installed
  if command_exists npm; then
    echo "✅ npm is installed"
    
    # Check if n8n is already installed
    echo "📋 Checking if n8n is installed..."
    if command_exists n8n; then
      echo "✅ n8n is already installed"
      n8n_version=$(n8n --version)
      echo "✅ n8n version: $n8n_version"
    else
      echo "❌ n8n is not installed"
      read -p "📥 Would you like to install n8n globally? (y/n): " install_n8n
      if [[ $install_n8n == "y" || $install_n8n == "Y" ]]; then
        echo "📥 Installing n8n globally via npm..."
        if command_exists sudo; then
          sudo npm install n8n -g
        else
          npm install n8n -g
        fi
        
        if command_exists n8n; then
          n8n_version=$(n8n --version)
          echo "✅ n8n installed successfully! Version: $n8n_version"
        else
          echo "❌ n8n installation failed."
          echo "ℹ️ You may need higher permissions to install global packages."
          echo "ℹ️ Try running with sudo: sudo npm install n8n -g"
          exit 1
        fi
      else
        echo "❌ n8n is required for this setup."
        exit 1
      fi
    fi
  else
    echo "❌ npm is not installed."
    echo "ℹ️ Your Node.js installation may be incomplete or corrupted."
    exit 1
  fi
else
  echo "❌ Node.js is not installed."
  echo "📥 Node.js is required for n8n. Would you like to install it now?"
  read -p "📥 Install Node.js now? (y/n): " install_node
  if [[ $install_node == "y" || $install_node == "Y" ]]; then
    echo "📥 Installing Node.js..."
    
    # Detect OS and install Node.js
    if command_exists apt-get; then
      # Debian/Ubuntu
      echo "🐧 Detected Debian/Ubuntu system"
      
      # Try multiple methods to install Node.js
      install_node_success=false
      
      # Method 1: Official NodeSource repository
      if ! $install_node_success; then
        echo "📦 Attempting to install Node.js via NodeSource repository..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || true
        sudo apt-get install -y nodejs || true
        
        if command_exists node; then
          install_node_success=true
          echo "✅ Installed Node.js via NodeSource repository"
        fi
      fi
      
      # Method 2: Standard repository
      if ! $install_node_success; then
        echo "📦 Attempting to install Node.js from standard repository..."
        sudo apt-get update
        sudo apt-get install -y nodejs npm || true
        
        if command_exists node; then
          install_node_success=true
          echo "✅ Installed Node.js from standard repository"
        fi
      fi
      
      # Method 3: Direct download and install
      if ! $install_node_success; then
        echo "📦 Attempting to download and install Node.js directly..."
        NODE_MAJOR=20
        
        # Install dependencies
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg
        sudo mkdir -p /etc/apt/keyrings
        
        # Remove existing NodeSource key if exists
        sudo rm -f /etc/apt/keyrings/nodesource.gpg
        
        # Download and add NodeSource key
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
        
        # Create deb repository
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
        
        # Install Node.js
        sudo apt-get update
        sudo apt-get install -y nodejs || true
        
        if command_exists node; then
          install_node_success=true
          echo "✅ Installed Node.js via direct download method"
        fi
      fi
      
      # Fallback method: Use nvm (Node Version Manager)
      if ! $install_node_success; then
        echo "📦 Attempting to install Node.js via nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
        
        # Source nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        # Install latest LTS version
        nvm install --lts
        
        if command_exists node; then
          install_node_success=true
          echo "✅ Installed Node.js via nvm"
        fi
      fi
      
    elif command_exists yum; then
      # RHEL/CentOS/Fedora
      echo "🐧 Detected RHEL/CentOS/Fedora system"
      
      # Method 1: Official NodeSource repository
      curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
      sudo yum install -y nodejs
      
      # Alternative method if first fails
      if ! command_exists node; then
        sudo yum install -y epel-release
        sudo yum install -y nodejs npm
      fi
      
    elif command_exists brew; then
      # macOS
      echo "🍎 Detected macOS system"
      brew install node@20
      
    else
      echo "❌ Could not determine how to install Node.js on your system."
      echo "ℹ️ Please install Node.js manually from https://nodejs.org/"
      echo "ℹ️ Recommended methods:"
      echo "   - Download from https://nodejs.org/"
      echo "   - Use nvm (Node Version Manager): https://github.com/nvm-sh/nvm"
      exit 1
    fi
    
    # Final verification of Node.js installation
    if ! command_exists node; then
      echo "❌ Node.js installation failed through all methods."
      echo "ℹ️ Troubleshooting steps:"
      echo "   1. Check your internet connection"
      echo "   2. Ensure you have required system dependencies"
      echo "   3. Try manual installation from https://nodejs.org/"
      echo "   4. Use Node Version Manager (nvm): https://github.com/nvm-sh/nvm"
      exit 1
    fi
    
    # Check if Node.js was installed successfully
    if command_exists node; then
      echo "✅ Node.js installed successfully!"
      
      # Install n8n globally
      echo "📥 Installing n8n globally..."
      if command_exists sudo; then
        sudo npm install n8n -g
      else
        npm install n8n -g
      fi
      
      if command_exists n8n; then
        n8n_version=$(n8n --version)
        echo "✅ n8n installed successfully! Version: $n8n_version"
      else
        echo "❌ n8n installation failed."
        exit 1
      fi
    else
      echo "❌ Node.js installation failed."
      exit 1
    fi
  else
    echo "❌ Node.js is required for n8n. Exiting script."
    exit 1
  fi
fi

# Create n8n startup script
echo "📝 Creating n8n startup script..."
cat > start_n8n.sh << EOF
#!/bin/bash
echo "🚀 Starting n8n..."
echo "ℹ️ n8n will be available at http://localhost:5678"
n8n start
EOF
chmod +x start_n8n.sh
echo "✅ Created n8n startup script."

# Instructions for importing workflow
if [ -n "$workflow_json" ] && [ -f "$workflow_json" ]; then
  echo "📋 n8n workflow found: $workflow_json"
  echo "ℹ️ After n8n starts, import the workflow at http://localhost:5678"
  echo "ℹ️ Click the gear icon (top right) → 'Import Workflow'"
  echo "ℹ️ Select the file: $workflow_json"
fi

# Create a comprehensive start script
cat > start_apps.sh << EOF
#!/bin/bash
# Script to start both Streamlit and n8n in the current project directory

# Set error handling
set -e

# This script assumes it's run from the project directory

# Function to check if a port is in use
port_in_use() {
  local port=\$1
  if command -v netstat >/dev/null 2>&1; then
    netstat -tuln | grep -q ":\$port "
    return \$?
  elif command -v ss >/dev/null 2>&1; then
    ss -tuln | grep -q ":\$port "
    return \$?
  elif command -v lsof >/dev/null 2>&1; then
    lsof -i :\$port >/dev/null 2>&1
    return \$?
  else
    # Default to assuming port is free if we can't check
    return 1
  fi
}

# Check if Streamlit port is available
if port_in_use 8501; then
  echo "⚠️ Port 8501 is already in use. Streamlit may not start correctly."
  read -p "🔄 Continue anyway? (y/n): " continue_choice
  if [[ \$continue_choice != "y" && \$continue_choice != "Y" ]]; then
    exit 1
  fi
fi

# Check if n8n port is available
if port_in_use 5678; then
  echo "⚠️ Port 5678 is already in use. n8n may not start correctly."
  read -p "🔄 Continue anyway? (y/n): " continue_choice
  if [[ \$continue_choice != "y" && \$continue_choice != "Y" ]]; then
    exit 1
  fi
fi

# Start n8n
echo "🚀 Starting n8n..."
n8n start &
N8N_PID=\$!
echo "✅ n8n started with PID: \$N8N_PID"
echo "ℹ️ n8n will be available at http://localhost:5678"
# Give n8n time to start
echo "⏳ Waiting for n8n to initialize..."
sleep 10

# Activate virtual environment
echo "🔌 Activating virtual environment..."
if [[ "\$OSTYPE" == "msys" || "\$OSTYPE" == "win32" ]]; then
  source venv/Scripts/activate
else
  source venv/bin/activate
fi

# Check if Streamlit is installed in the virtual environment
if ! command -v streamlit >/dev/null 2>&1; then
  echo "❌ Streamlit not found in the virtual environment."
  echo "📥 Installing Streamlit..."
  if command_exists pip; then
    pip install streamlit
  else
    pip3 install streamlit
  fi
  if ! command -v streamlit >/dev/null 2>&1; then
    echo "❌ Failed to install Streamlit. Please install it manually."
    exit 1
  fi
fi

# Start Streamlit app
echo "🚀 Starting Streamlit app..."
echo "ℹ️ Streamlit will be available at: http://localhost:8501"
streamlit run $streamlit_script

# Note: This script doesn't properly handle stopping n8n when Streamlit is stopped
# If you want to stop n8n, you'll need to find its process and kill it manually
EOF

chmod +x start_apps.sh

echo "=========================================================="
echo "✅ Setup complete!"
echo "=========================================================="
echo "📋 To start your applications:"
echo "   1. Run: ./start_apps.sh from this directory"
echo "   - Streamlit will be available at: http://localhost:8501"
echo "   - n8n will be available at: http://localhost:5678"
echo ""
echo "ℹ️ Remember to update the N8N_WEBHOOK_URL in your Streamlit app"
echo "   with the actual webhook URL from your n8n workflow."
echo "=========================================================="

# Ask if they want to start the applications now
read -p "🚀 Do you want to start the applications now? (y/n): " start_now
if [[ $start_now == "y" || $start_now == "Y" ]]; then
  ./start_apps.sh
else
  echo "👋 You can start the applications later by running: ./start_apps.sh"
fi
