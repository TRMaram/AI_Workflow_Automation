# PMI Risk Monitoring Workflow

A comprehensive n8n workflow that automatically monitors project management risks and sends email alerts when critical thresholds are exceeded. This workflow analyzes bug tracking data and team performance metrics to proactively identify potential issues.

## 🎯 Overview

This workflow continuously monitors your project management data to detect:
- Critical bugs unresolved for more than 48 hours
- Development velocity issues
- High average resolution times
- Team workload imbalances
- Performance degradation trends

When risk thresholds are exceeded, the system automatically generates and sends detailed HTML email alerts to stakeholders.

## 🏗️ Workflow Architecture

The workflow consists of 6 main components:

1. **Schedule Trigger** - Runs the workflow at regular intervals
2. **Google Sheets** - Fetches project data from a centralized spreadsheet
3. **Code Node** - Processes and structures the data
4. **AI Agent** - Analyzes data and generates risk assessments
5. **OpenAI Chat Model** - Powers the AI analysis
6. **Gmail Tool** - Sends formatted email alerts

## 📊 Risk Metrics Monitored

### 1. Critical Bugs Alert
- **Threshold**: > 3 critical bugs unresolved for 48+ hours
- **Purpose**: Identifies high-priority issues that may impact system stability

### 2. Development Velocity
- **Threshold**: < 20% completion rate
- **Calculation**: (Resolved tickets / Total tickets) × 100
- **Purpose**: Monitors team productivity and project progress

### 3. Average Resolution Time
- **Threshold**: > 30 hours
- **Purpose**: Identifies process bottlenecks and efficiency issues

### 4. Junior Support Load
- **Threshold**: > 15 unresolved tickets
- **Teams Monitored**: Frontend, DevOps, Payment teams
- **Purpose**: Prevents junior team overload

### 5. Senior Support Load
- **Threshold**: > 15 unresolved tickets
- **Teams Monitored**: Backend Dev, Infrastructure, Security teams
- **Purpose**: Ensures senior resources aren't overwhelmed

## 🚀 Setup Instructions

### Prerequisites

- n8n instance (cloud or self-hosted)
- Google Sheets with project data
- Gmail account for sending alerts
- OpenAI API account

### 1. Import the Workflow

1. Copy the workflow JSON from `PMI_ex2_Risk.json`
2. In your n8n instance, go to **Workflows** → **Import from JSON**
3. Paste the JSON content and click **Import**

### 2. Configure Credentials

#### Google Sheets API
1. Go to **Settings** → **Credentials** → **Add Credential**
2. Select **Google Sheets OAuth2 API**
3. Follow the OAuth2 setup process:
   - Create a Google Cloud Project
   - Enable Google Sheets API
   - Create OAuth2 credentials
   - Configure authorized redirect URIs
4. Name the credential: `Google Sheets account 6`

#### Gmail API
1. Add a new **Gmail OAuth2** credential
2. Configure OAuth2 settings:
   - Use the same Google Cloud Project
   - Enable Gmail API
   - Set appropriate scopes (gmail.send)
3. Name the credential: `Gmail account 9`

#### OpenAI API
1. Add **OpenAI API** credential
2. Enter your OpenAI API key
3. Name the credential: `OpenAi account`

### 3. Configure Data Source

#### Google Sheets Setup
1. Create or use an existing Google Sheets document
2. Ensure your sheet contains the following columns:
   - `Severity` (Critical, High, Medium, Low)
   - `Status` (Open, In Progress, Resolved, Closed)
   - `Due Date` (Date format)
   - `Created On` (Date format)
   - `Assigned To` (Team names)
   - `Resolution Time (hrs)` (Numeric)

3. Update the **Google Sheets** node with your document ID and sheet name

### 4. Customize Alert Settings

#### Update Email Recipients
In the **Gmail1** node, change the `sendTo` parameter:
```
"sendTo": "your-email@domain.com"
```

#### Modify Risk Thresholds
Edit the **AI Agent** node prompt to adjust thresholds:
- Critical bugs threshold: Change `> 3`
- Velocity threshold: Change `> 20%`
- Resolution time threshold: Change `> 30`
- Support load thresholds: Change `> 15`

#### Configure Schedule
In the **Schedule Trigger** node, set your desired interval:
- Hourly: `0 * * * *`
- Daily: `0 9 * * *` (9 AM daily)
- Weekly: `0 9 * * 1` (9 AM every Monday)

## 🔧 Usage

### Manual Execution
1. Open the workflow in n8n
2. Click **Execute Workflow** to run manually
3. Monitor the execution in the workflow canvas

### Automated Execution
1. Activate the workflow using the toggle switch
2. The workflow will run according to your schedule
3. Check execution history in the **Executions** tab

### Monitoring Results
- **Email Alerts**: Stakeholders receive HTML-formatted risk reports
- **Execution Logs**: Review detailed logs in n8n interface
- **Error Handling**: Failed executions are logged for troubleshooting

## 📧 Email Alert Format

The system generates HTML-formatted emails containing:
- Executive summary of risk status
- Detailed breakdown of triggered alerts
- Specific metrics and thresholds exceeded
- Team-specific workload information
- Recommended actions

## 🛠️ Customization

### Adding New Risk Metrics
1. Modify the **AI Agent** prompt to include new calculations
2. Update the data processing logic in the **Code** node if needed
3. Adjust the email template format

### Team Configuration
Update team names in the AI Agent prompt to match your organization:
- Frontend Team → Your Frontend Team Name
- Backend Dev Team → Your Backend Team Name
- etc.

### Data Source Integration
The workflow can be adapted to work with:
- Different Google Sheets structures
- Other data sources (databases, APIs)
- Multiple data sources simultaneously

## 🔍 Troubleshooting

### Common Issues

**Authentication Errors**
- Verify all OAuth2 credentials are properly configured
- Check API quotas and limits
- Ensure proper scopes are set

**Data Processing Errors**
- Validate Google Sheets column names and data types
- Check date formats in your data
- Verify numeric fields contain valid numbers

**Email Delivery Issues**
- Confirm Gmail API is enabled
- Check spam folders for test emails
- Verify recipient email addresses

### Debug Mode
1. Enable debug mode in n8n settings
2. Run workflow manually to see detailed execution logs
3. Check each node's output data

## 📈 Performance Optimization

- **Batch Processing**: Process data in batches for large datasets
- **Caching**: Implement caching for frequently accessed data
- **Rate Limiting**: Respect API rate limits to avoid throttling
- **Error Handling**: Add retry logic for transient failures

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review n8n documentation
3. Open an issue in this repository
4. Contact the development team

---

**Note**: This workflow processes sensitive project data. Ensure proper security measures are in place and comply with your organization's data governance policies.
