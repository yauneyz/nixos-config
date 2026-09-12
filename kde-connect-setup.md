# KDE Connect phone remote

KDE Connect lets an Android phone control media playing on the NixOS desktop,
independently of Sunshine and Moonlight. It works with VLC and other Linux
players that expose the standard MPRIS media-control interface.

## What is configured

The desktop imports `hosts/desktop/kde-connect.nix`, which enables NixOS's KDE
Connect module. The module installs KDE Connect and opens its standard TCP and
UDP port range, 1714-1764. Hyprland starts `kdeconnect-indicator` with the
graphical session, which also ensures the KDE Connect daemon is running and
provides a tray entry for pairing and status.

This does not require the KDE Plasma desktop. Media control uses the session
D-Bus and MPRIS interfaces and works under the existing Wayland/Hyprland
session.

## Install and start

Rebuild the desktop:

```console
sudo nixos-rebuild switch --flake .#desktop
```

Log out of Hyprland and back in once so the new tray indicator is started. To
start it immediately without logging out, launch **KDE Connect Indicator** from
the application launcher or run:

```console
kdeconnect-indicator
```

## Pair the phone

1. Install **KDE Connect** from Google Play or F-Droid on the phone.
2. Put the phone and desktop on the same home network. They do not have to use
   the same connection type; Wi-Fi on the phone and Ethernet on the desktop is
   fine.
3. Open KDE Connect on the phone.
4. Select the desktop named **desktop**, then tap **Request pairing**.
5. Accept the request from the desktop notification or KDE Connect Indicator.

Both devices must see and accept the pairing. Pairing is retained across
reboots.

If the phone cannot discover the desktop, make sure it is not on guest Wi-Fi,
temporarily disable NordVPN, and run:

```console
kdeconnect-cli --refresh
kdeconnect-cli --list-available
```

## Play and pause desktop video

1. Start VLC, Spotify, or another media player on the desktop.
2. Start the video or music normally.
3. On the phone, open KDE Connect, select **desktop**, and choose
   **Multimedia control**.
4. Choose the desired player if more than one appears.
5. Use play/pause, previous/next, seeking, or volume from the phone.

This works while Moonlight is streaming the desktop to the TV. The video and
audio continue to travel through Sunshine/Moonlight; KDE Connect sends only the
control commands. The Moonlight app can remain full-screen on the TV.

VLC should appear automatically. To see which applications currently expose
media controls, run:

```console
playerctl --list-all
```

For browser video, Firefox and Chromium-based browsers normally expose an
MPRIS player while media is active. If a browser does not appear, use KDE's
Plasma Browser Integration extension or control VLC instead.

## Remote commands

KDE Connect's **Run commands** plugin can expose a small set of explicit host
commands on the phone. Useful commands for this setup are:

| Name | Command |
| --- | --- |
| Play/Pause | `playerctl play-pause` |
| Previous | `playerctl previous` |
| Next | `playerctl next` |
| Stop | `playerctl stop` |
| Darken/restore monitors | `toggle-monitor-brightness` |

Add them from KDE Connect Indicator on the desktop under **Plugin settings >
Run commands**. Only add commands that are safe to invoke without a terminal;
the paired phone can run every command listed there.

The built-in Multimedia control screen is preferable for ordinary playback
because it shows the active player and track state. The explicit commands are
useful as simple one-tap fallbacks.

## Using it away from home

KDE Connect can also travel over the existing private Tailscale network. Do
not forward KDE Connect ports on the router.

1. Install Tailscale on the phone and sign in to the same tailnet as the
   desktop.
2. Pair KDE Connect on the home LAN first.
3. Connect Tailscale on the phone.
4. In the phone's KDE Connect menu, choose **Add devices by IP** and enter the
   desktop's Tailscale `100.x.y.z` address or MagicDNS name.

Automatic LAN discovery does not cross Tailscale, which is why the address
must be added manually. The desktop must remain powered on, logged into
Hyprland, and connected to Tailscale.

## Wayland and Hyprland limitation

Media control, notifications, file sharing, and Run commands work under this
Wayland/Hyprland setup. KDE Connect's phone-as-touchpad feature is different:
it needs the Wayland RemoteDesktop portal, which the current Hyprland portal
does not yet implement. It may report that remote input is unavailable or fail
to move the pointer.

Use Moonlight's forwarded mouse/controller, a physical input device connected
to the desktop, or KDE Connect's media controls instead. This limitation does
not affect play/pause or the other MPRIS controls described above.

## Useful commands

```console
kdeconnect-cli --list-devices
kdeconnect-cli --list-available
kdeconnect-cli --refresh
pgrep -af kdeconnect
```

To unpair a device, use the phone or indicator UI, or find its ID with
`kdeconnect-cli --list-devices --id-only` and run:

```console
kdeconnect-cli --device DEVICE_ID --unpair
```

## References

- [KDE Connect](https://kdeconnect.kde.org/)
- [KDE Connect user guide](https://userbase.kde.org/KDEConnect/en)
- [NixOS KDE Connect module](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/programs/kdeconnect.nix)
- [Hyprland RemoteDesktop portal status](https://github.com/hyprwm/xdg-desktop-portal-hyprland/issues/252)
