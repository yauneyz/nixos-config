# Instant GBA Session on NixOS

## Goal

Turn the NixOS desktop into a Switch/Steam-Deck-like environment for Game Boy Advance games.

The core interaction should be:

**Super + Shift + G**

- If no GBA game is running:
  - launch the desired GBA ROM in RetroArch
  - automatically restore the exact previous emulator state
  - get into gameplay with as little friction as possible

- If a GBA game is currently running:
  - automatically save emulator state
  - exit RetroArch cleanly
  - return immediately to the desktop

The resulting experience should make a GBA game feel like something that can be picked up and put down in seconds.

The ROM collection is located at:

```text
~/Games/Retroid
```

The NixOS configuration is located at:

```text
~/nixos-config
```

The implementation should live in the NixOS/Home Manager configuration wherever practical instead of relying on manually configured system state.

---

# Desired UX

The primary use case is:

```text
working on desktop
        ↓
Super+Shift+G
        ↓
GBA game appears
        ↓
continue from exact previous moment
        ↓
play for 30 seconds / 5 minutes / an hour
        ↓
Super+Shift+G
        ↓
state saved
RetroArch exits
desktop appears
```

A later press of the same shortcut should bring the game back at the same point.

The interaction should require no emulator menus and ideally no visible loading/configuration UI.

---

# Emulator Choice

Use RetroArch with the `mgba` Libretro core unless testing uncovers a strong reason not to.

The configuration currently has a RetroArch Home Manager module, but RetroArch appears not to be enabled there yet.

Prefer the current Nixpkgs interface:

```nix
pkgs.retroarch.withCores (cores: with cores; [
  mgba
])
```

Do not use the older `retroarch.override { cores = ...; }` pattern.

---

# Save/Resume Model

The important mechanism is RetroArch's automatic save-state support.

Configure RetroArch so that clean exit performs an automatic save state and subsequent launch of the same content automatically loads it.

The relevant conceptual settings are:

```ini
savestate_auto_save = true
savestate_auto_load = true
```

Verify the current RetroArch names/behavior rather than assuming blindly.

Normal in-game saves should continue to work independently.

The automatic state is an additional resume mechanism, not a replacement for game saves.

---

# Clean Shutdown Requirement

Do not implement the toggle by force-killing RetroArch.

The close path must give RetroArch an opportunity to write its automatic save state.

Preferred approaches, in descending order:

1. Send RetroArch its normal Quit command through a supported RetroArch control mechanism.
2. Use RetroArch's command/network interface if appropriate.
3. Use a signal only if RetroArch documents that it results in a normal shutdown.
4. Avoid `SIGKILL`.

The implementation should verify that repeatedly toggling the game does not lose state.

---

# Hotkey

Add this Hyprland binding:

```text
Super + Shift + G
```

The repository already has Hyprland keybindings managed declaratively. Add the binding in the existing Hyprland bindings module rather than creating a separate unmanaged config.

The binding should call a single script or executable such as:

```text
gba-toggle
```

Keep compositor-specific behavior in the Hyprland binding and game/session logic in the script.

---

# gba-toggle Behavior

Create a small, deterministic launcher/toggle script.

Conceptually:

```text
if managed RetroArch GBA session exists:
    request clean RetroArch shutdown
    wait briefly for normal termination
    exit
else:
    determine ROM
    launch RetroArch using mGBA core
    exit
```

Do not use broad commands such as:

```bash
pkill retroarch
```

if they could accidentally terminate unrelated RetroArch sessions.

The script should identify the session it owns.

Possible approaches include:

- PID/state file under `$XDG_RUNTIME_DIR`
- systemd user transient/service unit
- process matching that includes a unique marker
- another simple robust ownership mechanism

Prefer correctness over cleverness.

---

# ROM Selection

Design the implementation so ROM selection can evolve without changing the hotkey/session machinery.

For the first version, one of these approaches is acceptable:

## Option A — Last-played ROM

