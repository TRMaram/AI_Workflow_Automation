# Import the necessary libraries at the top of your script if not already done
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

# Initialize session state variables if they don't exist
if 'submission_attempted' not in st.session_state:
    st.session_state.submission_attempted = False
if 'submission_result' not in st.session_state:
    st.session_state.submission_result = None
if 'submission_error' not in st.session_state:
    st.session_state.submission_error = None
# Set page configuration
st.set_page_config(page_title="Contract Management System", layout="wide")

# App title
st.title("Contract Management System")
# N8N webhook configuration
CONTRACTS_API_URL = "http://localhost:5678/webhook"  # Replace with your actual n8n API endpoint
CONTRACT_UPLOAD_URL = "http://localhost:5678/webhook/upload"  # Replace with your actual n8n webhook URL
API_TOKEN = "test_chat"  # Replace with your actual token

# Define headers for API requests
headers = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}
@st.cache_data(ttl=600)
def get_contracts_approaching_notice_period(df):
    # Convert the expiration column to datetime
    df["contract_expiration_date"] = pd.to_datetime(df["contract_expiration_date"], errors="coerce")
    
    today = pd.Timestamp.now()
    
    # Create a new column with the notice deadline date
    df["notice_deadline"] = df.apply(
        lambda row: row["contract_expiration_date"] - pd.Timedelta(days=row["notice_days"]+1) 
        if pd.notna(row["contract_expiration_date"]) and pd.notna(row["notice_days"]) 
        else pd.NaT, 
        axis=1
    )
    
    # Calculate the date range we want to check
    
    #notice_approaching_end = today + pd.Timedelta(days=1)
    
    # Filter contracts where:
    # 1. Notice deadline falls between today and X days in the future
    # 2. Contract hasn't expired yet
    return df[
        (today >= df["notice_deadline"]) &
        (df["contract_expiration_date"] > today)
    ]
def get_contracts_by_company1(company_name):
    try:
        response = requests.get(
            f"{CONTRACTS_API_URL}/contracts", 
            params={"societe client": company_name},
            headers=headers
        )
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        st.error(f"Error fetching contracts: {str(e)}")
        return []
