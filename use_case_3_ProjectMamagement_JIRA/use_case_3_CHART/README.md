# PMI Report & Chart Generation Workflow

A comprehensive n8n workflow for automated project management intelligence, featuring weekly bug report generation, interactive chart creation, and intelligent data validation with AI agents.

## 🚀 Features

### Automated Weekly Reports
- **Scheduled Bug Reports**: Automatically generates weekly HTML reports from Google Sheets data
- **AI-Powered Analysis**: Uses GPT-4o-mini to analyze bug data and create insights
- **Multi-format Output**: Generates both HTML and PDF reports
- **Email Distribution**: Automatically sends reports via Gmail

### Interactive Chart Bot
- **Conversational Interface**: Chat-based chart creation with step-by-step guidance
- **Multiple Chart Types**: Bar, pie, line, doughnut, horizontal bar, and radar charts
- **Real-time Data Access**: Connects to MySQL and Supabase databases
- **Python Code Generation**: Provides equivalent Python scripts for offline use

### Intelligent Validation
- **Report Validation**: AI agent validates reports against original data
- **Auto-correction**: Automatically fixes missing or inaccurate sections
- **Quality Assurance**: Ensures all required sections and charts are present

## 🏗️ Architecture

### Main Components

1. **Data Ingestion**: Google Sheets → Code Processing
2. **Report Generation**: AI Agent → HTML/PDF Creation
3. **Validation Layer**: Validation Agent → Quality Control
4. **Distribution**: Email Delivery via Gmail
5. **Interactive Bot**: Chat Interface → Chart Generation

### Workflow Paths

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│  Schedule       │───►│ Google       │───►│ Data            │
│  Trigger        │    │ Sheets       │    │ Processing      │
└─────────────────┘    └──────────────┘    └─────────────────┘
                                                    │
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│  Email          │◄───│ PDF          │◄───│ Report          │
│  Distribution   │    │ Generation   │    │ Generation      │
└─────────────────┘    └──────────────┘    └─────────────────┘
                                                    │
                              ┌─────────────────────▼─────────────────────┐
                              │         Validation & Correction           │
                              └───────────────────────────────────────────┘

┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│  Chat           │───►│ RAG AI       │───►│ Chart           │
│  Trigger        │    │ Agent        │    │ Generation      │
└─────────────────┘    └──────────────┘    └─────────────────┘
```

## 📋 Prerequisites

- n8n installation (self-hosted or cloud)
- Google account with Sheets API access
- OpenAI API account
- Gmail account for email distribution
- MySQL database (for chart bot)
- Supabase account (optional, for additional data source)
- ConvertAPI account (for PDF generation)

## ⚙️ Setup Instructions

### 1. Clone and Import Workflow

1. Download the workflow JSON file
2. In n8n, go to **Workflows** → **Import from File**
3. Select the downloaded JSON file
4. Click **Import**

### 2. Required Credentials Setup

#### Google Sheets API
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable Google Sheets API
4. Create OAuth 2.0 credentials
5. In n8n: **Credentials** → **Add** → **Google Sheets OAuth2 API**
   - Enter your Client ID and Client Secret
   - Complete OAuth flow

#### Gmail API
1. In Google Cloud Console, enable Gmail API
2. Use the same OAuth credentials or create new ones
3. In n8n: **Credentials** → **Add** → **Gmail OAuth2**
   - Enter credentials and complete OAuth flow

#### OpenAI API
1. Get API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. In n8n: **Credentials** → **Add** → **OpenAI**
   - Enter your API key

#### MySQL Database
1. Set up MySQL database with `bug_reports` table
2. In n8n: **Credentials** → **Add** → **MySQL**
   - Host: `localhost` (or your MySQL host)
   - Database: `faces` (or your database name)
   - User: `root` (or your MySQL user)
   - Password: (your MySQL password)

#### Supabase (Optional)
1. Create account at [Supabase](https://supabase.com/)
2. Create project and get API credentials
3. In n8n: **Credentials** → **Add** → **Supabase**
   - Enter Project URL and API Key

#### ConvertAPI (PDF Generation)
1. Get API key from [ConvertAPI](https://www.convertapi.com/)
2. Update the HTTP Request nodes with your API key:
   - Replace `PkRk3XkwSeRy8t2ltaBjBhqnzCZtkmVx` with your key

### 3. Configure Data Sources

#### Google Sheets Setup
1. Create a Google Sheet with bug report data
2. Update the Google Sheets node with your sheet ID:
   - Replace `1MxEYi96HqUJeYS2DXAqt3DPmQ9_SiX-b0C5IeBkHn5A`
3. Ensure your sheet has the following columns:
   - ID, Title, Severity, Status, Source, Submitted By, Assigned To
   - Resolved On, Blocked, Type, Resolution Time

#### MySQL Table Structure
Create the `bug_reports` table:

```sql
CREATE TABLE bug_reports (
    id INT PRIMARY KEY,
    title VARCHAR(255),
    severity ENUM('Critical', 'Major', 'High', 'Medium', 'Low'),
    status ENUM('Open', 'In Progress', 'Resolved', 'Closed', 'Backlog'),
    source VARCHAR(100),
    submitted_by VARCHAR(100),
    assigned_to VARCHAR(100),
    resolved_on DATE,
    blocked ENUM('Yes', 'No'),
    type VARCHAR(50),
    resolution_time INT
);
```

### 4. Update Email Configuration

1. In both Gmail nodes, update the recipient email:
   - Replace `maramtrabelsi1212@gmail.com` with your email
2. Customize email subject and message as needed

### 5. Configure Schedule

1. Update the Schedule Trigger node:
   - Default: Weekly execution
   - Modify interval as needed (daily, bi-weekly, etc.)

## 🎯 Usage

### Automated Reports

1. **Activate the workflow**: Toggle the workflow to "Active"
2. **Manual trigger**: Click "Execute Workflow" for immediate execution
3. **Scheduled execution**: Reports will be generated automatically based on schedule
4. **Check email**: HTML and PDF reports will be delivered to configured email

### Interactive Chart Bot

1. **Access chat interface**: Use the webhook URL provided by the "When chat message received" node
2. **Start conversation**: Begin with greetings or directly request a chart
3. **Follow prompts**: The AI will guide you through:
   - Data selection
   - Chart type selection
   - Customization options
4. **Generate chart**: Receive interactive chart and optional Python code

### Example Chat Interactions

```
User: "Show me bugs by status"
Bot: "I can create that chart for you! I see we have Status data. 
      Would you like a pie chart or bar chart for this visualization?"

