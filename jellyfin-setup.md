# Jellyfin setup

Jellyfin is the remote-friendly media layer for this setup. It catalogs the
same files under `/home/zac/Videos` that Kodi reads over SMB, remembers watch
state per user, and automatically direct-plays, remuxes, or transcodes media to
fit each client. Remote access uses Tailscale instead of public port forwarding.

Use each tool for its strength:

- **Kodi + SMB:** direct original-file playback on the home LAN.
- **Kodi + JellyCon:** Kodi's interface with Jellyfin users and watch state.
- **Jellyfin clients:** the easiest local and remote movie/TV experience.
- **Sunshine + Moonlight:** live desktop applications and games.

See [Kodi setup](kodi-setup.md) and
[Sunshine/Moonlight setup](sunshine-setup.md) for those companion systems.

## What NixOS configures

The desktop imports `hosts/desktop/jellyfin.nix`, which:

- runs Jellyfin as a system service;
- stores its database, metadata, logs, and cache under `/data/jellyfin`;
- grants the Jellyfin service read access to user media and NVIDIA devices;
- uses the RTX 4090 for NVDEC/NVENC transcoding and HDR tone mapping;
- enables hardware H.264, HEVC, and AV1 encoding where clients support it;
- opens HTTP port 8096 only on `enp6s0` and `tailscale0`;
- opens local discovery port 7359 only on the home Ethernet interface; and
- waits for `/home/zac/Videos` to be mounted before starting.

The shared GUI package list installs **Jellyfin Desktop** on both the NixOS
desktop and laptop.

## Install and open the server

Rebuild the desktop:

```console
sudo nixos-rebuild switch --flake .#desktop
```

Check the service:

```console
systemctl status jellyfin
```

Open the initial setup wizard on the desktop:

<http://localhost:8096>

The first account created by the wizard is the administrator. Give it a strong
password; anyone with this account can change the server and access all media.

## Complete the setup wizard

1. Select the preferred interface language.
2. Create the administrator account and password.
3. Add separate media libraries:

   | Library | Content type | Folder |
   | --- | --- | --- |
   | Movies | Movies | `/home/zac/Videos/Movies` |
   | TV Shows | Shows | `/home/zac/Videos/TV Shows` |
   | Home Videos | Photos or mixed content | `/home/zac/Videos/Home Videos` |

4. Choose the preferred metadata language and country.
5. Enable remote connections, because Tailscale clients arrive through another
   network interface.
6. Leave automatic port mapping/UPnP **disabled**. Tailscale provides remote
   access without opening the home router.
7. Finish the wizard and sign in.

If a media directory is missing, create it as `zac` beneath `~/Videos`, then
add the library from **Administration Dashboard > Server > Libraries**.

## Create a playback user

Do not sign every TV or handheld into the administrator account.

1. Open **Administration Dashboard > Server > Users**.
2. Add a user for ordinary playback.
3. Give it a strong password.
4. Grant access only to the desired libraries.
5. Leave server-management permissions disabled.
6. Keep **Allow remote connections to this server** enabled for devices that
   will connect through Tailscale.

Use this account on the TCL TV, Retroid, laptop, and JellyCon. Jellyfin keeps
that user's favorites, playback progress, and watched state synchronized.

## Install clients

### TCL Google TV

1. Open the Play Store.
2. Install **Jellyfin for Android TV**.
3. Add server `http://10.1.10.188:8096`.
4. Sign in with the playback account, or use Quick Connect and authorize the
   displayed code from an already signed-in Jellyfin session.

Use the native Android TV client for the simplest experience. To retain Kodi's
interface, follow the JellyCon section in [kodi-setup.md](kodi-setup.md).

### NixOS laptop and desktop

After rebuilding each system, launch **Jellyfin Desktop** from the application
launcher or run:

```console
jellyfin-desktop
```

Use `http://10.1.10.188:8096` while at home. The web interface works at the
same address in Firefox or Chrome if the desktop client is unavailable.

### Retroid Pocket 3+

1. Install **Jellyfin** from the Play Store.
2. At home, connect to `http://10.1.10.188:8096`.
3. Sign in with the playback account.
4. In client playback settings, prefer the integrated/native player first.
   Try the web player or an external player only if a particular file fails.

The Retroid's 750p screen does not benefit much from a remote stream above
720p. Set a client bitrate around 5-10 Mbps when away from home.

## Remote streaming through Tailscale

Jellyfin is not exposed directly to the internet. Every remote client must join
the same Tailscale network as the desktop.

The desktop and laptop already receive Tailscale from the NixOS configuration.
Authenticate them once with:

```console
sudo tailscale up
```

On Android/Google TV devices that need remote access, install Tailscale from
Google Play and sign in to the same account.

Find the desktop's Tailscale address:

```console
tailscale ip -4
```

It normally starts with `100.`. On a remote client:

1. Connect Tailscale.
2. Open Jellyfin or Jellyfin Desktop.
3. Add `http://100.x.y.z:8096`, substituting the desktop's actual Tailscale
   address. A MagicDNS hostname may be used instead.
4. Sign in with the playback account.

