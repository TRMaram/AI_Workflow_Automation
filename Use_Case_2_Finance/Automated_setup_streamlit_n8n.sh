#!/bin/bash

# Exit on error
set -e

echo "=========================================================="
echo "🚀 Streamlit & n8n Automated Setup Script"
echo "=========================================================="

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check Python installation
echo "📋 Checking Python installation..."
if command_exists python3; then
  python_cmd="python3"
elif command_exists python; then
  python_cmd="python"
else
  echo "❌ Python not found. Please install Python 3.9-3.11 from python.org"
  exit 1
fi

# Check Python version
python_version=$($python_cmd --version | cut -d ' ' -f 2)
echo "✅ Python $python_version found"

# Check pip installation
echo "📋 Checking pip installation..."
if command_exists pip3; then
  pip_cmd="pip3"
elif command_exists pip; then
  pip_cmd="pip"
else
  echo "❌ pip not found. Please ensure pip is installed and added to PATH"
  exit 1
fi

# Prompt for project details
read -p "📂 Enter the path to your zip file (e.g., Use_Case_2_Finance.zip): " zip_file
read -p "📂 Enter the name for your project folder: " project_folder
read -p "📄 Enter the name of your Streamlit script file (e.g., test2.py): " streamlit_script
read -p "📄 Enter the path to your n8n workflow JSON file (or leave empty if none): " workflow_json

# Create and set up project
echo "📦 Setting up project folder..."
mkdir -p "$project_folder"

if [ -f "$zip_file" ]; then
  echo "📂 Unzipping project files..."
  unzip -q "$zip_file" -d "$project_folder"
else
  echo "⚠️ Zip file not found. Creating empty project folder."
fi

cd "$project_folder"
echo "📍 Working directory: $(pwd)"

# Create virtual environment
echo "🔧 Creating Python virtual environment..."
$python_cmd -m venv venv

# Activate virtual environment
echo "🔌 Activating virtual environment..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  source venv/Scripts/activate
else
  source venv/bin/activate
fi

# Create requirements.txt if it doesn't exist
if [ ! -f "requirements.txt" ]; then
  echo "📝 Creating requirements.txt..."
  cat > requirements.txt << EOF
streamlit>=1.24.0
requests>=2.28.0
pandas>=1.5.0
EOF
  echo "✅ Created requirements.txt with basic dependencies"
fi

# Install dependencies
echo "📦 Installing Python dependencies..."
pip install -r requirements.txt

# Create Streamlit webhook integration if it doesn't exist
if [ ! -f "$streamlit_script" ]; then
  echo "📝 Creating Streamlit webhook integration script..."
  cat > "$streamlit_script" << EOF
import streamlit as st
import requests

# Page configuration
st.set_page_config(page_title="n8n Workflow Trigger", page_icon="🔄")

st.title("n8n Workflow Trigger")
st.write("Click the button below to trigger your n8n workflow via webhook")

# Replace this with your actual n8n webhook URL
N8N_WEBHOOK_URL = "http://localhost:5678/webhook/your-webhook-path"

# Function to trigger the webhook
def trigger_n8n_webhook():
    try:
        # Display a spinner while making the request
        with st.spinner("Triggering n8n workflow..."):
            response = requests.post(N8N_WEBHOOK_URL)
        
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
    4. Paste it in the \`N8N_WEBHOOK_URL\` variable in this code
    5. Run this Streamlit app and click the button to trigger your workflow
    """)

# Display the current webhook URL (for debugging)
st.caption(f"Current webhook URL: {N8N_WEBHOOK_URL}")
EOF
  echo "✅ Created Streamlit script: $streamlit_script"
fi

# Check if Docker is installed for n8n setup
echo "📋 Checking for Docker installation..."
if command_exists docker; then
  echo "✅ Docker is installed"
  
  # Prompt to start n8n in Docker
  read -p "🐳 Do you want to start n8n using Docker? (y/n): " start_n8n
  if [[ $start_n8n == "y" || $start_n8n == "Y" ]]; then
    echo "🐳 Starting n8n in Docker..."
    echo "📦 Running n8n container..."
    echo "ℹ️ n8n will be available at http://localhost:5678"
    
    # Create a temporary script to run Docker in background
    cat > start_n8n_docker.sh << EOF
#!/bin/bash
docker run -it --rm \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
EOF
    chmod +x start_n8n_docker.sh
    
    # Instructions for importing workflow
    if [ -n "$workflow_json" ] && [ -f "$workflow_json" ]; then
      echo "📋 n8n workflow found: $workflow_json"
      echo "ℹ️ After n8n starts, import the workflow at http://localhost:5678"
      echo "ℹ️ Click the gear icon (top right) → 'Import Workflow'"
      echo "ℹ️ Select the file: $workflow_json"
    fi
  fi
else
  echo "⚠️ Docker not installed. Alternative n8n installation:"
  echo "ℹ️ 1. Install Node.js from https://nodejs.org/"
  echo "ℹ️ 2. Run: npm install n8n -g"
  echo "ℹ️ 3. Start n8n by running: n8n"
fi

# Create a start script for convenience
cat > start_apps.sh << EOF
#!/bin/bash
# Script to start both Streamlit and n8n

# Start n8n (if using Docker)
if [ -f "start_n8n_docker.sh" ]; then
  echo "Starting n8n in Docker..."
  ./start_n8n_docker.sh &
  N8N_PID=\$!
  echo "n8n started with PID: \$N8N_PID"
  echo "n8n will be available at http://localhost:5678"
  # Give n8n time to start
  sleep 5
else
  echo "Please start n8n manually before continuing"
  echo "Run 'n8n' if installed via npm, or use Docker"
fi

# Activate virtual environment
if [[ "\$OSTYPE" == "msys" || "\$OSTYPE" == "win32" ]]; then
  source venv/Scripts/activate
else
  source venv/bin/activate
fi

# Start Streamlit app
echo "Starting Streamlit app..."
streamlit run $streamlit_script
EOF

chmod +x start_apps.sh

echo "=========================================================="
echo "✅ Setup complete!"
echo "=========================================================="
echo "📋 To start your applications:"
echo "   1. Run: ./start_apps.sh"
echo "   - Streamlit will be available at: http://localhost:8501"
echo "   - n8n will be available at: http://localhost:5678"
echo ""
echo "ℹ️ Remember to update the N8N_WEBHOOK_URL in your Streamlit script"
echo "   with the actual webhook URL from your n8n workflow."
echo "=========================================================="

# Ask if they want to start the applications now
read -p "🚀 Do you want to start the applications now? (y/n): " start_now
if [[ $start_now == "y" || $start_now == "Y" ]]; then
  ./start_apps.sh
else
  echo "👋 You can start the applications later by running: ./start_apps.sh"
fi
