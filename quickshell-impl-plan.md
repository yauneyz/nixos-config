# Quickshell Desktop Shell Implementation Plan

## 1. Purpose

This document specifies an aggressive, native Quickshell desktop shell for this
NixOS/Hyprland configuration. The goal is to make the desktop feel continuously
responsive and alive through coherent motion, stateful surfaces, and direct
system integration while preserving the existing workflow and making rollback
immediate.

This is an implementation plan, not an adoption of the Serpantinum dotfiles.
The visual and interaction ideas are inspired by that project, but the shell
will be written specifically for this repository, its two hosts, its Stylix
palette, its Hyprland Lua configuration, and its current utilities.

The implementation will replace the *runtime roles* of Waybar, SwayOSD, and
SwayNC when enabled. Their Nix modules and configuration will remain in the
repository as a tested fallback. It will not change Ghostty, the shell prompt,
terminal colors, terminal keybindings, or terminal behavior.

## 2. Desired outcome

When the Quickshell backend is enabled, the desktop will provide:

- One reactive bottom bar on every connected monitor.
- Per-monitor workspace displays with an elastic active-workspace indicator.
- A system tray with native menus and animated item insertion/removal.
- A compact media capsule and an expanded MPRIS player.
- Native PipeWire output, input, stream, mute, and device controls.
- A first-class Bluetooth manager that handles many paired and simultaneously
  connected devices.
- Network, battery, clock, calendar, system-resource, recording, and update
  status.
- Morphing popups that originate from the bar item that opened them.
- Volume, microphone, brightness, keyboard-lock, media, and device OSDs.
- Notification toasts plus a searchable/clearable notification center.
- Multi-monitor correctness during startup, hotplug, unplug, scaling, rotation,
  and focus changes.
- A consistent animation system rather than unrelated effects on every widget.
- A single Nix option that switches between the new shell and the legacy stack.

The result should feel expressive but remain usable as a daily desktop. Motion
must communicate state and spatial relationships; it must not delay actions.

## 3. Existing system baseline

The implementation must integrate with, rather than rediscover, the following
existing pieces:

- Hyprland is configured through Home Manager using the new Lua configuration
  format.
- The bar is currently a translucent, segmented bottom Waybar.
- SwayNC currently owns the notification daemon and control center.
- SwayOSD currently renders volume and brightness feedback.
- `awww` owns per-monitor wallpaper display.
- Stylix exposes the custom `Cosmic Night` Base16 palette.
- PipeWire/WirePlumber provide audio.
- EasyEffects is already installed and enabled.
- Cava is already configured and can be reused as a visualization data source.
- Vicinae is available for clipboard history and richer command launching.
- Rofi remains available as a fallback application launcher and power menu.
- NetworkManager and BlueZ provide network and Bluetooth services.
- The laptop uses `eDP-1` at high DPI and 120 Hz.
- The desktop normally uses a rotated portrait `DP-1` and landscape `DP-2`,
  with different fractional scales and different workspace assignments.
- `nwg-displays` may override the declarative monitor layout at runtime.

The existing files most directly affected by integration are:

- `modules/home/default.nix`
- `modules/home/hyprland/exec-once.nix`
- `modules/home/hyprland/binds.nix`
- `modules/home/hyprland/settings.nix`
- `modules/home/hyprland/windowrules.nix`
- `modules/home/hyprland/monitors.nix`
- `modules/home/hyprland/monitors-desktop.nix`
- `modules/home/waybar/`
- `modules/home/swaync/`
- `modules/home/swayosd.nix`
- `modules/core/stylix.nix`

## 4. Scope

### 4.1 In scope

- A repository-native Home Manager module for Quickshell 0.3.x.
- A modular QML shell and reusable visual primitives.
- Native Quickshell integrations where the API is mature enough.
- Small, purpose-built helper processes only where there is no good native API.
- Declarative startup, IPC commands, logging, and health checks.
- Multi-monitor bars, popups, OSDs, and notification placement.
- A polished Bluetooth experience, including multiple connected devices.
- Preservation of legacy programs and a one-setting rollback mechanism.
- Static validation, Nix evaluation, runtime smoke tests, and performance tests.

### 4.2 Explicitly out of scope

- Replacing or restyling Ghostty.
- Changing Zsh, Starship/p10k, Neovim, Emacs, or other terminal applications.
- Copying Serpantinum's files or installer.
- A graphical monitor layout/configuration editor in the first implementation.
- Replacing `nwg-displays`.
- An online wallpaper search engine in the first implementation.
- A lock screen or display manager rewrite.
- A full application launcher intended to replace both Rofi and Vicinae on day
  one. The shell may expose launch buttons and a compact launcher later.
- Persistent desktop widgets that obscure normal tiled-window use.

## 5. Non-negotiable design requirements

### 5.1 Rollback must be trivial

The implementation will introduce a local option conceptually equivalent to:

```nix
desktop.shell.backend = "quickshell"; # or "legacy"
```

The exact option namespace will follow conventions already used in the
repository. The option controls runtime ownership:

| Backend | Bar | Notifications | OSD | Quickshell |
|---|---|---|---|---|
| `legacy` | Waybar | SwayNC | SwayOSD | stopped |
| `quickshell` | Quickshell | Quickshell | Quickshell | running |

The legacy packages and configuration files remain installed unless there is a
strong reason not to do so. Switching back must require only changing the
option, rebuilding, and logging out/in or restarting the affected user units.

Only one notification server may run at a time. Backend selection therefore
must be authoritative and must never start both SwayNC and Quickshell's
`NotificationServer`.

### 5.2 Multi-monitor is foundational

Multi-monitor support is not a later enhancement. Every top-level surface must
be screen-aware from its first implementation.

Quickshell's `Variants { model: Quickshell.screens }` will create one `BarWindow`
per `ShellScreen`. Each instance receives its screen explicitly. The shell must
not assume `DP-1`, `DP-2`, or `eDP-1` inside QML.

Hyprland's `Hyprland.monitorFor(screen)` maps a Quickshell screen to the correct
Hyprland monitor. Workspace filtering and popup routing use that mapping rather
than output-name string comparisons wherever possible.

### 5.3 Event driven by default

Use native reactive services for:

- Hyprland monitors, workspaces, active windows, and IPC events.
- System tray items and menus.
- MPRIS players.
- PipeWire nodes and default devices.
- BlueZ adapters/devices.
- NetworkManager devices and Wi-Fi state.
- UPower battery state.
- Notifications.

Polling is reserved for data that has no reliable signal source, such as CPU,
memory, temperature, update availability, and possibly EasyEffects state.
Polling intervals must be conservative and stop when the relevant UI is not
visible where practical.