Remember the last selected GBA ROM and make Super+Shift+G resume that game.

If no last-played ROM exists, present a picker.

This is probably the best long-term interaction.

## Option B — ROM picker whenever starting

When there is no active GBA session:

```text
Super+Shift+G
        ↓
ROM picker
        ↓
game
```

Use an existing launcher such as Rofi if convenient.

Only list GBA-compatible ROM files under:

```text
~/Games/Retroid
```

Search recursively.

Typical extensions to consider:

```text
.gba
.zip
```

Only support archives if RetroArch/mGBA handles them reliably.

The picker should show human-readable filenames.

The chosen ROM path must be safely quoted and work with spaces and punctuation.

---

# Recommended Final UX

A good target is:

```text
Super+Shift+G
```

Resume/stop the current or last GBA game.

And optionally later:

```text
Super+Alt+G
```

Choose a different GBA game.

That keeps the primary suspend/resume command instantaneous after initial setup.

The secondary shortcut is optional for the first implementation.

---

# NixOS/Home Manager Integration

Keep the setup declarative.

Likely areas of the repository to modify include:

```text
~/nixos-config/modules/home/retroarch.nix
~/nixos-config/modules/home/hyprland/binds.nix
~/nixos-config/modules/home/scripts/
```

There is already infrastructure for turning shell scripts in the scripts directory into packages available on `$PATH`; reuse that rather than inventing another script installation mechanism if appropriate.

The implementation should:

- install RetroArch
- install the mGBA Libretro core
- install/configure any launcher dependency used
- install `gba-toggle`
- configure RetroArch's auto-save/auto-load behavior
- bind Super+Shift+G in Hyprland

Avoid imperative setup in `~/.config` unless Home Manager is managing those files.

---

# State Storage

Application state should go to appropriate XDG directories.

Examples:

```text
$XDG_STATE_HOME/gba-toggle/
$XDG_CONFIG_HOME/retroarch/
$XDG_RUNTIME_DIR/
```

Do not put runtime PID files in the Nix config repository.

It is acceptable to store a small file containing the last-played ROM path.

Do not modify ROM files themselves.

---

# Window Behavior

The first implementation does not need complicated Gamescope or scratchpad behavior.

The important things are:

- launch reliably
- focus RetroArch
- save state reliably
- quit reliably
- restore reliably

If RetroArch does not naturally focus/fullscreen cleanly, small Hyprland window rules may be added.

Fullscreen is desirable if it makes the interaction feel console-like, but it should not make startup fragile.

---

# Controller/Input

Do not spend significant effort configuring controllers unless required to make the emulator usable.

Keyboard input should work.

Existing controller configuration should not be broken.

RetroArch menus/hotkeys should not conflict with the global Super+Shift+G shortcut.

---

# Reliability Requirements

The implementation should survive:

- ROM filenames containing spaces
- repeated fast toggles
- RetroArch crashing
- stale PID/state files
- rebuilding Home Manager/NixOS
- rebooting the computer
- moving between several ROMs

If the recorded process no longer exists, the next toggle should recover automatically and launch normally.

The launcher should not create multiple accidental instances of the managed GBA session.

---

# Scope

This version is specifically for GBA.

Do not generalize prematurely into a complete multi-emulator gaming framework.

However, structure the toggle logic cleanly enough that future backends could include:

```text
gba
snes
gbc
ps1
steam
```

The immediate objective is to prove that the "instant game" UX feels good.

---

# Success Criterion

The feature is successful when the following feels natural:

1. Open a GBA game.
2. Reach an arbitrary point during active gameplay.
3. Press Super+Shift+G.
4. RetroArch disappears and exits cleanly.
5. Do unrelated desktop work.
6. Press Super+Shift+G.
7. Within a short startup delay, the exact previous gameplay state reappears.
8. Repeat this many times without corrupting or losing state.

The interaction should feel much closer to a handheld's Home/Sleep button than to manually launching an emulator.