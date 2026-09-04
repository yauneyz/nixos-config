# Sunshine and Moonlight setup

Sunshine runs on the NixOS desktop and streams its complete display and system
audio. Moonlight runs on the TCL Google TV and acts as the receiver. This works
like wireless HDMI: VLC, browsers, Steam, games, and other desktop applications
do not need Chromecast support.

For direct library playback without screen capture, see the
[Kodi setup](kodi-setup.md).

## What is configured

The desktop imports `hosts/desktop/sunshine.nix`, which:

- starts Sunshine with the Hyprland graphical session;
- opens the Sunshine/Moonlight ports in the NixOS firewall;
- captures Hyprland through the `wlr` screen-capture protocol;
- uses the NVIDIA GPU's NVENC hardware encoder; and
- gives `zac` access to `uinput` for forwarded controllers, keyboards, and mice.

The shared GUI package list installs the Moonlight client on both the desktop
and laptop. Tailscale is enabled on those two machines so the laptop can reach
Sunshine privately while away from home.

Sunshine configuration is declarative. Change capture or encoder settings in
`hosts/desktop/sunshine.nix`, then rebuild, rather than changing those settings
in Sunshine's web interface.

## Install and start Sunshine

From the NixOS configuration checkout, rebuild the desktop:

```console
sudo nixos-rebuild switch --flake .#desktop
```

Rebuild the laptop as well so it receives Moonlight and Tailscale:

```console
sudo nixos-rebuild switch --flake .#laptop
```

Reboot afterward. A reboot ensures the `uinput` kernel support, group membership,
and user service are all active. On later rebuilds, a reboot is normally not
necessary.

After signing into Hyprland, verify Sunshine is running:

```console
systemctl --user status sunshine
```

Sunshine only streams the signed-in graphical session. Keep the desktop awake,
unlocked, and connected to a physical display while using it.

## First-time Sunshine setup

1. On the desktop, open <https://localhost:47990>.
2. Accept the browser warning for Sunshine's locally generated certificate.
   This warning is expected for the local web interface.
3. Create the Sunshine web-interface username and password when prompted.
4. Leave this page available for the pairing PIN.

Do not expose the Sunshine web interface or streaming ports through the router.
They are intended for the local network.

## Install and pair Moonlight on the TCL Google TV

1. Open the Play Store on the TV.
2. Install **Moonlight Game Streaming**.
3. Confirm the TV and desktop are on the same home network. The desktop may use
   Ethernet while the TV uses Wi-Fi, as long as the router does not isolate the
   Wi-Fi clients.
4. Open Moonlight. Select the desktop when it appears.
5. If it is not discovered, choose **Add PC manually** and enter
   `10.1.10.188`, the desktop's configured LAN address.
6. Moonlight displays a PIN. Enter it in Sunshine's PIN page at
   <https://localhost:47990>.
7. Refresh Moonlight if necessary. The paired desktop should now be available.

Pairing is normally permanent. Repeat it only after clearing Sunshine's state,
reinstalling Moonlight, or deliberately removing the client.

## Recommended Moonlight settings

Begin with these settings in the Moonlight TV app:

| Setting | Starting value |
| --- | --- |
| Resolution | 1920x1080 |
| Frame rate | 60 FPS |
| Bitrate | 20-30 Mbps |
| Codec | HEVC/H.265 preferred |
| HDR | Off initially |
| Audio | Stereo, unless the TV/audio system supports surround |

After confirming that the stream is stable, try 4K at 60 FPS and roughly
50-80 Mbps. Reduce bitrate first if the picture freezes, becomes blocky, or
Moonlight reports network jitter. A wired desktop and either Ethernet or strong
5/6 GHz Wi-Fi at the TV give the best results.

Enable the TV's **Game Mode** for gaming. Disable motion smoothing and similar
picture processing because it adds input latency.

## Watching videos and other desktop content

1. Sign into Hyprland on the desktop and make sure Sunshine is running.
2. Open Moonlight on the TV.
3. Select the desktop, then launch the **Desktop** entry.
4. On the PC, open VLC, a browser, or another application and play the content.
5. Make the player full-screen on the monitor being streamed.
6. Use the PC's keyboard and mouse normally. Moonlight can also forward input
   from a supported TV remote, keyboard, mouse, or controller.
