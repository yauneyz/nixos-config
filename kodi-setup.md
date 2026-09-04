# Kodi setup

Kodi complements Sunshine rather than replacing it. Sunshine/Moonlight mirrors
the live desktop and is ideal for games or arbitrary applications. Kodi runs
directly on the TCL Google TV, reads media files from the desktop, and lets the
TV decode and play them without capturing or re-encoding the desktop.

For screen mirroring and game streaming, see the
[Sunshine and Moonlight setup](sunshine-setup.md).

For adaptive remote streaming, centralized users, and synchronized watch state,
see the [Jellyfin setup](jellyfin-setup.md).

## What is installed and configured

The NixOS configuration now provides:

- `kodi-wayland` on both the desktop and laptop;
- an authenticated, read-only SMB share named `Videos` on the desktop;
- `/home/zac/Videos` as the shared media directory;
- SMB2 or newer, with legacy NetBIOS discovery disabled; and
- TCP port 445 available only through the desktop's home Ethernet and Tailscale
  interfaces.

Kodi on the TCL Google TV and Retroid Pocket 3+ is installed from Google Play,
because those devices run Android rather than NixOS.

## Prepare the desktop

Rebuild the desktop:

```console
sudo nixos-rebuild switch --flake .#desktop
```

Create a Samba password for `zac`:

```console
sudo smbpasswd -a zac
```

The Samba password is separate from the Linux login password. Use a strong,
unique password. It will be entered once in Kodi and stored on that device.

Verify the server:

```console
systemctl status samba-smbd
smbclient -L //localhost -U zac
```

The share list should contain `Videos`. Samba starts automatically on future
boots.

## Organize the media library

Kodi produces better matches when each media type has its own source directory.
A useful layout is:

```text
/home/zac/Videos/
├── Movies/
│   ├── Blade Runner (1982)/
│   │   └── Blade Runner (1982).mkv
│   └── Dune (2021)/
│       └── Dune (2021).mkv
├── TV Shows/
│   └── Example Show/
│       ├── Season 01/
│       │   ├── Example Show S01E01.mkv
│       │   └── Example Show S01E02.mkv
│       └── Season 02/
└── Home Videos/
```

For movies, use `Movie Name (Year)` for both the directory and filename. For
television, include season and episode numbers such as `S01E03`. Keep movies,
TV shows, and home videos in separate source directories so Kodi can apply the
correct metadata scraper.

External subtitles should have the same base filename as the video:

```text
Dune (2021).mkv
Dune (2021).en.srt
Dune (2021).es.srt
```

The Samba share is intentionally read-only. Kodi can play and scan media but
cannot rename or delete the source files.

## Install Kodi on the TCL Google TV

1. Open the Play Store on the TV.
2. Search for and install **Kodi** from the Kodi Foundation.
3. Open Kodi once and grant requested network access.
4. If local USB files are also needed, open Google TV **Settings > Apps > Kodi
   > Permissions > Files and media** and allow file access.

## Add the desktop's SMB library to Kodi

Add movies and TV shows as separate sources:

1. From Kodi's home screen, open **Videos > Files > Add videos… > Browse**.
2. Select **Add network location…**.
3. Enter:

   | Field | Value |
   | --- | --- |
   | Protocol | Windows network (SMB) |
   | Server name | `10.1.10.188` |
   | Shared folder | `Videos` |
   | Username | `zac` |
   | Password | The password created with `smbpasswd` |

4. Save the network location and enter it.
5. Select the `Movies` directory and name the source **Movies**.
6. Set **This directory contains** to **Movies**. Enable **Movies are in
   separate folders that match the movie title** when using the recommended
   layout, then scan the source.
7. Repeat the process for `TV Shows`, setting its content type to **TV shows**.
8. Add `Home Videos` as a file source without assigning a scraper if those
   files should not be matched against online metadata.

Entering the numeric address avoids SMB name-discovery problems. Do not choose
SMB1 if Kodi offers protocol-version settings; the server deliberately accepts
only SMB2 and newer.

## Recommended Google TV playback settings

Set Kodi's settings level to **Standard** or **Advanced**, then review:

- **Settings > Player > Videos > Adjust display refresh rate:** start with
  **On start/stop** for smooth 24p movie playback. If the TCL blanks excessively
  or fails to switch modes, turn it off.
- **Settings > Player > Videos > Sync playback to display:** leave off when
  using audio passthrough, because this setting disables passthrough.
- **Settings > System > Audio > Number of channels:** choose the channels
  actually supported by the TV, soundbar, or receiver.
- **Allow passthrough:** leave off when using only the TV speakers. When using
  a soundbar or receiver, enable only formats that device explicitly supports.
- Enable the TV's normal movie/cinema picture mode rather than Game Mode unless
  low remote-control latency is more important than image processing.

## Day-to-day operation

1. Leave the desktop powered on. The SMB service does not require Hyprland or a
   logged-in graphical session.
2. Copy or move new media into the appropriate directory under `~/Videos`.
3. Open Kodi on the TV.
4. If new titles do not appear automatically, open the source's context menu
   and select **Scan for new content**, or choose **Update library**.
5. Play the title from Kodi's Movies or TV Shows library.

Unlike Sunshine, Kodi continues working when the desktop monitor is off or the
desktop is at the login screen. The computer itself and the `/data` filesystem
backing `~/Videos` must remain powered on and mounted.

## Kodi on the NixOS desktop or laptop

