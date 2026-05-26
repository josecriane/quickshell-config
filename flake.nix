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

      mkQuickshellConfigFor =
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
              # Track the input revision so the store-path version string
              # actually reflects the source. `dirtyShortRev` is set when
              # the working tree has uncommitted changes; "dev" is the
              # last-resort fallback for non-git source contexts.
              version = self.shortRev or self.dirtyShortRev or "dev";

              src = ./.;

              nativeBuildInputs = [ pkgs.makeWrapper ];
              buildInputs = [
                quickshellPkg
                pkgs.material-symbols
              ];

              installPhase = ''
                # Install QML tree under quickshell's named-config search path
                # (XDG config dir, per `quickshell --help`). Selecting the config
                # by name ("qsc") instead of by store path means IPC callers
                # built from a different generation can still talk to the
                # running instance.
                configDir=$out/etc/xdg/quickshell/qsc
                mkdir -p $configDir
                cp -r ds modules services shell data $configDir/
                cp shell.qml $configDir/

                # Process Foundations.qml with Stylix replacement if available
                ${
                  if stylix != null then
                    ''
                        # Use template and replace placeholders
                        cat > $configDir/ds/Foundations.qml << 'EOF'
                      ${replaceStylixPlaceholders (builtins.readFile ./ds/Foundations.qml.template) stylix}
                      EOF
                    ''
                  else
                    ''
                      # No stylix passed: fall back to a checked-in Foundations.qml.
                      # Fail loudly if neither is available — silently producing a
                      # broken package is worse than a build error.
                      if [ -f ds/Foundations.qml ]; then
                        cp ds/Foundations.qml $configDir/ds/
                      else
                        echo "ERROR: stylix is not configured and ds/Foundations.qml is not present." >&2
                        echo "  Either pass a stylix configuration to mkQuickshellConfig," >&2
                        echo "  or commit a non-template ds/Foundations.qml as a fallback." >&2
                        exit 1
                      fi
                    ''
                }

                # Copy JSON files (use provided paths or default from source)
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

                # Create wrapper scripts
                mkdir -p $out/bin

                # Create fonts directory and symlink the fonts
                mkdir -p $out/share/fonts
                ln -s ${pkgs.material-symbols}/share/fonts/truetype $out/share/fonts/

                # Main quickshell wrapper. --config qsc selects the named
                # config installed under $out/etc/xdg/quickshell/qsc/, which
                # is reachable via XDG_CONFIG_DIRS.
                makeWrapper ${quickshellPkg}/bin/quickshell $out/bin/quickshell-config \
                  --add-flags "--config qsc" \
                  --prefix QML2_IMPORT_PATH : "${quickshellPkg}/lib/qt-6/qml" \
                  --prefix XDG_DATA_DIRS : "$out/share:${pkgs.material-symbols}/share" \
                  --prefix XDG_CONFIG_DIRS : "$out/etc/xdg"

                # IPC helper: routes through the wrapped quickshell-config so
                # the IPC client and the running shell are always the same
                # quickshell binary.
                install -Dm755 bin/qs-ipc $out/bin/qs-ipc
                substituteInPlace $out/bin/qs-ipc \
                  --replace-fail @QUICKSHELL_CONFIG@ $out/bin/quickshell-config

                # Launcher toggle script: thin wrapper over qs-ipc.
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
        mkQuickshellConfig;
    in
    {
      # Per-system factory exposed under `lib`. Functions cannot live under
      # `packages.<system>` (the flake schema rejects non-derivations there),
      # so consumers call `inputs.quickshell-config.lib.${system}.mkQuickshellConfig`.
      lib = forAllSystems (system: {
        mkQuickshellConfig = mkQuickshellConfigFor system;
      });

      packages = forAllSystems (system: rec {
        default = quickshell-config;
        quickshell-config = mkQuickshellConfigFor system { };
      });

      # `nix flake check` builds the default package so evaluation and
      # build regressions are caught in CI.
      checks = forAllSystems (system: {
        build = self.packages.${system}.default;
      });

      # Home Manager module. Surfaces every argument of `mkQuickshellConfig`
      # as a typed option, builds the package once from those inputs, and
      # exposes it back as `programs.quickshell-config.package` so other
      # modules (e.g. window-manager keybindings) can reference the same
      # derivation without re-invoking the factory.
      homeManagerModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.programs.quickshell-config;
          mkPath = description: lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            inherit description;
          };
        in
        {
          options.programs.quickshell-config = {
            enable = lib.mkEnableOption "quickshell-config";

            commandsPath = mkPath "Path to commands.json (one-shot launcher commands).";
            sessionCommandsPath = mkPath "Path to session-commands.json (logout/reboot/etc).";
            interactiveCommandsPath = mkPath "Path to interactive-commands.json (calculator, bash, base64).";
            excludedAppsPath = mkPath "Path to excluded-apps.json (desktop entries hidden from the launcher).";

            stylix = lib.mkOption {
              type = lib.types.nullOr (lib.types.attrsOf lib.types.anything);
              default = null;
              description = ''
                Optional stylix base16 + font attrset used to render
                ds/Foundations.qml from its template. Expects keys
                base00..base0F, monoFont, sansFont.
              '';
            };

            package = lib.mkOption {
              type = lib.types.package;
              readOnly = true;
              description = ''
                The built quickshell-config derivation. Read-only; set the
                input options above to influence what is built.
              '';
              default = self.lib.${pkgs.stdenv.hostPlatform.system}.mkQuickshellConfig {
                inherit (cfg)
                  commandsPath
                  sessionCommandsPath
                  interactiveCommandsPath
                  excludedAppsPath
                  stylix
                  ;
              };
            };
          };

          config = lib.mkIf cfg.enable {
            home.packages = [ cfg.package ];
          };
        };

      # Overlay for easier integration
      overlays.default = final: prev: {
        quickshell-config = self.packages.${final.system}.quickshell-config;
      };
    };
}