7. When finished, use Moonlight's Back/Quit action to end the stream. Closing
   the stream does not close VLC or other applications on the desktop.

Sunshine captures the current default PipeWire audio output. If the picture
works but audio does not, use `pavucontrol` on the desktop to confirm that the
application is playing to the expected default output.

Screen capture is not the same as sending the original video file. It encodes
what appears on the desktop, so it uses some GPU resources and the output is
limited to the selected stream resolution and frame rate. DRM-protected video
may intentionally produce a black image; normal VLC files are unaffected.

## Steam gaming

The simplest workflow is to stream the desktop and then start Steam:

1. Pair the controller with the Google TV under **Settings > Remotes &
   Accessories**, or connect it by USB. A controller can instead remain paired
   directly to the PC if it has enough range.
2. Open Moonlight and launch **Desktop**.
3. Start Steam on the desktop and enter Big Picture Mode.
4. Start the game. Controller input connected to the TV is forwarded through
   Moonlight and Sunshine to the PC.
5. Exit the game normally, then quit the Moonlight stream.

If a game does not recognize the forwarded controller, first reboot after the
Sunshine installation, then confirm that the user has the expected group:

```console
id -nG zac
```

The output should include `uinput`. Steam Input can be enabled or disabled per
game if a title has double-input or incorrect button mappings.

## Remote gaming from the laptop over the internet

The configuration enables Tailscale on the desktop and laptop. Tailscale gives
both machines private addresses on an authenticated encrypted network, even
when they are behind different routers or carrier-grade NAT. This avoids
publishing Sunshine directly to the internet.

Do **not** enable Sunshine UPnP and do not create router port forwards for this
setup. The NixOS firewall permits Sunshine locally, while Tailscale provides the
private route between the two machines.

### One-time Tailscale setup

After rebuilding, authenticate Tailscale on the desktop:

```console
sudo tailscale up
```

Open the URL printed by the command and sign in. Repeat the same command on the
laptop and sign in to the same Tailscale account/tailnet.

Confirm that both machines appear on each other:

```console
tailscale status
```

On the desktop, record its Tailscale IPv4 address:

```console
tailscale ip -4
```

It will normally be in the `100.x.y.z` range. If MagicDNS is enabled in the
Tailscale admin console, the desktop's Tailscale hostname can be used instead.

### Pair the laptop with Sunshine

Pair while both machines are still at home if practical. This makes the first
setup easier, although pairing through Tailscale also works.

1. Make sure Sunshine is running on the desktop and both machines show as
   connected in `tailscale status`.
2. Launch **Moonlight** from the laptop's application launcher, or run
   `moonlight`.
3. Choose **Add PC manually**.
4. Enter the desktop's `100.x.y.z` Tailscale address or MagicDNS hostname. Do
   not enter its home-only `10.1.10.188` address for remote use.
5. Select the newly added desktop. Moonlight displays a pairing PIN.
6. On the desktop, open <https://localhost:47990>, go to the PIN page, and enter
   the code.
7. Start **Desktop** or **Steam** once to verify the pairing.

Before relying on it during a trip, test from a genuinely external connection:
disconnect the laptop from home Wi-Fi and connect it through a phone hotspot.

### Day-to-day remote play

Before leaving home:

- leave the desktop powered on, awake, logged into Hyprland, and with its
  physical display connected;
- confirm Sunshine and Tailscale are running; and
- avoid logging out or allowing the host display to sleep, because Sunshine
  cannot capture a graphical session that is not available.

On the remote laptop:

1. Connect to the internet and confirm `tailscale status` shows the desktop.
2. Open Moonlight and select the entry using the Tailscale address.
3. Launch **Steam** or **Desktop**.
4. Connect a controller to the laptop by Bluetooth or USB. Moonlight forwards
   it to Sunshine just as it does from the Google TV.

For remote networks, start with 1080p60 at 10-20 Mbps. The chosen bitrate must
fit comfortably below the home connection's upload speed as well as the
laptop's download speed. Lower it on hotel Wi-Fi or a mobile hotspot.

Check whether Tailscale obtained a direct peer-to-peer path:

```console
tailscale ping desktop
```

Replace `desktop` with the Tailscale hostname or address if necessary. A
`direct` result is best for gaming. A `DERP`/relay result still works but
usually has more latency. The configuration opens Tailscale's UDP port to make
a direct path more likely, but restrictive NAT or public Wi-Fi can still force
a relay.

