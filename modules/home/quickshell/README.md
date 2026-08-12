# Zac Quickshell

The shell is deployed as `~/.config/quickshell/zac-shell` and is intentionally
selected by one option:

```nix
zac.desktop.shell.backend = "quickshell"; # default: "legacy"
```

The legacy Waybar, SwayNC, and SwayOSD packages/configuration remain installed.
Only their runtime ownership changes.

## Development

Run the repository tree with hot reload (stop the managed unit first):

```sh
systemctl --user stop zac-quickshell.service
qs --path ./modules/home/quickshell/config
```

When developing while the declarative backend is `legacy`, stop SwayNC for the
test session before launching the shell: both programs implement the single
freedesktop notification-server interface and must not run together.

The repository `Theme.qml` contains substitution markers, so the development
run uses its safe fallback colors. A Home Manager rebuild injects the exact
Stylix palette.

Useful commands:

```sh
zac-shell toggle bluetooth
zac-shell close
zac-shell reload
zac-shell-diagnostics
journalctl --user -u zac-quickshell.service -f
```

## Emergency runtime fallback

```sh
systemctl --user stop zac-quickshell.service
waybar &
swaync &
swayosd-server &
```

Make the rollback permanent by setting the backend to `"legacy"` and rebuilding.
