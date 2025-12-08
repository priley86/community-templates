# To learn more about how to use Nix to configure your environment
# see: https://developers.google.com/idx/guides/customize-idx-env
{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "unstable";
  
  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.python313
    pkgs.uv
    pkgs.pipx
    pkgs.nodejs_22
  ];
  
  # Sets environment variables in the workspace
  env = {
    # Set Python to use Python 3.13 from nix
    PYTHON = "${pkgs.python313}/bin/python3";
    
    # Increase UV HTTP timeout for slower network connections
    UV_HTTP_TIMEOUT = "120";
    
    # Backend base URL (where the FastAPI server runs)
    # Frontend URL since Vite proxies /api to backend
    APP_BASE_URL = "https://9000-$WEB_HOST";
    
    # LangGraph server URL
    LANGGRAPH_API_URL = "http://localhost:54367";
    
    # Backend API URL for frontend and Vite proxy
    VITE_API_URL = "http://localhost:8000";
    
    # Frontend URL for CORS
    FRONTEND_HOST = "https://9000-$WEB_HOST";
    
    # Backend CORS origins
    BACKEND_CORS_ORIGINS = "https://9000-$WEB_HOST";
  };
  
  idx = {
    # Search for the extensions you want on https://open-vsx.org/ and use "publisher.id"
    extensions = [
      "ms-python.python"
      "ms-python.vscode-pylance"
      "dbaeumer.vscode-eslint"
      "esbenp.prettier-vscode"
    ];
    
    # Enable previews
    previews = {
      enable = true;
      previews = {
        # Frontend preview on port 9000 (matches APP_BASE_URL and CORS config)
        web = {
          command = ["npm" "run" "dev" "--" "--port" "9000" "--host" "0.0.0.0"];
          manager = "web";
          cwd = "frontend";
          env = {
            PORT = "9000";
          };
        };
      };
    };
    
    # Workspace lifecycle hooks
    workspace = {
      # Runs when a workspace is first created
      onCreate = {
        # Copy environment files
        copy-backend-env = "cp backend/.env.example backend/.env && cp backend/.env.production.example backend/.env.production";
        copy-frontend-env = "cp frontend/.env.example frontend/.env && cp frontend/.env.production.example frontend/.env.production";
        
        # Install frontend dependencies
        npm-install = "cd frontend && npm install";
        
        # Install backend dependencies
        backend-setup = "cd backend && uv sync";
        
        # Open editors for the following files by default, if they exist:
        default.openFiles = [ 
          ".idx/dev.nix" 
          "README.md" 
          "backend/app/main.py"
          "frontend/src/main.tsx"
        ];
      };
      
      # Runs when the workspace is (re)started
      onStart = {
        # Start the backend FastAPI server
        start-backend = "cd backend && uv run fastapi dev app/main.py --host 0.0.0.0 --port 8000";
        
        # Start the LangGraph server
        start-langgraph = "cd backend && uv run langgraph dev --port 54367 --host 0.0.0.0 --no-browser --allow-blocking";
      };
    };
  };
}