Tailscale does not wake or log into the desktop by itself. Keep the host awake
for the initial setup; Wake-on-LAN over Tailscale can be added separately if
needed. Also check the Tailscale admin console before a long trip to make sure
the desktop's device key will not expire while away.

### Remote connection troubleshooting

- Run `tailscale status` on both machines. If either says it needs login, run
  `sudo tailscale up` again and authenticate.
- Run `tailscale ping desktop` from the laptop before troubleshooting
  Moonlight.
- Use the desktop's Tailscale address, not `10.1.10.188`, when away from home.
- NordVPN can interfere with Tailscale routes. Disconnect NordVPN while testing
  or configure it to allow local/private network traffic.
- If Moonlight finds the host but streaming fails, check
  `journalctl --user -u sunshine -b` on the desktop.
- If the connection works but latency is high, lower the bitrate and check
  whether `tailscale ping` reports a relayed rather than direct path.

## Retroid Pocket 3+ client

The Retroid Pocket 3+ runs Android and has a 1334x750, 60 Hz display, so it can
use the regular Android Moonlight client. Its built-in controls are forwarded
to Sunshine as a gamepad.

### Install Moonlight

1. Open the Play Store on the Retroid.
2. Install **Moonlight Game Streaming**.
3. Open Moonlight's settings before pairing and start with:

   | Setting | Recommended value |
   | --- | --- |
   | Video resolution | 720p |
   | Video frame rate | 60 FPS |
   | Video bitrate on the home LAN | 8-15 Mbps |
   | Video bitrate over the internet | 5-10 Mbps initially |
   | Video frame pacing | Balanced |
   | Codec | Prefer HEVC |
   | HDR | Off |
   | Audio | Stereo |
   | On-screen controls | Off |

The Retroid screen is only slightly taller than 720p, so a 1080p stream costs
extra bandwidth and decoding power for little visible benefit. If HEVC causes
decoder crashes, visual corruption, or unusual latency, switch Moonlight to
H.264.

### Pair and play at home

1. Connect the Retroid to the same home network as the desktop. Prefer the
   router's 5 GHz Wi-Fi network.
2. Open Moonlight and select the automatically discovered desktop.
3. If it does not appear, choose **Add PC manually** and enter `10.1.10.188`.
4. Moonlight displays a PIN. Enter it in the Sunshine web interface at
   <https://localhost:47990> on the desktop.
5. Launch **Steam** for Big Picture Mode or **Desktop** for arbitrary programs.

Use Steam Big Picture where possible because its interface is easier to read
and navigate on the Retroid's 4.7-inch screen. The physical Retroid controls
should appear to the desktop as a standard gamepad.

If the face-button actions do not match their labels, enable Moonlight's
**Flip face buttons** setting, which swaps A/B and X/Y. Leave Moonlight's
on-screen controls disabled unless you need a missing button. Long-pressing
Start toggles Moonlight's gamepad mouse-emulation mode; the sticks then move the
desktop pointer, A left-clicks, and B right-clicks. The touchscreen can also be
configured as either a trackpad or direct pointer in Moonlight's input settings.

### Play remotely through Tailscale

1. Install **Tailscale** from the Play Store on the Retroid.
2. Sign in to the same Tailscale account used by the desktop and laptop.
3. Connect Tailscale and confirm the desktop appears in its device list.
4. In Moonlight, choose **Add PC manually** and enter the desktop's Tailscale
   `100.x.y.z` address or MagicDNS hostname. Do not use `10.1.10.188` away from
   home.
5. Pair this Moonlight installation with Sunshine using the displayed PIN.
6. Test the complete remote path from a phone hotspot before traveling.

Keep the Tailscale VPN active for the entire remote session. If Android stops
Tailscale in the background, exclude it from battery optimization and reconnect
before opening Moonlight.

For mobile hotspots and public Wi-Fi, begin at 720p60 and 5 Mbps. Raise the
bitrate gradually if Moonlight's performance overlay shows no network frame
drops. Switch to 30 FPS or reduce the bitrate further when the connection is
unstable. Remote quality is limited primarily by the home's upload speed and
the latency between the Retroid and desktop.

### Retroid troubleshooting

- If no input reaches the game, reboot the desktop once, confirm `zac` belongs
  to `uinput`, and restart Sunshine.
