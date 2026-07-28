# QuickShell Configuration

Personal QuickShell configuration packaged as a Nix flake.

## Structure

```
.
├── ds/                 # Design system components
├── modules/            # QuickShell modules (bar, dashboard, drawer, etc.)
├── services/           # Services (audio, network, notifications, etc.)
├── shell/              # Shell-specific configurations
├── shell.qml           # Main entry point
└── flake.nix           # Nix flake definition
```

## Usage

### Manual Testing

```bash
# Run the packaged configuration (registered as the named config "qsc")
quickshell-config

# Or use the start script (kills existing instance first)
~/.config/mango/start-quickshell

# Run from a working copy with live reload
quickshell -p ./
```

### IPC

The packaged shell is selected by the stable name `qsc`, not by its
nix store path, so IPC clients keep working across rebuilds.

Two helpers are installed alongside `quickshell-config`:

```bash
# Forward arbitrary IPC to the running instance
qs-ipc call <target> <method> [args...]

# Convenience: toggle the launcher drawer
qs-toggle-launcher
```

Both go through the same wrapped `quickshell` binary that runs the
shell, so the IPC client and the running instance are always the
same version (IPC is not forward/backward compatible across
quickshell versions).

### Integration with Mango

The bar reads compositor state through the `Mango` singleton
(`services/Mango.qml`), which talks to mango over `mmsg` (`watch` streams
for tags, monitors, focus, and keyboard layout; `dispatch` for actions).
Auto-start happens from mango's `autostart.sh`:

```bash
~/.config/mango/start-quickshell &
```

## Development

### Testing Changes

1. Make changes to the QML files in this directory
2. Rebuild the system: `quickshell -p ./`


## Flake Structure

This configuration is packaged as a Nix flake with:

- **`packages.<system>.default`** — no-arg build of the configuration.
- **`lib.<system>.mkQuickshellConfig`** — factory taking
  `{ commandsPath?, sessionCommandsPath?, interactiveCommandsPath?, excludedAppsPath?, stylix? }`
  for downstream consumers.
- **`homeManagerModules.default`** — home-manager module exposing
  `programs.quickshell-config.{enable,commandsPath,sessionCommandsPath,interactiveCommandsPath,excludedAppsPath,stylix}`,
  plus a read-only `package` for other modules to reference.
- **`overlays.default`** — for system-wide availability.

## Dependencies

- QuickShell (from git+https://git.outfoxxed.me/outfoxxed/quickshell)
- Qt6 QML modules
- Nix with flakes enabled

## ToDo
- [ ] DS
  - [ ] Propagate margin, radius and opacity to all components
- [ ] Bar
  - [ ] Handle unknown icons
- [ ] Notifications
  - [ ] Add notificationTime
  - [ ] Don't hide notification when hover
  - [ ] Group notifications

## Troubleshooting

### Process Management

If QuickShell doesn't restart properly:

```bash
# Find QuickShell processes
pgrep -af quickshell

# Kill all QuickShell instances
pgrep -f "/bin/quickshell.*-p" | xargs -r kill
```

## 📚 References
* [Quickshell](https://quickshell.org/docs/v0.2.0/types/Quickshell.Hyprland/HyprlandWorkspace/)
* [Caelestia-shell](https://github.com/caelestia-dots/shell)
* [Shovel-shell](https://github.com/shovelwithasprout/shovel-shell)