### 5.4 Actions must be immediate

Animations may follow an action but must not gate it. Examples:

- Workspace activation is dispatched immediately; the indicator animates to
  the resulting state.
- Volume is changed immediately; the displayed fill interpolates to the new
  value.
- Bluetooth connect/disconnect starts immediately; the card changes into a
  progress state while BlueZ completes the operation.
- Popup content may fade and move while its container morphs, but input should
  become usable as soon as the popup is visible.

## 6. Proposed repository layout

The implementation should be contained in a dedicated module rather than
scattering QML across existing Waybar or Hyprland modules.

```text
modules/home/quickshell/
├── default.nix
├── service.nix
├── keybinds.nix
├── README.md
└── config/
    ├── shell.qml
    ├── qmldir
    ├── Theme.qml
    ├── Motion.qml
    ├── ShellState.qml
    ├── Metrics.qml
    ├── assets/
    │   ├── icons/
    │   └── sounds/
    ├── components/
    │   ├── ActionButton.qml
    │   ├── AnimatedNumber.qml
    │   ├── AvatarIcon.qml
    │   ├── Badge.qml
    │   ├── DeviceIcon.qml
    │   ├── EmptyState.qml
    │   ├── IconButton.qml
    │   ├── MaterialIcon.qml
    │   ├── MorphSurface.qml
    │   ├── ProgressArc.qml
    │   ├── ScrollableColumn.qml
    │   ├── SectionHeader.qml
    │   ├── SegmentedButton.qml
    │   ├── Slider.qml
    │   ├── StatusDot.qml
    │   ├── Surface.qml
    │   ├── Switch.qml
    │   └── Tooltip.qml
    ├── services/
    │   ├── AudioService.qml
    │   ├── BluetoothService.qml
    │   ├── BrightnessService.qml
    │   ├── MediaService.qml
    │   ├── NetworkService.qml
    │   ├── NotificationService.qml
    │   ├── PowerService.qml
    │   ├── SessionService.qml
    │   ├── SystemStatsService.qml
    │   └── WallpaperService.qml
    ├── bar/
    │   ├── Bar.qml
    │   ├── BarBackground.qml
    │   ├── BarCapsule.qml
    │   ├── BatteryCapsule.qml
    │   ├── ClockCapsule.qml
    │   ├── ConnectivityCapsule.qml
    │   ├── LauncherCapsule.qml
    │   ├── MediaCapsule.qml
    │   ├── ResourceCapsule.qml
    │   ├── StatusArea.qml
    │   ├── Tray.qml
    │   ├── TrayItem.qml
    │   ├── WorkspaceStrip.qml
    │   └── WorkspaceButton.qml
    ├── popups/
    │   ├── PopupHost.qml
    │   ├── PopupRouter.qml
    │   ├── AudioPanel.qml
    │   ├── BluetoothPanel.qml
    │   ├── CalendarPanel.qml
    │   ├── MediaPanel.qml
    │   ├── NetworkPanel.qml
    │   ├── PowerPanel.qml
    │   ├── SessionPanel.qml
    │   └── SystemPanel.qml
    ├── bluetooth/
    │   ├── AdapterHeader.qml
    │   ├── ConnectedDeviceHero.qml
    │   ├── DeviceCard.qml
    │   ├── DeviceDetails.qml
    │   ├── DeviceList.qml
    │   ├── PairingDialog.qml
    │   └── ScanIndicator.qml
    ├── audio/
    │   ├── AppStreamRow.qml
    │   ├── DeviceRow.qml
    │   ├── EqualizerSection.qml
    │   ├── LevelMeter.qml
    │   └── VolumeControl.qml
    ├── notifications/
    │   ├── NotificationCenter.qml
    │   ├── NotificationCard.qml
    │   ├── NotificationGroup.qml
    │   └── ToastLayer.qml
    └── osd/
        ├── OsdHost.qml
        ├── OsdModel.qml
        └── OsdToast.qml
```

This is a target organization, not a demand to create empty files. Closely
related components can start together and be split once they become unwieldy.

## 7. Nix and service integration

### 7.1 Package set

The Home Manager module will install at least:

- `quickshell` (currently available as 0.3.0 in the pinned nixpkgs).
- `qt6.qtmultimedia` if album art/media or notification sounds need it.
- `inotify-tools` only if a helper must watch files that Quickshell cannot watch
  directly.
- `jq` for bounded helper scripts that consume JSON.
- Existing tools used by actions, such as `brightnessctl`, `playerctl`,
  `pavucontrol`, `easyeffects`, `nmcli`, and `bluetoothctl`, remain available.

Native Quickshell APIs should eliminate most subprocess dependencies.

### 7.2 Configuration deployment

Home Manager will deploy the QML tree under:

```text
~/.config/quickshell/zac-shell/
```

The entry point is `shell.qml`, and the runtime is selected with:

```text
qs --config zac-shell --no-duplicate
```

For normal operation the deployed files can be immutable store-backed links.
The module README will document a development command using `qs --path` against
the repository directory so QML hot reload works without rebuilding Nix after
every edit.

### 7.3 User service

Prefer a systemd user unit over a naked Hyprland startup command. The service
will:

- Start only for the `quickshell` backend.
- Be associated with `hyprland-session.target`.
- Start after the graphical session environment has been imported.
- Use `Restart=on-failure` with bounded restart delay.
- Write logs to the user journal.
- Stop cleanly on session exit.
- Run exactly one named Quickshell instance.

The existing `exec-once.nix` startup list will conditionally start either:

- Waybar + SwayNC + SwayOSD for the legacy backend, or
- the Quickshell systemd unit for the new backend.

No `pkill`-based startup arbitration should be necessary during steady-state
operation.

### 7.4 IPC and command surface

Quickshell `IpcHandler` objects will expose a small stable command API:

```text
shell.togglePanel(name)
shell.openPanel(name)
shell.closePanel()
shell.toggleNotificationCenter()
shell.showOsd(kind, value, label)
shell.reload()
```

Wrapper scripts or direct `qs ipc call` commands will be bound from Hyprland.
The shell must not expose internal QML object names as the public command API.

When a keyboard command opens a panel, `ShellState` chooses the screen
corresponding to `Hyprland.focusedMonitor`. When a pointer click opens one, it
uses the screen and source geometry of the clicked bar item.

## 8. Shared state and service architecture

### 8.1 `ShellState`

`ShellState` is the single source of truth for shell-level UI state:

