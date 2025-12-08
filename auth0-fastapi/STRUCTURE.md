# Project Structure

This document provides an overview of the project structure and explains the purpose of each directory and key files.

## Root Directory

```
auth0-fastapi/
├── .idx/                      # Firebase Studio (Project IDX) configuration
│   └── dev.nix               # Development environment configuration
├── backend/                   # Python FastAPI backend
├── frontend/                  # React + Vite frontend
├── .gitignore                # Git ignore rules
├── CONTRIBUTING.md           # Contribution guidelines
├── dev.nix                   # NIX configuration for template bootstrap
├── idx-template.json         # Template metadata for Firebase Studio
├── idx-template.nix          # Template bootstrap script
├── LICENSE                   # MIT License
├── README.md                 # Main documentation
└── SETUP.md                  # Setup instructions
```

## Backend Structure

```
backend/
├── app/
│   ├── agents/               # LangGraph agent definitions
│   │   ├── __init__.py
│   │   ├── assistant0.py     # Main AI assistant agent (using Gemini)
│   │   └── tools/            # Agent tools
│   │       ├── __init__.py
│   │       └── google_calendar.py  # Google Calendar integration tool
│   ├── api/                  # API routes and routers
│   │   ├── __init__.py
│   │   ├── api_router.py     # Main API router
│   │   └── routes/
│   │       ├── __init__.py
│   │       ├── chat.py       # Chat/agent proxy endpoint
│   │       └── profile.py    # User profile endpoint
│   ├── core/                 # Core configurations
│   │   ├── __init__.py
│   │   ├── auth.py           # Auth0 SDK routes and client
│   │   ├── auth0_ai.py       # Auth0 AI SDK integration
│   │   └── config.py         # Application settings
│   ├── __init__.py
│   └── main.py               # FastAPI application entry point
├── .env.example              # Example environment variables
├── .gitignore               # Backend-specific git ignore
├── langgraph.json           # LangGraph configuration
├── pyproject.toml           # Python dependencies (uv)
├── uv.lock                  # Locked dependency versions
└── README.md                # Backend documentation
```

## Frontend Structure

```
frontend/
├── public/                   # Static assets
│   └── images/
│       ├── arch-bg.png      # Architecture background
│       ├── auth0-logo.svg   # Auth0 logo
│       ├── favicon.png      # Favicon
│       └── home-page.png    # Home page screenshot
├── src/
│   ├── components/           # Reusable React components
│   │   ├── auth0/           # Auth0 components
│   │   │   └── user-button.tsx  # User dropdown menu
│   │   ├── auth0-ai/        # Auth0 AI SDK components
│   │   │   ├── TokenVault/  # Token Vault for third-party API auth
│   │   │   └── util/        # Auth0 AI utilities
│   │   ├── guide/           # Guide components
│   │   │   └── guide-info-box.tsx  # Info box for instructions
│   │   ├── ui/              # shadcn/ui components
│   │   │   ├── avatar.tsx
│   │   │   ├── button.tsx
│   │   │   ├── dropdown-menu.tsx
│   │   │   └── ... (other UI components)
│   │   ├── chat-message-bubble.tsx  # Individual chat message
│   │   ├── chat-window.tsx          # Chat interface container
│   │   ├── layout.tsx               # App layout with header
│   │   ├── memoize-markdown.tsx     # Memoized markdown renderer
│   │   ├── navbar.tsx               # Navigation with active links
│   │   └── TokenVaultInterruptHandler.tsx  # Handles token vault flows
│   ├── lib/                  # Utility functions
│   │   ├── api-client.ts    # Axios API client
│   │   ├── use-auth.ts      # Authentication hook
│   │   └── utils.ts         # Helper functions (cn, etc.)
│   ├── pages/                # Page components
│   │   ├── ChatPage.tsx     # Main chat interface
│   │   └── ClosePage.tsx    # OAuth popup close handler
│   ├── global.css            # Global Tailwind styles
│   ├── main.tsx              # Application entry point (React Router)
│   └── vite-env.d.ts         # TypeScript environment definitions
├── .env.example              # Example environment variables
├── .gitignore               # Frontend-specific git ignore
├── components.json          # shadcn/ui configuration
├── eslint.config.js         # ESLint configuration
├── index.html               # HTML template
├── package.json             # npm dependencies
├── package-lock.json        # Locked npm dependencies
├── README.md                # Frontend documentation
├── tailwind.config.js       # Tailwind CSS configuration
├── tsconfig.json            # TypeScript configuration
├── tsconfig.app.json        # App-specific TypeScript config
├── tsconfig.node.json       # Node-specific TypeScript config
└── vite.config.ts           # Vite configuration
```

