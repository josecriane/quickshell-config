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

      configName = "qsc";

      mkQuickshellConfigFor =
        system:
        let
          pkgs = nixpkgsFor.${system};
          quickshellPkg = quickshell.packages.${system}.default;

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
        in
        {
          commandsPath ? null,
          sessionCommandsPath ? null,
          interactiveCommandsPath ? null,
          stylix ? null,
          excludedAppsPath ? null,
          keepassPath ? null,
        }:
        pkgs.stdenv.mkDerivation {
          pname = "quickshell-config";
          # Track the input revision so the store-path version string reflects
          # the source. dirtyShortRev is set when the working tree has
          # uncommitted changes; "dev" covers non-git source contexts.
          version = self.shortRev or self.dirtyShortRev or "dev";

          src = ./.;

          nativeBuildInputs = [ pkgs.makeWrapper ];
          buildInputs = [
            quickshellPkg
            pkgs.material-symbols
          ];

          installPhase = ''
            configDir=$out/etc/xdg/quickshell/${configName}
            mkdir -p $configDir
            cp -r ds modules services shell $configDir/
            cp shell.qml $configDir/

            ${
              if stylix != null then
                ''
                    cat > $configDir/ds/Foundations.qml << 'EOF'
                  ${replaceStylixPlaceholders (builtins.readFile ./ds/Foundations.qml.template) stylix}
                  EOF
                ''
              else
                ''
                  if [ -f ds/Foundations.qml ]; then
                    cp ds/Foundations.qml $configDir/ds/
                  else
                    echo "ERROR: stylix is not configured and ds/Foundations.qml is not present." >&2
                    exit 1
                  fi
                ''
            }

            ${
              if commandsPath != null then
                ''cp ${commandsPath} $configDir/commands.json''
              else
                ''
                  if [ -f commands.json ]; then
                    cp commands.json $configDir/commands.json
                  else
                    echo '{"commands":[]}' > $configDir/commands.json
                  fi
                ''
            }

            ${
              if sessionCommandsPath != null then
                ''cp ${sessionCommandsPath} $configDir/session-commands.json''
              else
                ''
                  if [ -f session-commands.json ]; then
                    cp session-commands.json $configDir/session-commands.json
                  else
                    echo '{"commands":[]}' > $configDir/session-commands.json
                  fi
                ''
            }

            ${
              if interactiveCommandsPath != null then
                ''cp ${interactiveCommandsPath} $configDir/interactive-commands.json''
              else
                ''
                  if [ -f interactive-commands.json ]; then
                    cp interactive-commands.json $configDir/interactive-commands.json
                  else
                    echo '{"commands":[]}' > $configDir/interactive-commands.json
                  fi
                ''
            }

            ${
              if excludedAppsPath != null then
                ''cp ${excludedAppsPath} $configDir/excluded-apps.json''
              else
                ''
                  if [ -f excluded-apps.json ]; then
                    cp excluded-apps.json $configDir/excluded-apps.json
                  else
                    echo '{"excludedApps":[]}' > $configDir/excluded-apps.json
                  fi
                ''
            }

            ${
              if keepassPath != null then
                ''cp ${keepassPath} $configDir/keepass.json''
              else
                ''
                  if [ -f keepass.json ]; then
                    cp keepass.json $configDir/keepass.json
                  else
                    echo '{}' > $configDir/keepass.json
                  fi
                ''
            }

            mkdir -p $out/bin

            mkdir -p $out/share/fonts
            ln -s ${pkgs.material-symbols}/share/fonts/truetype $out/share/fonts/

            # Instances are keyed by md5 of the resolved shell.qml path, so
            # selecting the config by store path yields a new key on every
            # rebuild. --config ${configName} lets a stable XDG_CONFIG_HOME
            # entry win instead; this store dir is only the fallback.
            makeWrapper ${quickshellPkg}/bin/quickshell $out/bin/quickshell-config \
              --add-flags "--config ${configName}" \
              --prefix QML2_IMPORT_PATH : "${quickshellPkg}/lib/qt-6/qml" \
              --prefix PATH : "${
                pkgs.lib.makeBinPath [
                  pkgs.cliphist
                  pkgs.wl-clipboard
                ]
              }" \
              --prefix XDG_DATA_DIRS : "$out/share:${pkgs.material-symbols}/share" \
              --prefix XDG_CONFIG_DIRS : "$out/etc/xdg"

            install -Dm755 bin/qs-ipc $out/bin/qs-ipc
            substituteInPlace $out/bin/qs-ipc \
              --replace-fail @QUICKSHELL_CONFIG@ $out/bin/quickshell-config

            install -Dm755 bin/qs-toggle-launcher $out/bin/qs-toggle-launcher
            substituteInPlace $out/bin/qs-toggle-launcher \
              --replace-fail @QS_IPC@ $out/bin/qs-ipc
          '';

          meta = with pkgs.lib; {
            description = "Personal QuickShell configuration";
            platforms = platforms.linux;
          };
        };
    in
    {
      # Per-system factory exposed under `lib`. Functions cannot live under
      # `packages.<system>` because the flake schema rejects non-derivations
      # there, which is also what makes `nix flake check` usable.
      lib = forAllSystems (system: {
        mkQuickshellConfig = mkQuickshellConfigFor system;
      });

      packages = forAllSystems (system: rec {
        default = quickshell-config;
        quickshell-config = mkQuickshellConfigFor system { };
      });

      checks = forAllSystems (system: {
        build = self.packages.${system}.default;
      });

      homeManagerModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.programs.quickshell-config;
          mkPath =
            description:
            lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              inherit description;
            };
        in
        {
          options.programs.quickshell-config = {
            enable = lib.mkEnableOption "quickshell-config";

            commandsPath = mkPath "Path to commands.json (one-shot launcher commands).";
            sessionCommandsPath = mkPath "Path to session-commands.json (lock, reboot, poweroff).";
            interactiveCommandsPath = mkPath "Path to interactive-commands.json (calculator, base64, shell).";
            excludedAppsPath = mkPath "Path to excluded-apps.json (desktop entries hidden from the launcher).";
            keepassPath = mkPath "Path to keepass.json (database, age identity and encrypted password).";

            stylix = lib.mkOption {
              type = lib.types.nullOr (lib.types.attrsOf lib.types.anything);
              default = null;
              description = ''
                base16 palette plus monoFont and sansFont, used to render
                ds/Foundations.qml from its template. Null falls back to the
                Foundations.qml committed in the source tree.
              '';
            };

            package = lib.mkOption {
              type = lib.types.package;
              readOnly = true;
              description = ''
                The built derivation, so other modules can point keybinds at
                the same one this module installs. Set the options above to
                influence what it contains.
              '';
              default = self.lib.${pkgs.stdenv.hostPlatform.system}.mkQuickshellConfig {
                inherit (cfg)
                  commandsPath
                  sessionCommandsPath
                  interactiveCommandsPath
                  excludedAppsPath
                  keepassPath
                  stylix
                  ;
              };
            };
          };

          config = lib.mkIf cfg.enable {
            home.packages = [ cfg.package ];
          };
        };

      overlays.default = final: prev: {
        quickshell-config = self.packages.${final.stdenv.hostPlatform.system}.quickshell-config;
      };
    };
}
