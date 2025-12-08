{ pkgs, ... }: {
  channel = "unstable";
  packages = [
    pkgs.python313
    pkgs.uv
    pkgs.pipx
    pkgs.nodejs_22
  ];
  
  env = {
    PYTHON = "${pkgs.python313}/bin/python3";
    UV_HTTP_TIMEOUT = "120";
  };
  
  bootstrap = ''    
    mkdir "$out"
    mkdir -p "$out/.idx/"
    cp -rf ${./.idx/dev.nix} "$out/.idx/dev.nix"
    
    # Copy all project files
    shopt -s dotglob
    for file in ${./.}/*; do
      if [ "$(basename "$file")" != "idx-template.nix" ] && [ "$(basename "$file")" != "idx-template.json" ]; then
        cp -r "$file" "$out/"
      fi
    done
    
    chmod -R +w "$out"
    
    # Make scripts executable
    find "$out" -type f -name "*.sh" -exec chmod +x {} \;
  '';
}