## Key Files Explained

### Template Files

- **`idx-template.json`**: Defines the template metadata for Firebase Studio (name, description, categories)
- **`idx-template.nix`**: Bootstrap script that sets up the project when creating a new workspace
- **`dev.nix`**: NIX configuration for the development environment (packages, environment variables, lifecycle hooks)
- **`.idx/dev.nix`**: Copy of dev.nix placed in the workspace for customization

### Backend Files

- **`backend/app/main.py`**: FastAPI application with CORS, Auth0 middleware, and API routes
- **`backend/app/core/config.py`**: Application settings loaded from environment variables
- **`backend/app/core/auth.py`**: Auth0 FastAPI SDK routes and client configuration
- **`backend/app/core/auth0_ai.py`**: Auth0 AI SDK integration for calling third-party APIs on behalf of users
- **`backend/app/api/api_router.py`**: Main API router combining all route modules
- **`backend/app/api/routes/chat.py`**: Proxy endpoint that forwards authenticated requests to LangGraph
- **`backend/app/api/routes/profile.py`**: User profile endpoint returning authenticated user info
- **`backend/app/agents/assistant0.py`**: LangGraph agent using Gemini (via OpenAI-compatible interface)
- **`backend/app/agents/tools/google_calendar.py`**: Google Calendar tool for the agent
- **`backend/langgraph.json`**: Configuration file telling LangGraph which agents to expose
- **`backend/pyproject.toml`**: Python dependencies managed by `uv`
- **`backend/uv.lock`**: Locked dependency versions for reproducible builds

### Frontend Files

- **`frontend/src/main.tsx`**: React app entry point with React Router, React Query, and NuqsAdapter
- **`frontend/src/components/layout.tsx`**: App layout with header, navigation, and Auth0 user button
- **`frontend/src/components/auth0/user-button.tsx`**: User dropdown menu with avatar and logout
- **`frontend/src/components/chat-window.tsx`**: Reusable chat interface component with streaming support
- **`frontend/src/components/chat-message-bubble.tsx`**: Individual chat message with markdown rendering
- **`frontend/src/components/auth0-ai/TokenVault/`**: Components for OAuth connections to third-party APIs
- **`frontend/src/components/TokenVaultInterruptHandler.tsx`**: Handles interruptions for token vault flows
- **`frontend/src/components/navbar.tsx`**: Navigation component with active link highlighting
- **`frontend/src/components/guide/guide-info-box.tsx`**: Info box component for displaying instructions
- **`frontend/src/components/ui/`**: shadcn/ui component library (button, avatar, dropdown, etc.)
- **`frontend/src/lib/use-auth.ts`**: Custom hook for authentication state and auth URL generation
- **`frontend/src/lib/api-client.ts`**: Axios client for API requests with credentials
- **`frontend/src/pages/ChatPage.tsx`**: Main chat page with login/signup flow
- **`frontend/src/pages/ClosePage.tsx`**: Page that auto-closes OAuth popup windows
- **`frontend/vite.config.ts`**: Vite configuration with Tailwind and path aliases
- **`frontend/tailwind.config.js`**: Tailwind CSS configuration with custom theme
- **`frontend/components.json`**: shadcn/ui CLI configuration
- **`frontend/package.json`**: npm dependencies including React, LangGraph SDK, Auth0 AI, shadcn/ui, and more