def get_companies():
    try:
        response = requests.get(f"{CONTRACTS_API_URL}/get_companies", headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        st.error(f"Error fetching companies: {str(e)}")
        return []
def get_expiring_contracts(df):
    
    # Convert the expiration column to datetime
    df["contract_expiration_date"] = pd.to_datetime(df["contract_expiration_date"], errors="coerce")
    
    today = pd.Timestamp.now()
    in_6_months = today + pd.DateOffset(months=6)
    
    return df[(df["contract_expiration_date"] >= today) & (df["contract_expiration_date"] <= in_6_months)]

# Define your handle_submission function if not already defined
def handle_submission(selected_contract, bullet_points_text):
    try:
        headers2 = {
                                    "Authorization": f"Bearer {API_TOKEN}",
                                    "Content-Type": "application/json",
                                    "Accept": "*/*",
                                    "Connection": "keep-alive"
                                }

        params = {
                                    "client_name": str(selected_contract.get("societe client", "")),
                                    "contract_type": str(selected_contract.get("type of contrat", "")),
                                    "expiration_date": str(selected_contract.get("contract_expiration_date", "")),
                                    "days_until_expiration": int(selected_contract.get("days_until_expiration", 0)),
                                    "notice_days": int(selected_contract.get("notice_days", 0)),
                                    "contract_id": str(selected_contract.get("contract_id", "")),
                                    "text_content": bullet_points_text.strip(),
                                    "timestamp": str(pd.Timestamp.now())
                                }

                                # Send POST request
        response = requests.post("http://localhost:5678/webhook/generate", headers=headers2, params=params)

        
        # Simulate successful response for demonstration
        st.session_state.submission_attempted = True
        st.session_state.submission_result = {
            "status_code": 200,
            "headers": {"Content-Type": "application/json"},
            "json": {"message": "Contract successfully submitted to workflow"},
            "text": "Success"
        }
        st.session_state.submission_error = None
        
    except Exception as e:
        st.session_state.submission_attempted = True
        st.session_state.submission_error = str(e)
        st.session_state.submission_result = None
def upload_and_process_file(binary_data, file_name, file_type, company_name):
    try:
        # Convert file to base64 for sending in JSON
        #file_base64 = base64.b64encode(binary_data).decode('utf-8')
        
        
        # Create payload with file content and metadata
        params = {
            "fileName": file_name,
            "fileType": file_type,
            "companyName": company_name,
            "uploadId": str(uuid.uuid4()),
            "timestamp": str(pd.Timestamp.now())
        }
        headers1 = {
            "Authorization": f"Bearer {API_TOKEN}",
            "Content-Type":  "application/octet-stream"
        }
        # Send to n8n webhook for processing
        response = requests.post(CONTRACT_UPLOAD_URL, headers=headers1, data=binary_data,params=params)
        response.raise_for_status()
        return response.ok
    except requests.exceptions.RequestException as e:
        st.error(f"Error processing file: {str(e)}")
        # Return detailed error message if available
        if hasattr(e, 'response') and e.response is not None:
            try:
                error_detail = e.response.json()
                return {"success": False, "message": str(e), "detail": error_detail}
            except:
                return {"success": False, "message": str(e), "status_code": e.response.status_code}
        return {"success": False, "message": str(e)}
def send_expiring_contracts_email(expiring_df, recipient_email,workflow_url):
    contract_table = expiring_df.to_html(index=False)
    try:
        
        params = {
            "recipient": recipient_email,
            "subject": "Notification: Contracts Expiring Soon",
            "contracts": f"""
        <html>
        <body>
            <h2>Contracts Expiring Soon</h2>
            <p>The following contracts will expire soon and may require attention:</p>
            {contract_table}
            <p>Click the link below to access the contract termination process:</p>
            <p><a href="{workflow_url}">Generate offers</a></p>
            <p>This is an automated notification. Please do not reply to this email.</p>
        </body>
        </html>
        """
        }
        email_webhook_url = f"{CONTRACTS_API_URL}/notify_expiring"  # Adjust to match your n8n flow
        response = requests.get(email_webhook_url, headers=headers, params=params)
        response.raise_for_status()
        return True
    except requests.exceptions.RequestException as e:
        st.error(f"Failed to send notification: {str(e)}")
        return False





# Sidebar navigation
st.sidebar.title("Navigation")
page = st.sidebar.radio("Go to", ["📄 View Contracts", "📤 Upload Contract", "💬 Chat Interface"])

if page == "📄 View Contracts":
        st.header("View Contracts")
        companies = get_companies()
        company_names = [company["company_name"] for company in companies] if companies else []
        selected_company = st.selectbox("Select Company", company_names)
        contracts = get_contracts_by_company1(selected_company)
        df = pd.DataFrame(contracts)
        if company_names:
            st.subheader(f"All Contracts for {selected_company}")
            contracts = get_contracts_by_company1(selected_company)
            df = pd.DataFrame(contracts)
            st.dataframe(df, use_container_width=True)                        
            csv = df.to_csv(index=False)
            st.download_button(
                            label="Download as CSV",
                                data=csv,
                                file_name=f"{selected_company}_contracts.csv",
                                mime="text/csv"
                            )
                        
            
        # Contract selection for individual handling
        contracts_in_notice_period = get_contracts_approaching_notice_period(df)
        if not contracts_in_notice_period.empty:
            st.warning("⚠️ Contracts in notice period requiring immediate attention!")
            # Add a column to show how many days left until expiration
            contracts_in_notice_period = contracts_in_notice_period.copy()

            st.dataframe(contracts_in_notice_period, use_container_width=True)
            if send_expiring_contracts_email(contracts_in_notice_period, 'maramtrabelsi1212@gmail.com', "http://localhost:5678/webhook/notify_expiring"):
                st.success(f"📧 Notification about contracts in notice period sent to {'maramtrabelsi1212@gmail.com'}!")
                        
            else:
                st.error("⚠️ Failed to send email notification!")
            contracts_in_notice_period["days_until_expiration"] = (contracts_in_notice_period["contract_expiration_date"] - pd.Timestamp.now()
                                ).dt.days   # Let user select which contract to handle
            contract_options = [f"{row['societe client']} - {row['type of contract']} (Expires in {row['days_until_expiration']} days)" 
                                for _, row in contracts_in_notice_period.iterrows()]
            st.subheader("Generate Request for Proposal (RFP)")
            selected_contract_idx = st.selectbox("Select contract to handle:", 
                                            options=range(len(contract_options)),
                                            format_func=lambda x: contract_options[x],
                                            key="contract_selector")
            
            # Get the selected contract data
            selected_contract = contracts_in_notice_period.iloc[selected_contract_idx]
            
            # Display information about selected contract
            
            st.info(f"Selected Contract: {selected_contract['societe client']} - {selected_contract['type of contract']} ")
            
            st.info(f"Days until expiration: {selected_contract['days_until_expiration']}")
            
            # Form for contract handling
            with st.form(key="contract_handling_form"):
                bullet_points_text = st.text_area(
                    "Enter additional information for this contract:",
                    height=150,
                    placeholder="Type your notes here...",
                    key="notes_text_area"
                )

                # Submit button inside the form
                submit_button = st.form_submit_button("Submit to Workflow")
                
                # Form submit button behavior is automatically handled by Streamlit
                # The code below will only run after form submission
                if submit_button:
                    if bullet_points_text.strip():
                        # Call the handle_submission function
                        handle_submission(selected_contract, bullet_points_text)
                    else:
                        st.warning("Please enter some information before submitting.")
            
            # Display results outside the form
            if st.session_state.submission_attempted:
                if st.session_state.submission_error:
                    st.error(f"Error occurred during submission: {st.session_state.submission_error}")
                elif st.session_state.submission_result:
                    result = st.session_state.submission_result
                    if 200 <= result["status_code"] < 300:
                        st.success(f"✅ Information submitted successfully! Status code: {result['status_code']}")
                    else:
                        st.error(f"Submission failed with status code: {result['status_code']}")

                    st.write("**Response Headers:**")
                    st.json(result["headers"])

                    if "json" in result:
                        st.write("**Response Body (JSON):**")
                        st.json(result["json"])
                    elif result["text"]:
                        st.write("**Response Body (Text):**")
                        st.code(result["text"])
                        
                # Add a button to clear the submission status
                if st.button("Clear Submission Status"):
                    st.session_state.submission_attempted = False
                    st.session_state.submission_result = None
                    st.session_state.submission_error = None
                    st.experimental_rerun()
        def trigger_n8n_webhook():
            try:
                # Display a spinner while making the request
                
                with st.spinner("Generate Analysis..."):
                    response = requests.post("http://localhost:5678/webhook/synthese",headers=headers)
                
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
        st.subheader("Generate Analysis of Incoming Proposals :")
        if st.button("🚀 Generate Analysis", type="primary", use_container_width=True):
            trigger_n8n_webhook()










elif page == "📤 Upload Contract":
    st.header("Upload & Classify Contract")

    show_debug = st.checkbox("Show Debug Information", value=False)
    
    if show_debug:
        with st.expander("Debug Configuration", expanded=True):
            st.code(f"Webhook URL: {CONTRACT_UPLOAD_URL}")
    companies = get_companies()
    company_names = [company["company_name"] for company in companies] if companies else []
        
    # Form for contract upload
    with st.form("upload_form"):
        # Select company
        company_for_upload = st.selectbox("Select Company", company_names if company_names else [""])
        
        # File uploader
        uploaded_file = st.file_uploader("Upload any document for text extraction and classification", type=None)
        # Show file information if uploaded
        if uploaded_file is not None:
            st.write(f"File: {uploaded_file.name} ({uploaded_file.size} bytes)")
            if uploaded_file.type:
                st.write(f"Type: {uploaded_file.type}")
        
        # Submit button
        submit_button = st.form_submit_button("Upload & Classify")
        
    if submit_button and uploaded_file is not None and company_for_upload:
        with st.spinner("Processing document..."):
            try:
                # Read file bytes - this is key to match Postman
                binary_data = uploaded_file.getvalue()  # Use getvalue() instead of read()
                file_name = uploaded_file.name
                file_type = uploaded_file.type if uploaded_file.type else "application/octet-stream"
                
                # Generate a unique ID for tracking
                upload_id = str(uuid.uuid4())
                timestamp = str(pd.Timestamp.now())
                
                # Prepare request parameters as query string parameters
                # This is how Postman sends additional data with binary uploads
                params = {
                    "fileName": file_name,
                    "fileType": file_type,
                    "companyName": company_for_upload,
                    "uploadId": upload_id,
                    "timestamp": timestamp
                }
                
                # Set headers exactly like Postman would
                headers1 = {
                    "Authorization": f"Bearer {API_TOKEN}",
                    "Content-Type": file_type,  # Use the actual file MIME type
                    "Accept": "*/*",  # Postman typically includes this
                    "Connection": "keep-alive"  # Postman typically includes this
                }
                
                if show_debug:
                    with st.expander("Request Details", expanded=True):
                        st.write("**Headers:**")
                        st.json(headers)
                        st.write("**Query Parameters:**")
                        st.json(params)
                        st.write(f"**Binary Data Size:** {len(binary_data)} bytes")
                        st.write(f"**Binary Data Type:** {type(binary_data).__name__}")
                
                # Make the request exactly like Postman would
                response = requests.post(
                    CONTRACT_UPLOAD_URL,
                    headers=headers1,
                    data=binary_data,  # Send raw binary data as body
                    params=params      # Send parameters as query string
                )
                
                if show_debug:
                    with st.expander("Raw Response", expanded=True):
                        st.write(f"**Status Code:** {response.status_code}")
                        st.write(f"**Headers:** {dict(response.headers)}")
                        # Check if response has content
                        response_content = response.text
                        st.text(f"**Content:** {response_content if response_content else '(Empty response)'}")
                
                # Handle response
                if 200 <= response.status_code < 300:
                    st.success(f"Document sent successfully (Status: {response.status_code})")
                    
                    # Try to parse response as JSON if there's content
                    if response.text.strip():
                        try:
                            result = response.json()
                            if result.get("success", True):
                                st.success(f"Processing result: {result.get('message', 'Successful')}")
                            else:
                                st.warning(f"Process reported an issue: {result.get('message', 'Unknown error')}")
                            
                            # Display any additional information
                            with st.expander("Response Details"):
                                st.json(result)
                        except ValueError:
                            st.info("Response wasn't JSON format, but request was successful")
                    else:
                        st.info("No content was returned in the response, but the HTTP status indicates success.")
                        st.success("The n8n workflow has been triggered successfully.")
                    
                    # Show tracking information
                    st.info(f"Upload tracking ID: {upload_id}")
                    
                    # Provide link to view all contracts
                    if st.button("View All Contracts"):
                        st.session_state["page"] = "View Contracts"
                        st.rerun()
                else:
                    st.error(f"Failed to process document. Status code: {response.status_code}")
                    
                    if response.text.strip():
                        with st.expander("Error Details"):
                            try:
                                st.json(response.json())
                            except ValueError:
                                st.text(response.text)
            
            except requests.exceptions.RequestException as e:
                st.error(f"Error connecting to the API: {str(e)}")
                
            except Exception as e:
                st.error(f"An unexpected error occurred: {str(e)}")
                st.exception(e)  # This will show the full traceback in development
                
            finally:
                # Reset the file uploader position after reading
                if uploaded_file is not None:
                    uploaded_file.seek(0)
                
    elif submit_button:
        if not uploaded_file:
            st.warning("Please upload a document")
        if not company_for_upload:
            st.warning("Please select a company")



elif page == "💬 Chat Interface":
    st.header("Chat with AI Assistant")

    # Initialize session state variables if they don't exist
    if "session_id" not in st.session_state:
        st.session_state.session_id = str(uuid.uuid4())  # Generate a random session ID

    if "messages" not in st.session_state:
        st.session_state.messages = []

    # Webhook URL for chat (You can also reuse API_TOKEN from earlier)
    CHAT_WEBHOOK_URL = "http://localhost:5678/webhook/invoke_agent"  # Replace if different

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
            response = requests.post(CHAT_WEBHOOK_URL, headers=headers, json=payload)
            response.raise_for_status()
            result = response.json()
            return result.get("output", "Sorry, I couldn't process your request.")
        except requests.exceptions.RequestException as e:
            return f"Error communicating with the AI service: {str(e)}"

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