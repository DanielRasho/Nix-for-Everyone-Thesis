{
  description = "A nixty survey";

  inputs = {
    default-pkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    #moonInput.url = "github:moonrepo/moon";
  };

  outputs = { self, default-pkgs }: let

      # SUPPORTED SYSTEMS
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      
      forAllSystems = default-pkgs.lib.genAttrs supportedSystems;

      nixpkgsFor = system : pkgs : import pkgs {
        inherit system;
        config.allowUnfree = true;
      };
    
  in
  {
    devShells = forAllSystems ( system: 
      let 
        defaultPkgs = nixpkgsFor system default-pkgs ;
        #moonPkg = moonInput.packages.${system}.default;
      in 
      {
        default = defaultPkgs.mkShell {
          # process-compose would otherwise load compose.yml (the docker file) first
          PC_CONFIG_FILES = "process-compose.yaml";

          packages = with defaultPkgs; [
            # task managers
            moon
            process-compose
            # - Go - main language
            go 
            gopls 
            gotools 
            air
            # - NODE - for running tests
            nodejs 
            pnpm 
            # - Process orchestration
            process-compose

            coreutils

            # SQL Generation
            sqlc
          ];
        };
      }
    ); 
  };
}