- If buttons are reversed, toggle **Flip face buttons** in Moonlight rather than
  remapping every Steam game.
- If the image freezes while audio continues, lower the bitrate and try H.264.
- If controls work in Moonlight but not in a game, toggle Steam Input for that
  game.
- If remote play cannot find the host, reconnect Tailscale and add the
  Tailscale address manually; Android discovery does not cross the VPN by
  itself.
- If battery life matters more than responsiveness, use 720p30 and enable
  Moonlight's refresh-rate reduction option.

## Day-to-day controls

Sunshine starts automatically whenever the Hyprland graphical session starts.
Useful manual commands are:

```console
systemctl --user status sunshine
systemctl --user restart sunshine
systemctl --user stop sunshine
systemctl --user start sunshine
journalctl --user -u sunshine -b
```

The last command shows Sunshine logs from the current boot and is the first
place to look when capture, encoding, or controller forwarding fails.

## Troubleshooting

### Moonlight cannot find the desktop

- Add `10.1.10.188` manually in Moonlight.
- Confirm both devices are on the same LAN and the TV is not on a guest network.
- Temporarily disconnect NordVPN, or enable its local-network/LAN access.
- Check `systemctl --user status sunshine` on the desktop.
- Restart Sunshine with `systemctl --user restart sunshine`.

### The stream is black or Sunshine reports capture failure

First inspect the logs:

```console
journalctl --user -u sunshine -b
```

The configured `wlr` backend is the preferred Hyprland path. If it fails on the
installed NVIDIA/Hyprland versions, use DRM/KMS capture as a fallback by changing
`hosts/desktop/sunshine.nix` to:

```nix
services.sunshine = {
  enable = true;
  autoStart = true;
  openFirewall = true;
  capSysAdmin = true;

  settings = {
    capture = "kms";
    encoder = "nvenc";
  };
};
```

Then rebuild and restart the graphical session. `capSysAdmin` grants Sunshine a
powerful, root-equivalent capability, which is why the configuration tries
Hyprland's unprivileged `wlr` capture first.

### Sunshine streams the wrong monitor

Review the startup log for the display names/IDs Sunshine detects:

```console
journalctl --user -u sunshine -b
```

Add the reported desired display to the declarative settings:

```nix
settings = {
  capture = "wlr";
  encoder = "nvenc";
  output_name = "DISPLAY_REPORTED_BY_SUNSHINE";
};
```

Rebuild and restart Sunshine afterward.

### The stream stutters or has high latency

- Enable Game Mode on the TV.
- Lower Moonlight to 1080p60 and 20 Mbps as a baseline.
- Prefer Ethernet for the TV, or use 5/6 GHz Wi-Fi with a strong signal.
- Avoid guest Wi-Fi, mesh hops, VPN routing, and simultaneous large downloads.
- Increase bitrate only after the stream is stable.
- Check Moonlight's performance overlay to distinguish network, decode, and
  host-rendering latency.

### Video works but audio does not

- Confirm the application is audible locally and visible in `pavucontrol`.
- Check the default PipeWire/PulseAudio sink with `pactl info`.
- Restart Sunshine after changing the default sink.
- Begin with stereo in Moonlight before enabling 5.1 or 7.1 audio.

### The controller does not work

- Reboot once after enabling Sunshine.
- Confirm `id -nG zac` includes `uinput`.
- Re-pair the controller with Google TV and restart Moonlight.
- Test both Steam Input enabled and disabled for the affected game.
- If the controller is paired directly with the PC, confirm it works locally
  before starting Moonlight.

## References

- [Sunshine documentation](https://docs.lizardbyte.dev/projects/sunshine/latest/)
- [Sunshine configuration reference](https://docs.lizardbyte.dev/projects/sunshine/latest/md_docs_2configuration.html)
- [Moonlight for Android and Google TV](https://play.google.com/store/apps/details?id=com.limelight)
- [Moonlight Android releases](https://github.com/moonlight-stream/moonlight-android/releases)
- [Moonlight setup and internet-streaming guide](https://github.com/moonlight-stream/moonlight-docs/wiki/Setup-Guide)
- [NixOS Sunshine guide](https://wiki.nixos.org/wiki/Sunshine)
- [Tailscale Linux installation and authentication](https://tailscale.com/docs/install/linux)