After rebuilding, launch **Kodi** from the application launcher or run:

```console
kodi
```

On the desktop, add `/home/zac/Videos/Movies` and
`/home/zac/Videos/TV Shows` as local sources.

On the laptop at home, add the same SMB network location used by the TV. When
away from home, first connect Tailscale and use the desktop's Tailscale
`100.x.y.z` address or MagicDNS hostname instead of `10.1.10.188`. The Samba
password and share name remain the same.

Remote Kodi playback consumes the desktop's internet upload bandwidth. Kodi
does not automatically lower quality like a transcoding media server, so the
connection must be fast enough for the original file's bitrate. Use
Sunshine/Moonlight or Jellyfin when the remote connection cannot carry the
original file reliably.

## Use the Jellyfin library inside Kodi

The direct SMB sources above are simple and remain available if Jellyfin is
stopped. For centralized watch state and remote-friendly access, install the
**JellyCon** add-on in Kodi. JellyCon coexists cleanly with existing SMB sources;
the more invasive **Jellyfin for Kodi** database-sync add-on can conflict with a
Kodi library that already contains local or SMB media.

On the TCL Google TV:

1. Open **Kodi Settings > File manager > Add source**.
2. Enter `https://kodi.jellyfin.org` and name it **Jellyfin Repo**.
3. Open **Settings > Add-ons > Install from zip file**. If prompted, enable
   unknown sources for this installation.
4. Select **Jellyfin Repo** and install `repository.jellyfin.kodi.zip`.
5. Open **Install from repository > Kodi Jellyfin Add-ons > Video add-ons** and
   install **JellyCon**.
6. Open JellyCon and connect to `http://10.1.10.188:8096` with the Jellyfin
   playback-user credentials.

When using Kodi on the laptop through Tailscale, give JellyCon
`http://100.x.y.z:8096`, replacing the address with the desktop's Tailscale IP.
JellyCon's add-on mode lets the server choose direct play, remuxing, or
transcoding for the client and connection.

## Kodi on the Retroid Pocket 3+

1. Install **Kodi** from the Play Store.
2. At home, add the SMB source using `10.1.10.188`, the `Videos` share, and the
   Samba credentials.
3. For remote access, install and connect Tailscale, then add a second SMB
   network location using the desktop's Tailscale address.

Direct Kodi playback is useful for video, but Moonlight remains the better
choice for PC games because Kodi does not forward the Retroid controls to Steam.

## Troubleshooting

### Kodi cannot connect to the share

On the desktop, check:

```console
systemctl status samba-smbd
smbclient -L //localhost -U zac
```

Then confirm:

- Kodi is using server `10.1.10.188`, share `Videos`, and username `zac`;
- the Samba password has been created with `sudo smbpasswd -a zac`;
- the TV is on the main home network rather than an isolated guest network;
- the desktop is connected through `enp6s0`; and
- SMB is set to version 2 or newer in Kodi.

Kodi may not browse the server automatically because legacy NetBIOS discovery
is intentionally disabled. Adding the numeric address manually is expected.

### Kodi connects but a directory is empty

- Confirm the files are actually below `/home/zac/Videos`.
- Check that `zac` can read the directory and files locally.
- On Android TV 11 or newer, grant Kodi file permissions for local USB media;
  this permission is not normally required for SMB sources.
- Restart Samba after storage or mount changes:

  ```console
  sudo systemctl restart samba-smbd
  ```

### Titles are missing or matched incorrectly

- Use `Movie Name (Year)` for movies.
- Use `Show Name S01E01` season/episode notation for television episodes.
- Keep movies and TV shows in separate Kodi sources.
- Open the source's context menu, select **Change content**, verify the scraper,
  and scan again.
- Check Kodi's event log for files the scraper could not match.

### Playback buffers or stutters

- Prefer Ethernet for the TV when possible, otherwise use strong 5 GHz Wi-Fi.
- Test a lower-bitrate file to distinguish network limits from codec support.
- For remote playback, compare the file bitrate with the home's upload speed.
- If the TV cannot decode a particular codec, use VLC through Sunshine or add a
  transcoding media server such as Jellyfin.

### Audio is missing

- Disable passthrough and test with stereo output first.
- Enable passthrough codecs only when the connected soundbar or receiver
  supports them.
- Leave **Sync playback to display** disabled when using passthrough.

## Security and maintenance

- The share requires a separate Samba password and permits no guest access.
- The media share is read-only.
- Port 445 is opened only on the home Ethernet and Tailscale interfaces.
- Do not forward SMB port 445 through the router or expose it publicly.
- Remove access for `zac` with `sudo smbpasswd -x zac` if Kodi access is no
  longer needed.

## References

- [Kodi Android installation](https://kodi.wiki/view/HOW-TO%3AInstall_Kodi_for_Android)
- [Kodi SMB setup](https://kodi.wiki/view/Linux_File_Sharing_%28using_samba%29)
- [Adding video sources](https://kodi.wiki/view/Adding_video_sources)
- [Kodi source-folder organization](https://kodi.wiki/view/Source_folder)
- [Movie naming](https://kodi.wiki/view/Naming_video_files/Movies)
- [Kodi video playback settings](https://kodi.wiki/view/Settings/Player/Videos)
- [Kodi audio settings](https://kodi.wiki/view/Settings/System/Audio)
- [Jellyfin Kodi and JellyCon add-ons](https://jellyfin.org/docs/general/clients/kodi/)
