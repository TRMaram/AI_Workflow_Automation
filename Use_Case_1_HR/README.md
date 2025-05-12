
## ✅ 1. Set Up the n8n Workflow

### 🔹 Step 1: Install n8n (locally or via Docker)

#### Option A – Natively (Node.js required)

1. Install Node.js (v18 recommended): [https://nodejs.org/](https://nodejs.org/)
2. Install n8n globally:

```bash
npm install n8n -g
```

3. Run n8n:

```bash
n8n
```

It will be available at `http://localhost:5678`

#### Option B – Using Docker (preferred for clean setup)

```bash
docker run -it --rm \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

---

### 🔹 Step 2: Import the JSON Workflow

1. Open `http://localhost:5678` in your browser.
2. Click the gear icon (top right) → “Import Workflow”.
3. Select your `.json` file and import it.

---

### 🔹 Step 3: Configure Credentials and Webhooks
🔐 1. Gmail Node (OAuth2)
Set up Gmail OAuth credentials in the Google Cloud Console.
[Guide for Gmail Node setup](https://docs.n8n.io/integrations/builtin/credentials/google/oauth-generic/#prerequisites)
In n8n:

Go to Credentials > Google Gmail OAuth2 API.

Use:

Client ID

Client Secret

Redirect URI: http://localhost:5678/rest/oauth2-credential/callback


🧠 2. Gemini API Key
* make an account if you dont have one
* Get your Gemini API key from: https://aistudio.google.com/app/apikey
🧠 2. Groq API Key
* make an account
* Get your Groq API key from: [Groq apikey](https://console.groq.com/keys)

Save as an environment variable or in n8n credentials.

🔎 3. Cohere Embedder
Create an account and get your API key: https://dashboard.cohere.ai

🗄️ 4. Supabase
use this as guide : [Guide Supabase Setup](https://youtu.be/JjBofKJnYIU?si=CLL0iPvbrdMdtGWj)
1. create a new organization account
2. create a new project and copy the password of the project
3. PostGres Node Setup : 
* go to project settings --> then go to DataBase Settings  --> click on button connect on the nav bar
* in the connect panel change the code to postgres --> in the Transaction Pooler  section : copy the host variable (after the -h), copy the User (after the -U), copy the port (after -p) 
* use the project password as password in postgres node
4. Supabase Account Setup : [Guide](https://docs.n8n.io/integrations/builtin/credentials/supabase/#related-resources)
* go to project settings --> then go to Data API
* copy the project URL as Host , Copy the service role (secret)
5. Initialize Database : [Guide](https://supabase.com/docs/guides/ai/langchain?database-method=sql)
* copy the sql script from the guide into SQL Editor and run the script
* copy this to your script : 

```bash
-- Enable the pgvector extension to work with embedding vectors
create extension vector;

-- Create a table to store your documents
create table documents_3_duplicate (
  id bigserial primary key,
  content text, -- corresponds to Document.pageContent
  metadata jsonb, -- corresponds to Document.metadata
  embedding vector(1024) -- 1536 works for OpenAI embeddings, change if needed
);

-- Create a function to search for documents
create function match_documents_4 (
  query_embedding vector(1024),
  match_count int default null,
  filter jsonb DEFAULT '{}'
) returns table (
  id bigint,
  content text,
  metadata jsonb,
  similarity float
)
language plpgsql
as $$
#variable_conflict use_column
begin
  return query
  select
    id,
    content,
    metadata,
    1 - (documents_3_duplicate.embedding <=> query_embedding) as similarity
  from documents_3_duplicate
  where metadata @> filter
  order by documents_3_duplicate.embedding <=> query_embedding
  limit match_count;
end;
$$;
CREATE TABLE contracts (
    "id" TEXT PRIMARY KEY,
    "contract file name" TEXT,
    "societe client" TEXT,
    "societe partenaire" TEXT,
    "type of contract" TEXT,
    "contract_expiration_date" DATE,
    "contract_start_date" DATE,
    "termination_terms" JSON,
    "notice_days" INTEGER
);
CREATE TABLE fournisseur (
    "id" TEXT PRIMARY KEY,
    "name" TEXT NOT NULL,
    "email" TEXT,
    "phone" TEXT
);
CREATE TABLE proposals (
    "id" TEXT PRIMARY KEY,
    "contract_content" TEXT,
    "type" TEXT
);
CREATE TABLE "public"."companies" (
    "id" TEXT PRIMARY KEY,
    "company_name" TEXT NOT NULL
);
