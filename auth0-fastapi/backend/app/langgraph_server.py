"""
LangGraph Server for Cloud Run deployment.
This server runs the LangGraph API with in-memory storage.

Based on langgraph-api which is used by `langgraph dev` command.
"""
import os
import sys
import json
from pathlib import Path
from dotenv import load_dotenv

try:
    # Get the project root directory (where langgraph.json is located)
    project_root = Path(__file__).parent.parent
    
    # Change to project root directory so relative imports work
    os.chdir(project_root)
    
    # Add project root to Python path so imports work
    sys.path.insert(0, str(project_root))
    
    # Also add dependencies directories if specified
    config_path = project_root / "langgraph.json"
    with open(config_path) as f:
        config = json.load(f)
    
    dependencies = config.get("dependencies", [])
    for dep in dependencies:
        dep_path = project_root / dep
        if dep_path.is_dir() and dep_path.exists():
            sys.path.append(str(dep_path))
    
    # Load environment variables
    # In production (Cloud Run), environment variables are already set via --set-env-vars
    # For local development, load from .env file if it exists
    env_file = config.get("env")
    if env_file:
        env_path = project_root / env_file
        if env_path.exists():
            print(f"Loading environment from {env_path}")
            # override=False means existing env vars (from Cloud Run) take precedence
            load_dotenv(env_path, override=False)
        else:
            print(f"Note: env file {env_path} not found (will use environment variables from runtime)")
    
    graphs = config.get("graphs", {})
    
    if __name__ == "__main__":
        # Import the server runner from langgraph-api
        # This is what `langgraph dev` uses internally
        from langgraph_api.cli import run_server
        
        port = int(os.environ.get("PORT", 54367))
        print(f"Starting LangGraph server on port {port}...")
        print(f"Loading configuration from {config_path}")
        print(f"Graphs: {graphs}")
        
        # Run the server with in-memory storage
        # This is the same as running `langgraph dev`
        run_server(
            host="0.0.0.0",
            port=port,
            reload=False,  # No hot reload in production
            graphs=graphs,
            n_jobs_per_worker=None,
            open_browser=False,
            debug_port=None,
            wait_for_client=False,
            studio_url=None,
            allow_blocking=True,  # Enable blocking operations for tools
            log_level="info",
        )
        
except Exception as e:
    print(f"Error starting LangGraph server: {e}", file=sys.stderr)
    import traceback
    traceback.print_exc()
    sys.exit(1)