## Technology Stack

### Backend
- **FastAPI**: Modern Python web framework
- **LangGraph**: Framework for building AI agents
- **Auth0 FastAPI SDK**: Authentication middleware and routes
- **Auth0 AI SDK**: Integration for calling third-party APIs on behalf of users
- **Google Gemini**: LLM provider (default, via langchain-google-genai)
- **langchain-google-genai**: LangChain integration for Gemini models
- **langchain-openai**: LangChain integration for OpenAI models (optional)
- **uv**: Fast Python package manager

### Frontend
- **React 19**: UI library
- **Vite 7**: Fast build tool
- **TypeScript 5.8**: Type-safe JavaScript
- **Tailwind CSS 4**: Utility-first CSS framework
- **shadcn/ui**: Beautiful, accessible UI components
- **React Router 7**: Client-side routing
- **TanStack Query 5**: Data fetching and caching
- **LangGraph SDK**: Client for streaming agent responses
- **Auth0 AI React**: Components for third-party API authentication
- **nuqs**: Type-safe URL search params
- **React Markdown**: Markdown rendering
- **Lucide React**: Icon library

### Development Environment
- **NIX**: Reproducible development environments
- **Firebase Studio (Project IDX)**: Cloud-based development

## Development Workflow

1. **Firebase Studio (Project IDX)**: Click "Open in IDX" → workspace initializes → servers start automatically
2. **Local Development**: 
   - Start backend: `cd backend && uv sync && fastapi dev app/main.py`
   - Start LangGraph: `cd backend && langgraph dev --port 54367 --allow-blocking`
   - Start frontend: `cd frontend && npm install && npm run dev`

## Environment Variables

### Backend (`backend/.env`)
- Auth0 credentials (domain, client ID, secret)
- Google AI API key (or OpenAI API key)
- Application URLs
- CORS origins

### Frontend (`frontend/.env`)
- Auth0 credentials (domain, client ID)
- Backend API URL

## Data Flow

1. **User → Frontend**: User types message in chat
2. **Frontend → Backend**: Authenticated request to `/api/agent/*` (via `/api/user/profile` for auth check)
3. **Backend**: Auth0 FastAPI SDK validates session and user
4. **Backend → LangGraph**: Proxied request with user credentials in `config.configurable._credentials`
5. **LangGraph → Agent**: assistant0 agent processes message
6. **Agent → Gemini**: LLM call via langchain-google-genai
7. **Agent → Tools**: May call tools (e.g., Google Calendar) on behalf of user via Auth0 AI SDK
8. **Gemini → Agent**: Response generated
9. **Agent → LangGraph**: Response with tool results
10. **LangGraph → Backend**: Streamed response
11. **Backend → Frontend**: Streamed response
12. **Frontend → User**: Rendered message with markdown (via ReactMarkdown)

## Customization Points

- **Agent Logic**: `backend/app/agents/assistant0.py` - Modify prompt, add tools, change LLM model
- **Agent Tools**: `backend/app/agents/tools/` - Add new tools for your agent
- **API Routes**: `backend/app/api/routes/` - Add new endpoints
- **Third-Party API Integration**: `backend/app/core/auth0_ai.py` - Configure Auth0 AI SDK
- **Frontend UI**: `frontend/src/components/` and `frontend/src/pages/` - Customize layout and pages
- **UI Components**: `frontend/src/components/ui/` - Modify or add shadcn/ui components
- **Styling**: Tailwind classes in React components and `tailwind.config.js`
- **Development Environment**: `.idx/dev.nix` - Adjust NIX configuration
- **LLM Model**: Change `model` parameter in `assistant0.py` (e.g., `gemini-1.5-pro`, `gpt-4o-mini`)
