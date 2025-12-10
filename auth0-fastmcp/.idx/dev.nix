# To learn more about how to use Nix to configure your environment
# see: https://firebase.google.com/docs/studio/devnix-reference
{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "unstable";
  
  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.python313
    pkgs.poetry
    pkgs.nodejs_22
  ];
  
  # Sets environment variables in the workspace
  env = {
    # Set Python to use Python 3.13 from nix
    PYTHON = "${pkgs.python313}/bin/python3";
  };
  
  idx = {
    # Search for the extensions you want on https://open-vsx.org/ and use "publisher.id"
    extensions = [
      "ms-python.python"
      "ms-python.vscode-pylance"
    ];
    
    # Enable previews
    previews = {
      enable = true;
      previews = {
        # Landing page with cURL commands
        web = {
          command = ["python" "-m" "http.server" "$PORT" "--directory" ".idx"];
          manager = "web";
        };
      };
    };
    
    # Workspace lifecycle hooks
    workspace = {
      # Runs when a workspace is first created
      onCreate = {
        # Copy environment file
        copy-env = "cp .env.example .env";
        
        # Install dependencies using poetry
        install-deps = "poetry install";
        
        # Open editors for the following files by default, if they exist:
        default.openFiles = [
          "README.md"
        ];
      };
      
      # Runs when the workspace is (re)started
      onStart = {
        # Start MCP server on port 3001
        start-mcp-server = "poetry run python -m src.server";
      };
    };
  };
}
