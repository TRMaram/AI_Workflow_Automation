# Import the necessary libraries at the top of your script
import streamlit as st
import io
import requests
import pandas as pd
import uuid
import json
import base64
from datetime import datetime, timedelta
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

# Set page configuration - MUST be the first Streamlit command
st.set_page_config(page_title="Project Management System", layout="wide")

# Initialize session state variables if they don't exist
if 'submission_attempted' not in st.session_state:
    st.session_state.submission_attempted = False
if 'submission_result' not in st.session_state:
    st.session_state.submission_result = None
if 'submission_error' not in st.session_state:
    st.session_state.submission_error = None
if "session_id" not in st.session_state:
    st.session_state.session_id = str(uuid.uuid4())
if "messages" not in st.session_state:
    st.session_state.messages = []

# App title
st.title("Project Management System")

# N8N webhook configuration
CONTRACTS_API_URL = "http://localhost:5678/webhook"  # Replace with your actual n8n API endpoint
API_TOKEN = "test_chat"  # Replace with your actual token

# Define headers for API requests
headers = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}

# Move cache decorator to a proper function definition
@st.cache_data(ttl=600)


# Function to send message to LLM via n8n
def send_message_to_llm(session_id, user_message):
    headers = {
        "Authorization": f"Bearer {API_TOKEN}",
        "Content-Type": "application/json"
    }

    payload = {
        "sessionId": session_id,
        "chatInput": user_message
    }

    try:
        response = requests.post("http://localhost:5678/webhook/invoke_agent", headers=headers, json=payload)
        response.raise_for_status()
        result = response.json()
        return result.get("output", "Sorry, I couldn't process your request.")
    except requests.exceptions.RequestException as e:
        return f"Error communicating with the AI service: {str(e)}"
# Sidebar navigation
st.sidebar.title("Navigation")
page = st.sidebar.radio("Go to", ["💬 Chat Interface"])

if page == "💬 Chat Interface":
    st.header("Chat with AI Assistant")

    # Display chat history
    for message in st.session_state.messages:
        with st.chat_message(message["role"]):
            st.markdown(message["content"])

    # Input area
    if prompt := st.chat_input("Type your message here..."):
        # Save user message
        st.session_state.messages.append({"role": "user", "content": prompt})

        # Display user message
        with st.chat_message("user"):
            st.markdown(prompt)

        # Generate assistant response
        with st.chat_message("assistant"):
            with st.spinner("Thinking..."):
                response = send_message_to_llm(st.session_state.session_id, prompt)
                st.markdown(response)

        # Save assistant message
        st.session_state.messages.append({"role": "assistant", "content": response})

    # Sidebar session controls
    with st.sidebar:
        st.subheader("Chat Session Info")
        st.write(f"Session ID: {st.session_state.session_id}")
        if st.button("Start New Chat Session"):
            st.session_state.session_id = str(uuid.uuid4())
            st.session_state.messages = []
            st.rerun()

# Footer
st.divider()
st.caption("Contract Management System powered by Streamlit & n8n")