- Active popup name.
- Popup target screen.
- Popup anchor rectangle in screen-local coordinates.
- Whether the notification center is open.
- DND state.
- Current media player selection.
- Reduced-motion state.
- Performance/gaming mode.
- Currently visible OSD and dismissal deadline.
- Optional per-monitor remembered popup state.

It owns routing state only. It must not duplicate PipeWire, BlueZ, or Hyprland
state.

### 8.2 `Theme`

`Theme.qml` will be generated or parameterized from Stylix's Base16 values so
the shell uses the existing Cosmic Night palette. It will define semantic
tokens rather than allowing components to consume arbitrary Base16 slots:

- `background`, `surface`, `surfaceRaised`, `surfaceHover`.
- `text`, `textMuted`, `textDisabled`.
- `primary`, `secondary`, `tertiary`.
- `success`, `warning`, `danger`, `info`.
- `outline`, `shadow`, `scrim`.
- Audio, network, Bluetooth, battery, and workspace accents.

Color contrast must remain acceptable over both current wallpapers. Translucent
surfaces should rely on Hyprland blur but retain enough opacity to be legible
when blur is unavailable.

The first version uses the fixed Stylix palette. Runtime wallpaper-derived
colors are a later, isolated feature and must never generate terminal themes.

### 8.3 `Metrics`

Centralized dimensions prevent each widget from inventing geometry:

- Bottom margin: approximately 8 px logical.
- Bar height: approximately 42–46 px logical.
- Compact capsule height: approximately 36 px.
- Base radius: 12–14 px.
- Popup radius: 18–22 px.
- Hit target minimum: 34 px.
- Standard spacing: 4, 8, 12, 16, 24 px scale.
- Popup maximum widths and heights expressed relative to screen size.

QML coordinates are logical pixels. No manual multiplication by monitor scale
is needed for normal layout. Size classes based on available logical width will
handle the portrait monitor and laptop.

### 8.4 `Motion`

All components use a small set of named motion tokens:

| Token | Typical duration | Use |
|---|---:|---|
| `instant` | 80–120 ms | pressed feedback, mute icon change |
| `fast` | 150–200 ms | hover color, opacity, small controls |
| `normal` | 220–300 ms | popup morph, workspace indicator |
| `expressive` | 400–550 ms | entrance cascade, large content reveal |
| `ambient` | 1.5–3 s | attention pulse, scanning orbit |

Recommended easing families:

- `OutCubic`/`OutQuint` for movement that arrives decisively.
- A restrained `OutBack` for insertion and hover scale, with low overshoot.
- `InCubic` for exits.
- `InOutSine` for ambient loops.

Reduced-motion mode will:

- Remove overshoot.
- Reduce travel distance to nearly zero.
- Shorten or eliminate entrance cascades.
- Disable perpetual decorative animation.
- Preserve fades and functional progress indication.

## 9. Top-level windows and layers

### 9.1 Per-monitor bar windows

Each screen receives a `PanelWindow`:

- Anchored left, right, and bottom.
- Transparent full-width window with visual capsules placed inside it.
- An exclusive zone equal to bar height plus bottom margin.
- Namespace `zac-shell-bar`.
- Screen explicitly assigned from `Quickshell.screens`.
- Independent responsive layout based on the screen's logical dimensions.

The full-width layer window avoids re-creating windows when capsule widths
change. The visible bar remains visually segmented and floating.

### 9.2 Popup windows

There will be one popup host per screen, but only the selected screen's host is
visible. Popup hosts:

- Use the overlay layer.
- Ignore exclusive zones.
- Are keyboard-focusable only while a panel needing keyboard input is open.
- Provide an outside-click scrim/mask.
- Know the opening capsule's local geometry.
- Animate from the anchor rectangle into the requested panel bounds.
- Clamp final geometry to the screen's available area.

Switching from Bluetooth to audio does not destroy and recreate a visibly
unrelated window. The shared host moves/resizes while content crossfades and
slightly scales. This is the central “morphing shell” effect.

### 9.3 OSD windows

An OSD host exists per monitor. Hardware-key OSDs appear on the focused monitor;
device-specific events can appear on the monitor containing the invoking bar.
The host is non-focusable, does not reserve space, and ignores pointer input.

### 9.4 Notification toast windows

Toast placement will be configurable, initially top-right on the focused or
pointer monitor. Notifications are not duplicated across all monitors. A
notification is assigned a display when it arrives and remains there for its
lifetime even if focus changes.

## 10. Bar design

The current bottom-bar grouping is sound and should be preserved conceptually:

```text
[ launcher + tray ]        [ workspaces ]        [ media ] [ system ] [ clock/session ]
```

On narrower screens, optional detail text collapses before controls disappear.
The portrait display uses compact variants. The bar must never extend beyond the
logical screen width.

### 10.1 Startup choreography

After service readiness:

1. Left group moves up and fades in.
2. Workspace buttons appear in a 35–50 ms stagger.
3. Center/clock group settles in.
4. Right group enters from the nearest edge.
5. Tray items pop in only after their model is available.

The entire sequence should finish in roughly 700–900 ms and run only when a bar
window is newly created. Hotplugging a monitor can run a shorter version on the
new screen without replaying animation elsewhere.

### 10.2 Launcher capsule

- Displays the NixOS icon.
- Left click opens the existing preferred launcher (initially Rofi or Vicinae,
  selected declaratively).
- Right click opens the wallpaper actions panel or invokes the existing
  wallpaper restore action.
- Hover changes surface and gently scales the icon.
- Press compresses to approximately 0.94 scale.

### 10.3 Tray

Use `SystemTray.items` directly. Every tray item supports:

- Icon lookup and fallback icon.
- Left-click activation.
- Middle-click secondary activation.
- Right-click native `QsMenuAnchor` menu.
- Menu-only items.
- Tooltip/title.
- Animated insertion/removal through width, opacity, and scale.
- Correct icon sizing at fractional scale.

The tray capsule collapses entirely when empty. It grows smoothly as items are
added. Item animations must not move the workspace strip.

### 10.4 Workspace strip

Workspaces are sourced from `Hyprland.workspaces`, sorted by ID, and filtered
per monitor.

Filtering rules:

- Show normal positive-ID workspaces assigned to or currently on this monitor.
- Preserve the configured workspace vocabulary: `1`–`10`, then `w`, `y`, `u`,
  `o`, `p` for IDs `11`–`15`.
- On the desktop, `DP-1` normally shows `8`, `9`, and `10`; `DP-2` normally
  shows `1`–`7` and `11`–`15`.
- On the laptop, show the configured primary workspace set and any additional
  occupied/urgent workspace.
