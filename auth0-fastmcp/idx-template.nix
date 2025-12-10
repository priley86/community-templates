{ pkgs, ... }: {
  channel = "unstable";
  packages = [
    pkgs.python313
    pkgs.poetry
  ];
  
  env = {
    PYTHON = "${pkgs.python313}/bin/python3";
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