User: "Pie chart please"
Bot: "Perfect! Generating your pie chart of bugs by status..."
```

## 📊 Report Sections

The automated reports include:

1. **Executive Summary**: High-level overview of bug status
2. **Bugs Critiques Résolus**: Critical/Major resolved bugs
3. **Avancée du Développement**: Development progress overview
4. **BUGS Critical Blocked**: High-priority blocked issues
5. **Charge Support**: Support team workload
6. **Key Metrics**: Embedded charts and visualizations
7. **Trends & Insights**: Data analysis and patterns
8. **Milestones & Highlights**: Important achievements
9. **Suggested Focus**: Recommendations for next week

## 🔧 Customization

### Adding New Chart Types
1. Modify the RAG AI Agent prompt to include new chart types
2. Update the QuickChart HTTP request payload format
3. Test with sample data

### Custom Report Sections
1. Edit the main AI Agent prompt
2. Add new filtering logic for data sections
3. Update validation rules in the Validation Agent

### Email Templates
1. Modify HTML generation in Code nodes
2. Update email subject/body in Gmail nodes
3. Add custom styling or branding

## 🐛 Troubleshooting

### Common Issues

**Workflow fails at Google Sheets**
- Verify OAuth credentials are valid
- Check sheet permissions and ID
- Ensure sheet structure matches expected columns

**Charts not generating**
- Verify QuickChart service availability
- Check data format in HTTP request
- Validate JSON payload structure

**PDF generation fails**
- Confirm ConvertAPI key is valid
- Check API rate limits
- Verify HTML format is valid

**Email delivery issues**
- Check Gmail API quotas
- Verify recipient email address
- Review OAuth token validity

### Debug Tips

1. **Enable debug mode**: Turn on workflow execution data retention
2. **Check node outputs**: Examine data at each workflow step
3. **Test individual nodes**: Execute single nodes to isolate issues
4. **Review error logs**: Check n8n logs for detailed error messages

## 🔐 Security Notes

- Store all API keys securely in n8n credentials
- Use environment variables for sensitive data
- Regularly rotate API keys
- Limit database user permissions
- Review email distribution lists

## 📄 License

This workflow is provided as-is for educational and business use. Please ensure compliance with all third-party service terms of use.

## 🤝 Contributing

Feel free to fork, modify, and improve this workflow. Consider sharing enhancements with the community.

## 📞 Support

For issues and questions:
1. Check n8n documentation
2. Review service provider documentation (OpenAI, Google, etc.)
3. Test individual components
4. Create GitHub issues for workflow-specific problems

---

**Last Updated**: June 2025  
**Version**: 1.0  
**Compatible with**: n8n v1.0+
