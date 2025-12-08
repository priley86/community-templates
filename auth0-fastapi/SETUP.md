# Setup Guide

This guide will walk you through setting up the Auth0 + Firebase + FastAPI + LangChain Starter template.

## 🚀 Quick Start

### One-Click Setup (Recommended)

[![Open in IDX](https://cdn.idx.dev/btn/open_dark_32@2x.png)](https://idx.google.com/new?template=https://github.com/firebase-studio/community-templates/tree/main/auth0-fastapi)

1. Click the button above
2. Wait for workspace initialization
3. Configure your `.env` files (see below)
4. Start chatting with your AI assistant!

### Local Development Setup

```bash
# Backend
cd backend
uv sync
cp .env.example .env  # Edit with your credentials
source .venv/bin/activate
fastapi dev app/main.py  # Terminal 1

# LangGraph (in a new terminal)
cd backend
source .venv/bin/activate
langgraph dev --port 54367 --no-browser --allow-blocking  # Terminal 2

# Frontend (in a new terminal)
cd frontend
npm install
cp .env.example .env  # Edit with your credentials
npm run dev  # Terminal 3
```

## Prerequisites

Before you begin, make sure you have:

1. **Auth0 Account**: Sign up at [auth0.com](https://auth0.com/)
2. **LLM API Key**: Choose one:
   - **Google AI API Key** (default): Get one at [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
   - **OpenAI API Key**: Get one at [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
3. **Firebase Studio Account** (optional): For cloud development at [idx.google.com](https://idx.google.com/)

### For Local Development Only

- **Python 3.13+**: [python.org/downloads](https://www.python.org/downloads/)
- **Node.js 20+**: [nodejs.org](https://nodejs.org/)
- **uv**: Python package manager - [docs.astral.sh/uv](https://docs.astral.sh/uv/)

> **Note**: This template supports both Google Gemini and OpenAI models. The default configuration uses Google Gemini's `gemini-2.0-flash-exp`. You can easily switch between providers by modifying `backend/app/agents/assistant0.py` - see the GEMINI.md guide for detailed instructions.

## Auth0 Setup

### 1. Create an Auth0 Application

1. Log in to your [Auth0 Dashboard](https://manage.auth0.com/)
2. Navigate to **Applications** > **Applications**
3. Click **Create Application**
4. Choose **Regular Web Applications**
5. Give it a name (e.g., "AI Assistant")
6. Click **Create**

### 2. Configure Application Settings

In your application settings:

#### Application URIs

For Firebase Studio/IDX, you'll need to add:
- **Allowed Callback URLs**: 
  ```
  https://9000-<YOUR-WORKSPACE-ID>.<YOUR-CLUSTER-ID>.cloudworkkstations.dev/api/auth/callback
  ```
- **Allowed Logout URLs**:
  ```
  https://9000-<YOUR-WORKSPACE-ID>.<YOUR-CLUSTER-ID>.cloudworkkstations.dev
  ```
- **Allowed Web Origins**:
  ```
  https://9000-<YOUR-WORKSPACE-ID>.<YOUR-CLUSTER-ID>.cloudworkkstations.dev
  ```

For your deployed Firebase app, you'll need the same:
- **Allowed Callback URLs**: 
  ```
  https://<YOUR-DOMAIN>/api/auth/callback
  ```
  
- **Allowed Logout URLs**:
  ```
  https://<YOUR-DOMAIN>
  ```
  
- **Allowed Web Origins**:
  ```
  https://<YOUR-DOMAIN>
  ```

For local development, you'll want to also add the following:
- **Allowed Callback URLs**: 
  ```
  http://localhost:9000/api/auth/callback
  ```
  
- **Allowed Logout URLs**:
  ```
  http://localhost:9000
  ```
  
- **Allowed Web Origins**:
  ```
  http://localhost:9000
  ```

#### Save Your Credentials

Note down these values (you'll need them for environment variables):
- **Domain** (e.g., `your-tenant.auth0.com`)
- **Client ID**
- **Client Secret**

### 3. Generate a Secret Key

Generate a random secret key for session management:

```bash
openssl rand -hex 32
```

Or use Python:

```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

## Environment Configuration

### Backend Configuration

1. Navigate to the `backend` directory
2. Copy the example env file:
   ```bash
   cp .env.example .env
   ```
3. Edit `.env` with your credentials:

```env
# Auth0 Configuration
AUTH0_DOMAIN=your-tenant.auth0.com
AUTH0_CLIENT_ID=your-client-id
AUTH0_CLIENT_SECRET=your-client-secret
AUTH0_SECRET=your-generated-secret-key

# LLM API Key (choose one based on your provider)
# For Google Gemini (default): Get your key at https://aistudio.google.com/app/apikey
# For OpenAI: Get your key at https://platform.openai.com/api-keys
GOOGLE_API_KEY=your-api-key

# Application URLs
# APP_BASE_URL is the frontend URL (used for Auth0 callbacks)
APP_BASE_URL=http://localhost:9000
FRONTEND_HOST=http://localhost:9000

# LangGraph Configuration
LANGGRAPH_API_URL=http://localhost:54367
LANGGRAPH_API_KEY=

# CORS Origins (comma-separated)
BACKEND_CORS_ORIGINS=http://localhost:8000,http://localhost:9000
```

### Frontend Configuration

1. Navigate to the `frontend` directory
2. Copy the example env file:
   ```bash
   cp .env.example .env
   ```
3. Edit `.env` with your credentials:

```env
# API URL
VITE_API_URL=http://localhost:8000
```

## Running the Application

### Option 1: Using Firebase Studio (Project IDX)

1. Click the "Open in IDX" button in the README
2. Wait for the workspace to initialize
3. Configure your `.env` files as described above
4. The servers will start automatically!

> **⚠️ Important for Firebase Studio users**: The embedded "Web" preview window may show authentication errors due to third-party cookie blocking. **Always use the "Preview" button or "Open in new tab" button** (↗️) to open the application in a full browser tab where authentication will work correctly.


### Option 2: Local Development

#### Terminal 1: Backend API

```bash
cd backend
uv sync
source .venv/bin/activate
fastapi dev app/main.py
```

The backend will run on `http://localhost:8000`

#### Terminal 2: LangGraph Server

```bash
cd backend
source .venv/bin/activate
langgraph dev --port 54367 --no-browser --allow-blocking
```

The LangGraph server will run on `http://localhost:54367`

#### Terminal 3: Frontend

```bash
cd frontend
npm install
npm run dev
```

The frontend will run on `http://localhost:9000`

## Verifying the Setup

1. Open your browser to `http://localhost:9000`
2. You should be redirected to Auth0 login
3. After logging in, you should see the chat interface
4. Try sending a message to the AI assistant

## Troubleshooting

### Auth0 Errors

- **"Callback URL mismatch"**: Make sure your callback URLs are configured correctly in Auth0
- **"Client authentication failed"**: Double-check your Client ID and Client Secret

### Backend Errors

- **"Module not found"**: Run `cd backend && uv sync` again
- **"API error"**: Verify your API key is correct and enabled
- **"Cannot start FastAPI"**: Check that port 8000 is not already in use

### Frontend Errors

- **"Cannot connect to backend"**: Make sure the backend server is running on port 8000
- **"Auth0 configuration error"**: Verify your Auth0 domain and client ID in `.env`
- **"Module not found"**: Run `cd frontend && npm install`

### LangGraph Errors

- **"Cannot connect to LangGraph"**: Make sure the LangGraph server is running on port 54367
- **"Agent not found"**: Verify `langgraph.json` is configured correctly
- **"Port already in use"**: Kill the process using the port or use a different port

## Key Files Reference

| Purpose | File |
|---------|------|
| Agent logic | `backend/app/agents/assistant0.py` |
| Agent tools | `backend/app/agents/tools/` |
| API routes | `backend/app/api/routes/` |
| Frontend UI | `frontend/src/pages/ChatPage.tsx` |
| Layout | `frontend/src/components/layout.tsx` |
| Auth UI | `frontend/src/components/auth0/user-button.tsx` |
| Config | `.idx/dev.nix` or `dev.nix` |

## Deployment

The setup above is for local development with `fastapi dev` and `langgraph dev`.

For **production deployment** to Google Cloud Run and Firebase Hosting, see **[DEPLOYMENT.md](DEPLOYMENT.md)** for:

- Step-by-step deployment instructions
- Quick deploy commands and scripts
- Firebase Studio Cloud Run button configuration
- Security best practices and monitoring
- Cost optimization tips
- Troubleshooting and CI/CD setup

## Next Steps

Once everything is working:

1. **Customize the Agent**: Edit `backend/app/agents/assistant0.py` to add new capabilities
2. **Add Tools**: Integrate external APIs and services
3. **Improve the UI**: Customize the React components in `frontend/src/`
4. **Deploy to Production**: Follow the [DEPLOYMENT.md](DEPLOYMENT.md) guide
5. **Set up CI/CD**: Automate deployments with GitHub Actions
6. **Add Monitoring**: Set up alerts in Google Cloud Console

## 💡 Next Steps

Once everything is running:

1. **Customize the Agent**: Edit `backend/app/agents/assistant0.py` to add new capabilities
2. **Add Tools**: Integrate external APIs and services in `backend/app/agents/tools/`
3. **Improve the UI**: Customize React components in `frontend/src/`
4. **Deploy to Production**: Follow the [DEPLOYMENT.md](DEPLOYMENT.md) guide
5. **Switch LLM Providers**: See [GEMINI.md](GEMINI.md) for using Google Gemini models

## 📚 Additional Documentation

- **[README.md](README.md)** - Project overview and features
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Production deployment guide
- **[STRUCTURE.md](STRUCTURE.md)** - Architecture and file organization
- **[GEMINI.md](GEMINI.md)** - LLM provider guide (Gemini/OpenAI)

## 🔗 Getting Help

- [Auth0 Documentation](https://auth0.com/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [LangGraph Documentation](https://langchain-ai.github.io/langgraph/)
- [Firebase Studio Documentation](https://firebase.google.com/docs/studio)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [GitHub Issues](https://github.com/firebase-studio/community-templates/issues)
- [Auth0 Community](https://community.auth0.com/)
- [LangChain Discord](https://discord.gg/langchain)