No router port forwarding, public DNS, HTTPS certificate, or reverse proxy is
required. Tailscale encrypts the connection between devices. Do not forward
ports 8096 or 8920 through the router.

Before traveling, test through a phone hotspot and confirm the desktop remains
powered on. Unlike Sunshine, Jellyfin runs at the login screen and does not
require Hyprland or a connected monitor.

## Remote quality and transcoding

Jellyfin attempts playback in this order:

1. **Direct Play:** sends the original file unchanged.
2. **Direct Stream/remux:** repackages compatible audio and video without
   re-encoding the video.
3. **Transcode:** converts incompatible or overly large media to suit the
   client and configured bitrate.

For remote clients, choose a bitrate below the home's measured upload speed.
Useful starting points are:

| Connection | Starting maximum bitrate |
| --- | --- |
| Poor hotel Wi-Fi or cellular | 3-5 Mbps, 720p |
| Good cellular or Wi-Fi | 8-12 Mbps, 1080p |
| Strong remote connection | 15-25 Mbps, 1080p |
| Original 4K direct play | Only when upload bandwidth comfortably exceeds the file bitrate |

The NixOS module makes its transcoding configuration authoritative. Change
codec or hardware-acceleration policy in `hosts/desktop/jellyfin.nix`, not the
corresponding dashboard fields, because a service restart restores the NixOS
values.

## Verify NVIDIA hardware transcoding

Start playback on a client and deliberately select a lower quality to force a
transcode. In Jellyfin's dashboard, the active session should say
**Transcoding** rather than Direct Playing.

On the desktop, run:

```console
nvidia-smi
```

The process list should show `jellyfin-ffmpeg` using the GPU. Also inspect:

```console
journalctl -u jellyfin -b
```

The RTX 4090 supports headless NVENC/NVDEC, so the monitor can be off during
Jellyfin transcoding.

## Add and maintain media

Place new files in the same layout described in [kodi-setup.md](kodi-setup.md):

```text
/home/zac/Videos/Movies/Movie Name (Year)/Movie Name (Year).mkv
/home/zac/Videos/TV Shows/Show Name/Season 01/Show Name S01E01.mkv
```

Jellyfin periodically scans its libraries. To make a title appear immediately,
open the dashboard, select **Scan All Libraries**, or scan the individual
library. Correct filenames produce much more reliable metadata matches.

## Troubleshooting

### The web interface does not open

```console
systemctl status jellyfin
journalctl -u jellyfin -b
```

- On the desktop itself, use `http://localhost:8096`.
- At home, use `http://10.1.10.188:8096`.
- Away from home, connect Tailscale and use the desktop's `100.x.y.z` address.
- Do not use HTTPS or port 8920; this setup uses HTTP inside the encrypted
  Tailscale tunnel.

### Libraries are empty or folders cannot be added

Confirm the service account can read the media:

```console
sudo -u jellyfin ls /home/zac/Videos
```

If that fails, inspect the permissions on `~/Videos` and its parent directories.
The configuration adds Jellyfin to the `users` group, but unusually restrictive
files may need group-read permission.

### A remote client cannot connect

- Confirm Tailscale is connected on both devices.
- Run `tailscale ping desktop` from the laptop.
- Use the Tailscale IP rather than `10.1.10.188` remotely.
- Confirm the playback user is allowed remote connections.
- Disconnect NordVPN temporarily if it is intercepting private-network routes.
- Do not troubleshoot with router port forwarding; it is unnecessary here.

### Playback buffers

- Lower the client bitrate until it is comfortably below home upload capacity.
- Check whether the dashboard reports Direct Play or Transcoding.
- Force a transcode for very high-bitrate files on limited remote links.
- Avoid image-based subtitles when possible; burning them into video forces a
  transcode and can be costly.
- Use `nvidia-smi` to confirm the transcode is using the GPU.

### Transcoding fails

```console
nvidia-smi
journalctl -u jellyfin -b
```

Confirm `/dev/nvidia0` exists and that the Jellyfin process appears in
`nvidia-smi` during a forced transcode. Rebuild after NVIDIA driver changes so
the running kernel driver and userspace libraries remain matched.

## Backup and security

- Back up `/data/jellyfin`; it contains accounts, library state, metadata, and
  watch history.
- Media files remain separately under `/home/zac/Videos`.
- Use the administrator account only for administration.
- Port 8096 is limited to the home Ethernet and Tailscale interfaces.
- Never expose SMB port 445 or Jellyfin port 8096 directly to the internet.
- Tailscale access should be removed for lost or retired devices in the
  Tailscale admin console.

## References

- [Jellyfin setup wizard](https://jellyfin.org/docs/general/post-install/setup-wizard/)
- [Jellyfin networking](https://jellyfin.org/docs/general/post-install/networking/)
- [Jellyfin with Tailscale](https://jellyfin.org/docs/general/post-install/networking/tailscale/)
- [NVIDIA hardware acceleration](https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/nvidia/)
- [Jellyfin clients](https://jellyfin.org/downloads/)
- [Jellyfin Kodi add-ons](https://jellyfin.org/docs/general/clients/kodi/)