- Workspace-to-monitor ownership must follow Hyprland runtime state and rules,
  not a hard-coded QML table. A small Nix-provided preferred-ID list may define
  persistent empty workspaces if the Hyprland API does not expose empty ruled
  workspaces before creation.

Visual states:

- Empty: muted label.
- Occupied: brighter label/subtle surface.
- Active on this monitor: shared accent indicator behind the label.
- Focused active workspace: strongest text treatment.
- Urgent: danger tint plus one finite pulse.
- Fullscreen: optional small corner marker.

The active indicator is one shared rectangle, not one active background per
button. Its left and right edges animate separately:

- Moving right: leading/right edge arrives quickly, trailing/left edge follows.
- Moving left: inverse timing.
- The temporary stretch visually communicates direction.

Click activation calls `HyprlandWorkspace.activate()` immediately. Scroll over
the strip changes to the adjacent workspace on the same monitor if enabled.

### 10.5 Media capsule

The media capsule appears only when at least one meaningful MPRIS player exists.
Player selection prefers:

1. A currently playing player.
2. The last user-selected player.
3. A paused player with track metadata.
4. The first controllable player.

Compact contents:

- Cropped album art.
- Elided track title.
- Play/pause.
- Previous/next on sufficiently wide screens.
- A thin animated progress line where position is supported.

The capsule expands from zero width and slides its inner contents into place
when playback begins. Clicking its descriptive area opens `MediaPanel`.

### 10.6 Resource capsule

- CPU percentage.
- Memory percentage or used GiB.
- Disk percentage on desktop when desired.
- Optional temperature with hardware-aware fallback.
- Two-second polling while the bar is visible.
- Clicking opens a system panel; right-click can retain the existing floating
  `btop` action.

Values should animate numerically but not cause the capsule width to jitter.
Use tabular digits or fixed-width value slots.

### 10.7 Connectivity capsule

This capsule combines concise summaries while retaining separate click targets:

- Network icon and SSID/link state.
- Bluetooth icon plus connected-device count.
- Audio icon and output volume.
- Battery on hosts with a display battery.

Each sub-item opens its specific panel. Connected Bluetooth count must represent
all connected BlueZ devices, not only the most recently connected one.

### 10.8 Clock/session capsule

- Time in 24-hour format, matching the current bar.
- Compact date optionally shown when space permits.
- Clicking opens calendar/agenda.
- Notification bell shows unread/history count and DND state.
- Power icon opens the session panel.

The clock updates at minute precision unless seconds are deliberately shown,
reducing unnecessary wakeups.

## 11. Morphing popup router

The popup router owns a registry describing each panel:

```qml
{
    name: "bluetooth",
    component: bluetoothPanelComponent,
    preferredWidth: 620,
    preferredHeight: 680,
    placement: "above-anchor"
}
```

Opening behavior:

1. Record the source capsule's screen and rectangle.
2. Make that screen's popup host visible at the source rectangle.
3. Instantiate or reveal the requested content.
4. Animate the host to its clamped target rectangle.
5. Fade/translate content in with a slight delay no greater than 40–60 ms.

Switch behavior:

1. Keep the host visible.
2. Update target geometry.
3. Crossfade old/new content while geometry interpolates.
4. Preserve data services so device/media state does not reset.

Close behavior:

- Escape, outside click, repeated trigger click, or explicit close button.
- Content fades quickly.
- Host shrinks toward the original anchor and becomes invisible.
- Focus returns naturally; the bar itself must not steal keyboard focus.

The panel must choose a new anchor if its original monitor disappears while it
is open. Preferred behavior is to close immediately and cleanly; it may reopen
on the newly focused monitor only after another user action.

## 12. Bluetooth manager

Bluetooth is a primary feature, not a status-menu afterthought.

### 12.1 Data source

Use Quickshell 0.3's native `Quickshell.Bluetooth` integration:

- `Bluetooth.adapters` for every adapter.
- `Bluetooth.defaultAdapter` for the common case.
- `Bluetooth.devices` for connected devices across adapters.
- Each adapter's device model for paired, known, and discovered devices.
- Native writable adapter and device properties/functions where supported.

This avoids parsing the human-oriented output of `bluetoothctl` for normal
state. `bluetoothctl` may remain a narrowly scoped fallback for an operation
that the native API cannot complete reliably.

### 12.2 Summary state

The bar displays:

- Disabled adapter: disabled Bluetooth icon.
- Enabled, nothing connected: normal Bluetooth icon.
- One connected device: Bluetooth icon, optional device-type glyph, count `1`.
- Multiple connected devices: Bluetooth icon and exact count.
- Scanning or connecting: finite animated orbit/spinner.
- Error: danger badge that clears after state recovers.

The count is derived from the full connected device model. Headphones, a mouse,
a keyboard, and a controller can all be represented simultaneously.

### 12.3 Panel information architecture

The Bluetooth panel contains:

1. **Header**
   - Adapter name.
   - Master power switch.
   - Scan toggle and scanning indicator.
   - Connected count.
   - Adapter selector when more than one adapter exists.

2. **Connected devices hero area**
   - Horizontally scrollable or wrapped device cards.
   - Device name and type icon.
   - Battery percentage when reported.
   - Connection-state ring.
   - Quick disconnect action.
   - Multiple connected devices remain visible at once.

3. **Paired devices**
   - Known devices not currently connected.
   - Connect action.
   - Trusted indicator/toggle.
   - Forget action behind confirmation.

4. **Available devices**
   - Discovered, unpaired devices.
   - Signal strength if exposed; otherwise no fabricated meter.
   - Pair/connect action.
   - Clear scanning and pairing progress state.

5. **Device details**
   - Name/alias.
   - Address.
   - Paired, bonded, trusted, blocked, wake-allowed state.
   - Battery.
   - Owning adapter.
   - Connect/disconnect, trust/untrust, block/unblock, forget.

### 12.4 Device type treatment

Map BlueZ icon names to coherent glyphs and fallbacks:

- Audio headset/headphones.
- Speaker/audio card.
- Keyboard.
- Mouse/trackball.
- Game controller.
- Phone/tablet.
- Computer.
- Generic Bluetooth device.

The source-provided icon name should still be used through
`Quickshell.iconPath()` when a suitable themed icon exists.

### 12.5 Connection state machine

Every device card renders an explicit operation state:

```text
idle → connecting → connected
idle → pairing → paired/connecting → connected
connected → disconnecting → paired
paired → forgetting → removed
operation → failed → idle
```

QML derives normal terminal states from BlueZ. A small local operation record
tracks the requested transition and timeout so the UI can say “Connecting…”
instead of appearing frozen.

Requirements:

- Independent operation state per device; connecting one device must not lock
  the entire panel.
