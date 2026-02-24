{
  description = "QuickShell Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      quickshell,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];

      nixpkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
        }
      );
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
          quickshellPkg = quickshell.packages.${system}.default;

          # Function to replace Stylix placeholders in QML files (similar to stylix-css)
          replaceStylixPlaceholders =
            content: stylix:
            if stylix == null then
              content
            else
              builtins.replaceStrings
                [
                  "@base00@"
                  "@base01@"
                  "@base02@"
                  "@base03@"
                  "@base04@"
                  "@base05@"
                  "@base06@"
                  "@base07@"
                  "@base08@"
                  "@base09@"
                  "@base0A@"
                  "@base0B@"
                  "@base0C@"
                  "@base0D@"
                  "@base0E@"
                  "@base0F@"
                  "@monoFont@"
                  "@sansFont@"
                ]
                [
                  stylix.base00
                  stylix.base01
                  stylix.base02
                  stylix.base03
                  stylix.base04
                  stylix.base05
                  stylix.base06
                  stylix.base07
                  stylix.base08
                  stylix.base09
                  stylix.base0A
                  stylix.base0B
                  stylix.base0C
                  stylix.base0D
                  stylix.base0E
                  stylix.base0F
                  (stylix.monoFont)
                  (stylix.sansFont)
                ]
                content;

          # Function to create quickshell config with optional commands files
          mkQuickshellConfig =
            {
              commandsPath ? null,
              sessionCommandsPath ? null,
              interactiveCommandsPath ? null,
              stylix ? null,
              excludedAppsPath ? null,
            }:
            pkgs.stdenv.mkDerivation rec {
              pname = "quickshell-config";
              version = "0.1.0";

              src = ./.;

              nativeBuildInputs = [ pkgs.makeWrapper ];
              buildInputs = [
                quickshellPkg
                pkgs.material-symbols
              ];

              installPhase = ''
                # Copy all configuration files
                mkdir -p $out/share/quickshell-config
                cp -r ds modules services shell $out/share/quickshell-config/ 2>/dev/null || true
                cp shell.qml $out/share/quickshell-config/

                # Process Foundations.qml with Stylix replacement if available
                ${
                  if stylix != null then
                    ''
                        # Use template and replace placeholders
                        cat > $out/share/quickshell-config/ds/Foundations.qml << 'EOF'
                      ${replaceStylixPlaceholders (builtins.readFile ./ds/Foundations.qml.template) stylix}
                      EOF
                    ''
                  else
                    ''
                      # Use original Foundations.qml as fallback
                      [ -f ds/Foundations.qml ] && cp ds/Foundations.qml $out/share/quickshell-config/ds/
                    ''
                }

                # Copy JSON files (use provided paths or default from source)
                ${
                  if commandsPath != null then
                    ''cp ${commandsPath} $out/share/quickshell-config/commands.json''
                  else
                    ''
                      if [ -f commands.json ]; then
                        cp commands.json $out/share/quickshell-config/commands.json
                      else
                        echo '{"commands":[]}' > $out/share/quickshell-config/commands.json
                      fi
                    ''
                }

                ${
                  if sessionCommandsPath != null then
                    ''cp ${sessionCommandsPath} $out/share/quickshell-config/session-commands.json''
                  else
                    ''
                      if [ -f session-commands.json ]; then
                        cp session-commands.json $out/share/quickshell-config/session-commands.json
                      else
                        echo '{"commands":[]}' > $out/share/quickshell-config/session-commands.json
                      fi
                    ''
                }

                ${
                  if interactiveCommandsPath != null then
                    ''cp ${interactiveCommandsPath} $out/share/quickshell-config/interactive-commands.json''
                  else
                    ''
                      if [ -f interactive-commands.json ]; then
                        cp interactive-commands.json $out/share/quickshell-config/interactive-commands.json
                      else
                        echo '{"commands":[]}' > $out/share/quickshell-config/interactive-commands.json
                      fi
                    ''
                }

                ${
                  if excludedAppsPath != null then
                    ''cp ${excludedAppsPath} $out/share/quickshell-config/excluded-apps.json''
                  else
                    ''
                      if [ -f excluded-apps.json ]; then
                        cp excluded-apps.json $out/share/quickshell-config/excluded-apps.json
                      else
                        echo '{"excludedApps":[]}' > $out/share/quickshell-config/excluded-apps.json
                      fi
                    ''
                }

                # Create wrapper scripts
                mkdir -p $out/bin

                # Create fonts directory and symlink the fonts
                mkdir -p $out/share/fonts
                ln -s ${pkgs.material-symbols}/share/fonts/TTF $out/share/fonts/

                # Main quickshell wrapper
                makeWrapper ${quickshellPkg}/bin/quickshell $out/bin/quickshell-config \
                  --add-flags "--config $out/share/quickshell-config" \
                  --prefix QML2_IMPORT_PATH : "${quickshellPkg}/lib/qt-6/qml" \
                  --prefix XDG_DATA_DIRS : "$out/share:${pkgs.material-symbols}/share"

                # Launcher toggle script
                cat > $out/bin/qs-toggle-launcher << EOF
                #!/usr/bin/env bash
                ${quickshellPkg}/bin/quickshell -c $out/share/quickshell-config ipc call drawers toggle launcher
                EOF
                chmod +x $out/bin/qs-toggle-launcher
              '';

              meta = with pkgs.lib; {
                description = "Personal QuickShell configuration";
                platforms = platforms.linux;
              };
            };
        in
        {
          default = self.packages.${system}.quickshell-config;

          quickshell-config = mkQuickshellConfig { };

          # Function to create config with custom commands
          withCommands = commandsPath: mkQuickshellConfig { inherit commandsPath; };

          # Function to create config with both commands and session commands
          withAllCommands =
            {
              commandsPath ? null,
              sessionCommandsPath ? null,
              interactiveCommandsPath ? null,
              stylix ? null,
              excludedAppsPath ? null,
            }:
            mkQuickshellConfig {
              inherit
                commandsPath
                sessionCommandsPath
                interactiveCommandsPath
                stylix
                excludedAppsPath
                ;
            };
        }
      );

      # Home Manager module
      homeManagerModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          options.programs.quickshell-config = {
            enable = lib.mkEnableOption "quickshell-config";
          };

          config = lib.mkIf config.programs.quickshell-config.enable {
            home.packages = [ self.packages.${pkgs.system}.quickshell-config ];
          };
        };

      # Overlay for easier integration
      overlays.default = final: prev: {
        quickshell-config = self.packages.${final.system}.quickshell-config;
      };
    };
}
