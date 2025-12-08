# Auth0 + Firebase + FastAPI + LangChain Starter

An AI personal assistant template secured with Auth0, built on Firebase Studio (Project IDX), using FastAPI, LangGraph, and Vite/React.

[![Open in IDX](https://cdn.idx.dev/btn/open_dark_32@2x.png)](https://idx.google.com/new?template=https://github.com/firebase-studio/community-templates/tree/main/auth0-fastapi)

## About

This template provides a full-stack AI application starter with:

- **[Auth0](https://auth0.com/)** for authentication and authorization
- **[FastAPI](https://fastapi.tiangolo.com/)** for the backend API
- **[LangChain](https://python.langchain.com/)** and **[LangGraph](https://langchain-ai.github.io/langgraph/)** for building AI agents
- **Flexible LLM support** - easily swap between **[Google Gemini](https://ai.google.dev/)** (default) and **[OpenAI](https://openai.com/)** models
- **[Vite](https://vite.dev/)** + **[React](https://react.dev/)** for the frontend
- **[Firebase Studio (Project IDX)](https://idx.google.com/)** for the development environment

## Features

- 🔐 **Secure Authentication** with Auth0 FastAPI SDK
- 🤖 **AI-Powered Chat** using LangGraph agents (supports Google Gemini & OpenAI)
- 🔌 **Third-Party API Integration** via Auth0 AI SDK (Token Vault)
- 🚀 **Fast Development** with hot reload on frontend and backend
- 📦 **Modern Stack** with TypeScript, Python 3.13+, React 19, and Tailwind CSS 4
- 🎨 **Beautiful UI** with shadcn/ui components
- 🔧 **Easy Setup** with Firebase Studio (Project IDX)

## Architecture

The project is divided into three main parts:

```
.
├── backend/           # FastAPI backend
│   ├── app/
│   │   ├── agents/    # LangGraph agent definitions
│   │   ├── api/       # API routes
│   │   ├── core/      # Core configurations
│   │   └── main.py    # FastAPI application
│   ├── pyproject.toml
│   └── .env.example
├── frontend/          # Vite + React frontend
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── lib/
│   │   └── main.tsx
│   ├── package.json
│   └── .env.example
└── .idx/
    └── dev.nix        # Firebase Studio configuration
```

## Getting Started

### Prerequisites

- An [Auth0](https://auth0.com/) account with a Web Application configured
- An LLM API key:
  - **[Google AI API key](https://aistudio.google.com/app/apikey)** for Gemini models (default), OR
  - **[OpenAI API key](https://platform.openai.com/api-keys)** for GPT models
- A [Firebase Studio (Project IDX)](https://idx.google.com/) workspace (or local development environment)
- (Optional) Google Calendar API credentials if using the calendar tool

> **Note**: This template supports both Google Gemini and OpenAI models. The default configuration uses Google Gemini's `gemini-2.0-flash-exp`. To switch to OpenAI models, see `GEMINI.md` for detailed instructions.

### Quick Start with Firebase Studio (Project IDX)

1. Click the "Open in IDX" button above
2. Wait for the workspace to initialize (dependencies will be installed automatically)
3. Configure your environment variables (see below)
4. The servers will start automatically!

> **⚠️ Important for Firebase Studio users**: The embedded "Web" preview window may show authentication errors due to third-party cookie blocking. **Always use the "Preview" button or "Open in new tab" button** (↗️) to open the application in a full browser tab where authentication will work correctly.

See the **[SETUP.md](SETUP.md)** for further instructions about setup with Auth0 and local testing with Firebase Studio.

## Project Structure

### Backend

- `app/agents/` - LangGraph agent definitions and workflows
- `app/api/routes/` - FastAPI route handlers
- `app/core/` - Configuration, authentication, and shared utilities
- `app/main.py` - FastAPI application entry point

### Frontend

- `src/components/` - Reusable React components
- `src/pages/` - Page components
- `src/lib/` - Utility functions and API clients
- `src/main.tsx` - React application entry point

## Customization

### Modifying the AI Agent

The LangGraph agent is defined in `backend/app/agents/assistant0.py`. You can:

- Change the system prompt in the `get_prompt()` function
- Add new tools in `backend/app/agents/tools/`
- Switch between LLM providers (Gemini/OpenAI) and models (see GEMINI.md)
- Modify the agent's reasoning approach (ReAct, Planning, etc.)

### Styling the Frontend

The frontend uses Tailwind CSS. You can customize:

- `frontend/tailwind.config.js` - Tailwind configuration
- `frontend/src/components/` - Component styles
- Theme colors and typography

## Deployment

This template includes production-ready deployment scripts for Google Cloud Run.

### 📚 Documentation

- **[SETUP.md](SETUP.md)** - Initial setup and local development
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Production deployment guide

### 🌐 Architecture

- **Backend Services**: Google Cloud Run (auto-scaling containers)
- **Frontend**: Firebase Hosting (global CDN)
- **Alternative Platforms**: AWS Lambda, Vercel, Netlify, LangGraph Cloud

## Learn More

- [Auth0 Documentation](https://auth0.com/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [LangChain Documentation](https://python.langchain.com/)
- [LangGraph Documentation](https://langchain-ai.github.io/langgraph/)
- [Firebase Studio Documentation](https://firebase.google.com/docs/studio)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

This template is inspired by the [Auth0 AI Samples](https://github.com/auth0-samples/auth0-ai-samples) and adapted for Firebase Studio (Project IDX).

## Support

For issues and questions:
- [GitHub Issues](https://github.com/firebase-studio/community-templates/issues)
- [Auth0 Community](https://community.auth0.com/)
- [LangChain Discord](https://discord.gg/langchain)