- Allow multiple devices to connect concurrently when BlueZ permits it.
- Timeout with an actionable error, never an endless spinner.
- Do not optimistically claim “Connected” until BlueZ reports it.
- Retry is explicit.
- Disconnect should be a normal click; forget/block requires confirmation.

### 12.6 Pairing and authentication

Pairing is the highest-risk Bluetooth UX area and needs explicit testing.

- Simple-confirmation/no-input devices use the native `pair()` flow.
- The implementation must verify how the system BlueZ agent handles numeric
  confirmation, PIN entry, and passkey display on both hosts.
- If Quickshell 0.3 does not expose agent prompts, add a narrowly scoped pairing
  agent/helper or hand the exceptional flow to the already-installed
  Overskride UI.
- The panel must never silently hang on a missing agent.
- Pairing prompts must appear on the initiating monitor.
- Trust can be enabled after successful pairing if desired, but this behavior
  should be a declared setting rather than an undocumented side effect.

### 12.7 Bluetooth battery

- Display battery only when `batteryAvailable` is true.
- Do not treat a missing battery interface as 0%.
- Update live from BlueZ/UPower signals.
- Apply warning/danger colors below defined thresholds.
- Surface low battery as a finite attention pulse in the bar and optionally an
  actionable notification.

### 12.8 Bluetooth sound feedback

Optional subtle sounds may play for:

- Successful connect.
- Disconnect.
- Pairing success/failure.

Sounds are disabled by default until volume and annoyance are evaluated. They
must never play during initial model population at login.

## 13. Audio system

### 13.1 Native PipeWire service

Use:

- `Pipewire.defaultAudioSink`.
- `Pipewire.defaultAudioSource`.
- `Pipewire.nodes` for hardware and application streams.
- `PwObjectTracker` to bind nodes whose writable volume/mute properties are
  displayed.

Do not bind every PipeWire object forever. Track the default devices and the
subset of visible audio nodes to reduce overhead.

### 13.2 Bar audio control

- Icon reflects mute and rough volume band.
- Text shows integer percentage.
- Left click toggles mute.
- Scroll adjusts output in 2% steps.
- Right click opens the audio panel or `pavucontrol` according to user setting.
- Normal click on the capsule opens `AudioPanel`.

### 13.3 Audio panel

Sections:

1. **Master output**
   - Large volume control.
   - Mute.
   - Current sink name/icon.
   - Level meter where supported.

2. **Output devices**
   - All suitable sinks.
   - Click to set preferred default sink.
   - Bluetooth sinks show their Bluetooth device context where resolvable.

3. **Microphone/input**
   - Input level and mute.
   - Default source selector.
   - Active-capture indicator for privacy awareness.

4. **Application streams**
   - Per-app icon/name.
   - Volume and mute.
   - Stream list appears only while the panel is open.

5. **EasyEffects**
   - Button to open EasyEffects.
   - Preset selection/status if a stable CLI or D-Bus integration is available.
   - Do not duplicate the entire EasyEffects editor without a reliable API.

### 13.4 Fluid volume visualization

The master control can use a circular or pill-shaped fluid fill inspired by the
showcase. It should be implemented with a lightweight `Canvas` or clipped
geometry:

- Fill height maps to volume.
- Wave amplitude falls toward 0 at empty/full.
- The wave moves only while the panel/OSD is visible.
- Muting drains or desaturates the fill without changing the stored volume.
- Reduced-motion uses a static clipped fill.

This is decorative and must not run continuously when hidden.

## 14. Media panel

The expanded player provides:

- Large album art with a fallback gradient/icon.
- Track title, artist, and album.
- Player identity and player selector when several players exist.
- Previous, play/pause, next, and stop when supported.
- Seek slider using MPRIS position/length.
- Shuffle and loop state where supported.
- Player volume when supported.
- Optional visualization using existing Cava output.
- Button to open/raise the player.
- EasyEffects shortcut/preset area shared with audio.

MPRIS position should update only while a progress display is visible. A one
second timer is sufficient for the bar; a frame animation may be used while the
user is dragging the expanded seek slider.

## 15. Network panel

Use Quickshell's NetworkManager integration for primary state.

### 15.1 Bar summary

- Ethernet connected: wired icon.
- Wi-Fi connected: Wi-Fi strength icon and optional SSID.
- Enabled but disconnected: available/disconnected icon.
- Disabled/hardware-blocked: disabled icon.
- Captive/restricted connectivity: warning badge.

### 15.2 Panel

- Wi-Fi master switch.
- Current connection card.
- Available network list sorted by connection status, saved status, and signal.
- Scan/refresh action if supported.
- Secure/open indicators.
- Connect to saved network.
- Password field for new protected networks.
- Disconnect/forget actions with correct confirmation levels.
- Wired device state and reconnect/disconnect actions.
- Connectivity check/captive portal status.

If the 0.3 API lacks a required Wi-Fi credential workflow, use `nmcli` through a
strict helper that exchanges machine-readable JSON with QML. Never interpolate
raw SSIDs/passwords into a shell command string; pass arguments as separate
process arguments or through protected stdin.

## 16. Battery and power

Use `UPower.displayDevice` for the aggregate system battery.

Bar behavior:

- Hidden on desktop when the display device is not ready/present.
- Percentage and state-aware icon on laptop.
- Charging animation is finite/subtle, not a permanent high-frequency loop.
- Warning below 20%, danger below 10%, configurable.
- Estimated time appears in tooltip/panel only when valid.

Power panel:

- Charge percentage and state.
- Time to empty/full.
- Battery health/capacity when available.
- Power profile selector backed by power-profiles-daemon.
- Suspend, lock (if later enabled), log out, reboot, shutdown.
- Destructive session actions require confirmation.

## 17. Calendar and time

The clock panel contains:

- Current time and full date.
- Month calendar with animated month transition.
- Today highlight.
- Week numbers optionally.
- Upcoming events if a stable local calendar source is configured later.
- Weather only after a location/provider is explicitly configured.
- Quick timers/Pomodoro as a later subcomponent.

No network weather calls should be added implicitly. The initial panel can ship
fully functional as a calendar without external services.

## 18. Notifications

### 18.1 Server ownership

When the Quickshell backend is active, its `NotificationServer` owns the
freedesktop notification bus. SwayNC must not be running.

Advertised capabilities should match actual implementation:

- Body text and markup sanitization.
- Images/icons.
- Actions.
- Persistence when the center keeps history.
- Inline replies only if fully supported.

### 18.2 Toasts

