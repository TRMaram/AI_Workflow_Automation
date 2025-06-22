# PMI Document Processing & Retrieval Workflow

## Overview

This n8n workflow provides an intelligent document processing and retrieval system for software project teams. It combines automated document ingestion from Google Drive with AI-powered analysis and a chat-based retrieval interface.

## 🚀 Features

### Document Processing Pipeline
- **Automated Ingestion**: Monitors Google Drive folder for new documents (PDF, DOCX, Google Docs)
- **AI-Powered Analysis**: Automatically categorizes and extracts metadata from uploaded documents
- **Smart Classification**: Identifies document types (Bug Reports, QA Test Reports, Feature Specs, etc.)
- **Topic & Tag Generation**: Automatically generates relevant topics and tags for better searchability
- **Quality Control**: Includes validation agent to ensure data integrity

### Intelligent Document Retrieval
- **Natural Language Queries**: Users can ask questions in plain English
- **Context-Aware Search**: AI agent understands intent and searches relevant documents
- **PostgreSQL Integration**: Stores processed documents with rich metadata
- **Memory System**: Maintains conversation context for better user experience

## 🏗️ Architecture

### Workflow Components

#### 1. Document Ingestion Branch
```
Google Drive Trigger → Download → File Type Detection → Text Extraction → AI Analysis → Validation → Database Storage
```

#### 2. Chat Interface Branch
```
Chat Trigger → Query Processing → Database Search → Response Generation → User Response
```

### Key Nodes

| Node Type | Purpose |
|-----------|---------|
| **Google Drive Trigger** | Monitors folder for new documents |
| **Switch** | Routes documents based on file type (PDF/DOCX/Google Docs) |
| **Extract from File** | Extracts text content from various formats |
| **AI Agent** | Analyzes documents and generates metadata |
| **AI Agent1** | Validates generated metadata for quality control |
| **Supabase** | Stores processed documents in PostgreSQL database |
| **RAG AI Agent** | Handles natural language queries and retrieval |
| **Postgres Chat Memory** | Maintains conversation context |

## 📋 Prerequisites

### Required Services
- **n8n Instance** (self-hosted or cloud)
- **Google Drive** with API access
- **Supabase/PostgreSQL** database
- **OpenAI API** account

### Required n8n Nodes
- `@n8n/n8n-nodes-langchain` (LangChain integration)
- `n8n-nodes-docx-converter` (DOCX processing)
- Base n8n nodes (webhook, postgres, google drive, etc.)

## 🔧 Setup Instructions

### 1. Database Setup

Create a PostgreSQL table with the following schema:

```sql
CREATE TABLE project_documents (
    id SERIAL PRIMARY KEY,
    document_type VARCHAR(255),
    doc_name VARCHAR(255),
    summary TEXT,
    topics TEXT[],
    tags TEXT[],
    link_pdf TEXT,
    link_docx TEXT,
    link_html TEXT,
    link_rtf TEXT,
    link_odt TEXT,
    link_markdown TEXT,
    link_markdown_alt TEXT,
    link_epub TEXT,
    link_zip TEXT,
    link_txt TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### 2. Credentials Configuration

Configure the following credentials in your n8n instance:

- **Google Drive OAuth2 API**: For accessing Google Drive
- **OpenAI API**: For AI processing (requires GPT-4 access)
- **PostgreSQL**: For database operations
- **Supabase API**: If using Supabase instead of direct PostgreSQL
- **Header Auth**: For webhook security

### 3. Workflow Configuration

1. **Import the workflow** into your n8n instance
2. **Update Google Drive folder ID** in the Google Drive Trigger node
3. **Configure database connections** in Supabase/PostgreSQL nodes
4. **Set up webhook endpoints** for the chat interface
5. **Test the connections** and activate the workflow

### 4. Google Drive Folder Structure

Create a monitored folder in Google Drive where team members can upload documents. The workflow will automatically process any PDF, DOCX, or Google Docs files added to this folder.

## 🎯 Usage

### Document Upload
1. Upload documents (PDF, DOCX, Google Docs) to the monitored Google Drive folder
2. The workflow automatically detects new files and processes them
3. Documents are analyzed, categorized, and stored with metadata

### Document Retrieval
Send POST requests to the chat webhook endpoint:

```json
{
  "chatInput": "Find all bug reports related to checkout process",
  "sessionId": "user123"
}
```

### Example Queries
- "Show me QA test reports from last week"
- "Find bug reports related to UI issues"
- "What feature specifications are available for the payment module?"
- "List all critical bugs in the system"

## 🔍 AI Processing Details

### Document Analysis
The AI agent analyzes uploaded documents and extracts:
- **Document Type**: Automatically categorizes (Bug Report, QA Test Report, Feature Spec, etc.)
- **Summary**: 3-5 sentence summary of the document's purpose and content
- **Topics**: Key topics discussed in the document
- **Tags**: Classification tags for better filtering

### Quality Control
A validation agent ensures:
- JSON structure compliance
- Required field presence
- Data consistency
- Error correction when needed

### Search Intelligence
The retrieval agent:
- Understands natural language queries
- Generates appropriate SQL WHERE clauses
- Returns relevant documents with context
- Maintains conversation memory

## 📊 Performance Notes

- **Processing Speed**: Fast document analysis using GPT-4o-mini for efficiency
- **Validation Rate**: Current testing shows ~82% initial validation success rate
- **Search Accuracy**: Excellent retrieval results with contextual understanding
- **Scalability**: Handles batch processing of multiple documents

## 🛠️ Customization

### Document Types
Modify the AI agent prompt to recognize additional document types specific to your project needs.

### Database Schema
Extend the database schema to include additional metadata fields as required.

### Search Filters
Customize the search logic in the RAG AI Agent to include additional filtering criteria.

## 🔒 Security Considerations

- Use webhook authentication for API endpoints
- Implement proper database access controls
- Secure API credentials in n8n credential store
- Consider document access permissions in Google Drive

## 📈 Monitoring & Maintenance

- Monitor workflow execution logs for errors
- Regularly review AI validation results
- Update prompts based on document processing feedback
- Maintain database performance with appropriate indexing

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test changes thoroughly
4. Submit a pull request with detailed description

## 📄 License

This workflow is provided as-is for educational and project use. Ensure compliance with all API terms of service.

## 🆘 Troubleshooting

### Common Issues
- **File Processing Errors**: Check file permissions and format support
- **AI Analysis Failures**: Verify OpenAI API credits and model availability
- **Database Connection Issues**: Confirm credentials and network access
- **Webhook Timeouts**: Consider implementing async processing for large documents

### Support
For issues and questions, please create an issue in this repository with:
- Error messages
- Workflow execution logs
- Document types being processed
- Expected vs actual behavior

---

*This workflow demonstrates the power of combining n8n's automation capabilities with modern AI services for intelligent document management.*