- Stack on one selected monitor.
- Slide/fade from the edge with a slight scale settle.
- Timeout varies by urgency.
- Critical notifications persist.
- Hover pauses timeout.
- Action buttons are visible without opening the center.
- Swipe/drag dismissal may be added after mouse behavior is solid.
- Replacement notifications update the existing card instead of duplicating.

### 18.3 Notification center

- Opens from the bar bell and morphs from that capsule.
- History grouped by application and/or time.
- DND toggle.
- Clear individual, group, or all.
- Preserve live notification objects so actions remain usable.
- Empty state.
- MPRIS should stay in the dedicated media panel rather than being duplicated
  unless a compact now-playing header proves useful.

### 18.4 Persistence

The first version may keep session history in memory. If persistence across
restarts is added, store a sanitized bounded JSON history under XDG state, not
the Nix-managed config directory. Do not persist action handles that cannot
survive process restart.

## 19. OSD system

The shell replaces SwayOSD runtime rendering with a shared OSD model.

Supported OSD kinds:

- Output volume/mute.
- Microphone volume/mute.
- Brightness.
- Caps Lock, Num Lock, Scroll Lock.
- Media play/pause/track change.
- Bluetooth connect/disconnect.
- Optional workspace name for special workspace transitions.

Visual behavior:

- Compact bottom-center or center-right capsule on the focused monitor.
- Icon, label, value, and animated progress.
- Repeated hardware-key input updates the same OSD and resets its timeout.
- Opening uses fast scale/fade; closing uses a shorter fade/slide.
- No queue of stale volume OSDs.
- Value animation catches up quickly and never lags behind rapid key repeats.

Hyprland hardware keybindings will call commands that change the system state
and notify Quickshell. Where the Quickshell service itself can perform the
change over PipeWire, a single IPC call can do both atomically.

## 20. System/session panel

The system panel expands the existing CPU/memory/disk information:

- CPU total and optional per-core chart.
- Memory and swap.
- Disk usage.
- Temperatures when sensors are available.
- Network throughput only if collected efficiently.
- Uptime.
- Host name and NixOS generation/revision where inexpensive.
- Buttons for `btop`, system settings, and update/rebuild workflows.

The session panel provides:

- Lock only if lock support is enabled.
- Suspend.
- Log out.
- Reboot.
- Shutdown.

Every destructive action uses a second-stage confirmation surface. Confirmation
expires automatically.

## 21. Wallpaper integration

The first version retains `awww` and the existing per-monitor wallpaper pair.

Planned shell integration:

- Right-click launcher or a session-panel action opens a local wallpaper grid.
- Show repository wallpapers with cached thumbnails.
- Allow applying to current monitor, all monitors, or the configured desktop
  pair.
- Use `awww` transitions with a bounded duration and the monitor explicitly
  selected.
- Do not modify terminal themes.

Runtime palette generation is a second-stage feature:

- Matugen generates shell-only semantic colors from the chosen wallpaper.
- Write generated data under XDG cache/state.
- Quickshell watches/reloads that palette.
- Waybar/SwayNC/SwayOSD templates are irrelevant while the new backend is
  active, but legacy configuration remains unchanged.
- GTK, Qt, browser, editor, and terminal theming stay fixed unless separately
  and explicitly authorized.

## 22. Multi-monitor behavior in detail

### 22.1 Creation and destruction

- A bar instance is created for every `Quickshell.screens` entry.
- A screen addition does not restart the entire shell.
- A screen removal destroys only its visual instances.
- Shared service singletons remain alive once, avoiding duplicate polling and
  duplicate notification servers.

### 22.2 Workspace ownership

- Compare each workspace's `monitor` object with
  `Hyprland.monitorFor(barWindow.screen)`.
- Active state means active on that monitor; focused state distinguishes the
  currently keyboard-focused monitor.
- Persistent empty workspace buttons require declarative monitor preferences
  because Hyprland may not expose a workspace object until created.
- Refresh workspaces after monitor layout changes that do not emit enough IPC
  detail.

### 22.3 Popup routing

- Pointer-opened popup: invoking bar's screen.
- Keyboard-opened popup: `Hyprland.focusedMonitor`.
- Notification toast: focus/pointer policy selected once at arrival.
- OSD: focused monitor at the time of the hardware action.
- Popup coordinates are screen-local. Never calculate global positions using
  assumptions about the portrait monitor being left of the landscape monitor.

### 22.4 Responsive size classes

Define three logical-width classes:

- Compact: portrait/narrow screens.
- Standard: laptop and normal landscape.
- Wide: high-resolution landscape with ample logical width.

Compact behavior:

- Hide SSID and media artist before hiding icons.
- Limit workspace labels to monitor-relevant IDs.
- Collapse system resource text to icons/one rotating value if necessary.
- Popups use a larger fraction of width but remain inside screen bounds.
- Bluetooth connected cards wrap vertically instead of overflowing.

### 22.5 Fractional scale and rotation

- Use logical QML dimensions and `ShellScreen` size.
- Avoid cached pixel dimensions based on physical resolution.
- Test DP-1 rotated at 1.5 scale and DP-2 at 1.25 scale.
- Test the laptop at scale 2.
- Validate icon sharpness and one-pixel borders at fractional scale.
- Recompute popup bounds on screen geometry changes.

### 22.6 Fullscreen behavior

Initial policy: keep the bar visible because that matches the existing setup.
Later configuration can support:

- Always visible.
- Autohide on fullscreen.
- Per-monitor fullscreen autohide.

If autohide is implemented, it must affect only the monitor containing the
fullscreen workspace and restore its exclusive zone correctly.

## 23. Hyprland animation changes

The Quickshell UI provides most of the new motion, but compositor motion should
be tuned to match it.

Proposed changes after side-by-side testing:

- Change workspace animation from plain fade to a short `slidefade` of roughly
  15–20% travel.
- Add explicit `layersIn` and `layersOut` styles for Quickshell surfaces.
- Add special-workspace entrance/exit animation.
- Consider enabling `animate_manual_resizes` after checking latency.
- Preserve fast window motion and restrained pop-in.
- Do not add continuously rotating border animations.
- Keep motion blur disabled initially; it has a higher performance cost and is
  not necessary for the intended feel.

Layer rules will add blur/ignore-alpha behavior for namespaces such as:

- `zac-shell-bar`
- `zac-shell-popup`
- `zac-shell-notifications`
- `zac-shell-osd`

## 24. Keybindings and interactions

Existing application and window-management bindings remain unchanged.

Bindings to add or redirect:

- Toggle Bluetooth panel.
- Toggle audio panel.
- Toggle network panel.
- Toggle calendar.
- Toggle notification center.
- Close active shell panel.
- Reload Quickshell during development.
- Volume/mic/brightness keys routed through the new OSD path.

Existing direct Bluetooth shortcuts may remain:

- Connect the known headset.
- Disconnect the known headset.
- Open Overskride.

The shell must observe those out-of-band operations through native BlueZ state
and update immediately.

Mouse behavior will be consistent:

- Left click: primary action/open.
- Right click: details/context or existing expert UI.
- Middle click: secondary action where conventional.
- Wheel: adjust values only on controls where accidental scrolling is safe.
- Hover: visual affordance, not essential information.

## 25. Error handling and degraded modes

Every integration must have a useful unavailable state:

- No Bluetooth adapter: panel explains that no adapter is present and offers
  the external manager shortcut.
- BlueZ disabled: power action remains available where possible.
- No PipeWire sink/source: show “No audio device,” never dereference null.
- No MPRIS players: media capsule disappears cleanly.
- No battery: battery capsule disappears.
- NetworkManager unavailable: static disconnected state and diagnostic text.
- Notification server registration failure: log prominently and avoid repeated
  retry loops.
- Missing icon/art: semantic fallback glyph/gradient.
- Helper failure: bounded error card with retry and journal context.

The shell process should not crash because one service is absent. The VM host is
especially useful for testing missing-hardware paths.

## 26. Security and privacy

- Do not interpolate network passwords, SSIDs, device aliases, notification
  text, or media metadata into shell command strings.
- Prefer direct APIs and argument arrays.
- Password fields must mask input and clear after submission/close.
- Do not write Wi-Fi passwords to logs, cache, or shell history.
- Notification markup must be rendered safely within QML's supported subset.
- External URLs from notifications require deliberate user action.
- Destructive Bluetooth forget/block and session power actions require
  confirmation.
- No anonymous telemetry.
- Weather/location and online wallpaper search remain disabled unless explicitly
  configured.

## 27. Performance targets

Targets are guidelines to catch regressions:

- Idle shell CPU should normally round to 0% and remain well below 1% averaged
  over time on the desktop.
- No hidden `Canvas`, shader, Cava reader, or frame animation should request
  continuous frames.
- Memory target: below approximately 250 MiB for the initial complete shell;
  investigate anything approaching the reference project's reported 500 MiB.
- Popup open response should begin within one rendered frame after input.
- No subprocess spawned per animation frame or per bar instance.
- System stats are collected once globally and shared by all monitors.
- Models are reused; popups may be lazily instantiated and cached.
- Large image thumbnails are asynchronous and size-bounded.

There will be a performance/gaming toggle that disables ambient animation,
visualizers, expensive blur-adjacent effects, and unnecessary polling without
disabling essential UI.

## 28. Accessibility and usability

- Every icon-only control has an accessible name and tooltip.
- Color is not the sole signal for connected, muted, urgent, or failed states.
- Text contrast is checked over translucent backgrounds.
- Minimum pointer hit targets are maintained even in compact mode.
- Keyboard navigation works inside focused panels.
- Escape closes the active popup/dialog before affecting other applications.
- Logical tab order matches visual order.
- Reduced-motion is a first-class setting.
- Important values use text in addition to animated graphics.

## 29. Logging and diagnostics

The systemd unit's journal is the primary runtime log. Logging guidelines:

- Concise service startup summary.
- Screen creation/removal and monitor mapping at info/debug level.
- Notification-server ownership failure at error level.
- BlueZ operation start/result/timeout without sensitive metadata beyond device
  address/name already visible locally.
- Helper stderr captured with component prefix.
- Avoid logging every value change, animation frame, audio level, or position
  update.

Add a diagnostic command that reports:

- Quickshell version and running instance.
- Detected screens and Hyprland monitor mappings.
- Notification server ownership.
- PipeWire default sink/source availability.
- Bluetooth adapters and connected-device count.
- Network backend availability.
- Current backend selection.

## 30. Testing strategy

### 30.1 Static and build validation

- Format Nix files with the repository's formatter.
- Evaluate `desktop`, `laptop`, and `vm` configurations.
- Build the relevant Home Manager activation or full system closure when
  practical.
- Run Quickshell/QML static tooling available in the pinned package or Qt.
- Start the shell against a nested/headless Wayland compositor if viable.
- Check journal for QML binding loops, missing imports, and null dereferences.

### 30.2 Host matrix

| Scenario | Required checks |
|---|---|
| Laptop only | scale 2, battery, brightness, power profile, 120 Hz |
| Desktop dual monitor | portrait + landscape, fractional scales, split workspaces |
| Desktop single monitor | unplug either monitor and retain usable bar/popups |
| Hotplug | add/remove monitor without restarting shared services |
| VM/no hardware | no battery/Bluetooth/audio assumptions crash the shell |

### 30.3 Workspace tests

- Correct buttons per monitor.
- Empty, occupied, active, focused, urgent, and fullscreen states.
- Click and scroll activation.
- Directional elastic indicator.
- Move a window between monitor-bound workspaces.
- Runtime `nwg-displays` layout changes.

### 30.4 Bluetooth tests

- Adapter absent, off, on, discovering.
- Pair a mouse/keyboard or another simple device.
- Pair a device requiring confirmation/passkey.
- Connect and disconnect the known headset.
- Connect at least two devices simultaneously.
- Connect/disconnect two devices in quick succession.
- Display battery for a reporting device and omit it for a non-reporting one.
- Trust/untrust, block/unblock, forget confirmation.
- Adapter disabled during connection attempt.
- Device leaves range mid-operation.
- Restart BlueZ while panel is open.
- Run direct `bluetoothctl` commands and verify the UI reacts.

### 30.5 Audio/media tests

- No sink/source.
- Built-in and Bluetooth output switching.
- Mute and rapid key-repeat volume changes.
- Per-app streams appearing/disappearing.
- Microphone mute and capture state.
- Multiple MPRIS players.
- Broken/missing album art URLs.
- Seek-capable and non-seek-capable players.
- EasyEffects running/not running.

### 30.6 Notification tests

- Low/normal/critical urgency.
- Replacement ID updates.
- Images, markup, long text, actions.
- Timeout pause on hover.
- DND.
- Clear one/group/all.
- Monitor focus changes while a toast exists.
- Restart shell and ensure notification bus recovery.

### 30.7 Performance tests

- Idle for at least ten minutes.
- Panel open with animations complete.
- Bluetooth scanning.
- Cava/media visualization running.
- Rapid workspace switching.
- Notification burst.
- Monitor hotplug.
- Gaming/performance mode.

Track CPU, memory, frame pacing, Quickshell logs, and Hyprland render behavior.

## 31. Implementation phases

### Phase 0: Backend switch and shell skeleton

Deliverables:

- Backend option.
- Quickshell package/config deployment.
- User service and journal logging.
- `ShellState`, `Theme`, `Motion`, `Metrics`.
- Per-screen empty bar, popup, OSD, and toast hosts.
- Legacy stack still selectable and tested.

Exit criteria:

- All hosts evaluate.
- Every connected monitor gets exactly one correctly scaled bar shell.
- Switching back starts the legacy stack and no Quickshell process.

### Phase 1: Bar, workspace, tray, clock

Deliverables:

- Segmented responsive bar.
- Launcher capsule.
- Native system tray with menus.
- Monitor-filtered workspace strip and elastic indicator.
- Clock/date.
- Startup choreography.

Exit criteria:

- Daily workspace and tray workflows no longer require Waybar.
- Desktop dual-monitor workspace ownership is correct.
- Portrait and laptop layouts do not overflow.

### Phase 2: Shared popup host and audio/OSD

Deliverables:

- Morphing popup router.
- PipeWire service.
- Master output/input controls.
- Device switching.
- Application streams.
- Volume/brightness/mic/lock-key OSDs.
- Updated hardware keybindings.

Exit criteria:

- SwayOSD can be stopped in the Quickshell backend.
- Rapid key repeats remain responsive.
- Popup opens on the invoking/focused monitor.

### Phase 3: Bluetooth manager

Deliverables:

- Adapter state and controls.
- Connected, paired, and discovered sections.
- Multiple connected-device cards.
- Battery and device-type mapping.
- Per-device operation state and errors.
- Pairing/confirmation flow or explicit Overskride fallback.
- Bluetooth bar summary and OSD events.

Exit criteria:

- At least two concurrent connected devices are represented and independently
  controllable.
- Pair/connect/disconnect/forget workflows are reliable.
- No polling of `bluetoothctl` is required for normal state.

### Phase 4: Media, network, battery, system, session

Deliverables:

- Media capsule/panel.
- Network summary/panel.
- Battery/power profile panel.
- Resource polling/system panel.
- Session actions with confirmation.

Exit criteria:

- All current Waybar status information has an equal or better home.
- Laptop power/brightness behavior is complete.
- Desktop correctly omits unavailable battery UI.

### Phase 5: Notifications

Deliverables:

- Notification server.
- Toast layer.
- Notification center, DND, actions, history.
- Bell status in the bar.
- Conditional shutdown of SwayNC.

Exit criteria:

- Common notification conformance cases work.
- No competing notification daemon.
- Critical notifications remain visible and actions execute.

### Phase 6: Polish and expressive features

Deliverables:

- Calendar panel.
- Cava visualizer.
- Fluid audio fill.
- Wallpaper picker/transition integration.
- Optional shell-only Matugen palette.
- Reduced-motion and gaming modes.
- Final Hyprland animation tuning.

Exit criteria:

- No hidden continuous animation consumes resources.
- Visual language is consistent across all panels.
- Terminal configuration remains unchanged.

### Phase 7: Burn-in and default switch

Deliverables:

- Multi-day daily-driver burn-in.
- Performance report.
- Known-issues list.
- Rollback test.
- Quickshell becomes the selected backend only after acceptance.

## 32. Rollout and rollback procedure

### Rollout

1. Implement with `legacy` still the default.
2. Run Quickshell manually by named config alongside a temporarily hidden legacy
   bar, but do not allow both notification servers.
3. Validate desktop dual-monitor behavior.
4. Validate laptop behavior.
5. Switch the backend option to `quickshell`.
6. Rebuild and restart the graphical session/user units.
7. Run the diagnostic command and inspect journal errors.

### Immediate rollback

1. Set the backend option to `legacy`.
2. Rebuild.
3. Restart the relevant user units or log out/in.
4. Confirm Waybar, SwayNC, and SwayOSD are running and Quickshell is stopped.

No configuration migration should be required for rollback because the legacy
files were never removed.

### Emergency runtime fallback

The module README will include explicit commands to:

- Stop the Quickshell user unit.
- Start Waybar, SwayNC, and SwayOSD for the current session.
- Inspect Quickshell logs.

These commands are for recovery only; declarative backend selection remains the
source of truth.

## 33. Acceptance criteria

The implementation is complete only when all of the following are true:

- Every connected monitor has one correctly placed, scaled bar.
- Monitor hotplug does not duplicate the notification server or global service
  polling.
- Workspace buttons are monitor-correct and the active indicator animates
  directionally.
- Tray activation and native context menus work.
- Audio output/input, mute, default-device switching, and per-app streams work.
- Volume and brightness OSDs replace SwayOSD without losing locked/repeat key
  behavior.
- Bluetooth shows all connected devices at once and independently controls
  them.
- Bluetooth pair/connect/disconnect/forget and failure recovery are usable.
- Media controls support multiple MPRIS players.
- Network and battery panels degrade cleanly when hardware is absent.
- Notifications support critical urgency, images, actions, DND, and history.
- Popups originate on the correct monitor and remain within its bounds.
- The shell is responsive at laptop scale 2 and desktop fractional scales.
- Idle resource use is acceptable and hidden animation does not request frames.
- Reduced-motion and performance modes work.
- Ghostty and terminal configuration are untouched.
- Setting the backend to `legacy` restores Waybar, SwayNC, and SwayOSD.
- Desktop, laptop, and VM Nix configurations evaluate successfully.

## 34. Recommended first implementation milestone

The first milestone should be substantial enough to test the architecture but
small enough to diagnose:

1. Backend switch and systemd service.
2. Multi-monitor bottom bars.
3. Native tray.
4. Monitor-correct workspaces with elastic indicator.
5. Clock and launcher.
6. Morphing popup host.
7. PipeWire volume capsule and replacement volume OSD.

Bluetooth follows immediately as its own focused milestone. Implementing it
after the popup host and shared controls are proven avoids debugging BlueZ,
multi-monitor routing, animation geometry, and basic component styling all at
once.

## 35. Final architectural position

The shell should behave like a small desktop environment layer, not a collection
of scripts that happen to draw widgets. Quickshell owns presentation and
reactive interaction; Hyprland owns windows and workspaces; PipeWire owns audio;
BlueZ owns Bluetooth; NetworkManager owns networking; UPower owns battery state;
Stylix supplies the stable palette; Nix owns deployment and backend selection.

That separation is what makes an aggressive implementation maintainable. It
also preserves the most important safety property of this project: the new
desktop can be rich, animated, and deeply integrated without making the current
working environment difficult to restore.
