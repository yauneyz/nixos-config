# Quest 3 VR on the desktop

Reviewed September 17, 2026 for the RTX 4090, NVIDIA 595.99.02,
Hyprland, native Steam, and ALVR. The PC is connected through `enp6s0`.

## What the configuration provides

- ALVR **20.14.1**, the current upstream stable release, including NVENC.
- Steam's environment includes the same ALVR package and `steamvr-alvr` launcher.
- ALVR TCP/UDP ports 9943–9944 are open on `enp6s0` only.
- SteamVR is the user's OpenXR runtime, through a symlink to its installed runtime.
- A first-run Quest 3 profile is copied to `~/.config/alvr/session.json` only
  when that file does not exist. Dashboard changes and trusted headsets survive rebuilds.
- The original profile remains available at `~/.config/alvr/quest3-baseline.json`.

The old local FFmpeg profile-name patch was removed: current nixpkgs packages
ALVR with its own patched FFmpeg 6.0. NVENC is enabled independently of the
global `cudaSupport = false` setting.

## Apply and connect

1. Apply the desktop configuration:

   ```sh
   sudo nixos-rebuild switch --flake /home/zac/nixos-config#desktop
   ```

   This also applies any other pending changes in the repo. If the rebuild
   changes the NVIDIA driver or kernel, reboot before testing VR.

2. Fully exit Steam and reopen it so it uses the new environment. In SteamVR
   **Properties → General → Launch Options**, enter:

   ```text
   steamvr-alvr %command%
   ```

   Keep SteamVR's forced compatibility-tool checkbox **unchecked**: SteamVR
   itself runs natively. Apply Proton to Windows games individually.

3. Keep SteamVR on the current stable branch and let Steam finish updates.
   Valve released SteamVR **2.17** stable on September 10; **2.17.10** on
   September 15 is a beta. The local installation has build **25216780**,
   updated September 11, with no pending download in its manifest at audit time.
   A headset launch is still needed to confirm the reported runtime version.
   Set SteamVR updates to high priority if desired.

4. Install the **matching ALVR 20.14.1 client** on the Quest 3 from the
   [official release](https://github.com/alvr-org/ALVR/releases/tag/v20.14.1).
   Use `alvr_dashboard` on the PC. Open ALVR on the headset and trust your
   headset in the dashboard. Start Steam first, then launch SteamVR from ALVR.
   The dashboard registers the driver; restart SteamVR if needed on first use.
   If it is blocked, enable ALVR in SteamVR's **Manage Add-ons** settings.

5. In SteamVR, set **Render Resolution → Custom → 100%**, including a 100%
   initial per-game multiplier. This avoids stacking automatic SteamVR
   supersampling on top of ALVR's resolution. Disable SteamVR Home to free
   resources. Start with Motion Smoothing off where the setting is exposed.
   Confirm the OpenXR runtime is SteamVR in SteamVR's OpenXR settings.

6. For Windows VR games, start with **Proton 11.0-2** (current Valve stable),
   and try **Proton Experimental** for games with newer fixes. **GE-Proton11-6**
   is also available from this flake as a per-game alternative. Use native
   Linux VR versions when they work well. Start VR from the normal Hyprland
   desktop; don't wrap SteamVR in Gamescope or launch it from the Gamescope session.

## Initial profile and tuning

These are starting settings, not a measured optimum for every game or router.
No router information or headset measurements were available during the audit.

| Setting | Initial value |
| --- | --- |
| Refresh rate | 90 Hz |
| Codec | AV1, 10-bit |
| Encode and reported render width | 2560 per eye; height follows headset aspect ratio |
| Bitrate | Constant 100 Mbps |
| Foveated encoding | Enabled, upstream default strength |
| Buffering | Upstream default of 2 frames |
| Linux asynchronous reprojection | Disabled for the NVIDIA path |

Use the ALVR statistics and SteamVR frame-timing graphs in an actual game:

- At 90 Hz, keep game frame time below **11.1 ms**, with headroom for demanding
  scenes. Try **2880 pixels per eye** for more clarity if frame times permit.
- For rhythm/action games, try **120 Hz** only while sustaining frame times
  below **8.3 ms**. For demanding simulations, 80/72 Hz may be smoother than
  intermittently missing 90 Hz.
- Raise AV1 bitrate in small steps toward **120–150 Mbps** if compression is
  visible and network/decode latency stays stable. Lower it if you see spikes,
  dropped frames, or corruption. Compare HEVC at the same bitrate if AV1 has
  problems. H.264 needs much more bandwidth for similar quality.
- Quest 3's lenses make peripheral blur visible. Reduce foveation strength
  or widen the center after the baseline is stable, watching encoder time.
- Leave buffering at its default initially. More buffering trades latency
  for smoother delivery; first resolve network spikes or excessive bitrate.
- Avoid concurrent GPU inference, video generation, or another streaming
  session while measuring VR performance.

Use a nearby 5 GHz or 6 GHz access point with wired backhaul to the PC. Keep the
headset off guest/client-isolated networks. Mesh wireless backhaul, repeaters,
and busy shared channels can dominate latency even with a 4090. The Quest and
PC must be able to reach each other on the LAN. If automatic discovery fails,
add the headset's IP manually in ALVR; retain the firewall.

For audio, select the intended game-output device in ALVR and test it in the
headset. Enable microphone streaming only if needed, then select the ALVR
microphone source in the game. PipeWire and its PulseAudio compatibility layer
are already enabled. Test playback and recording separately.

## Verification and remaining checks

The ALVR package and Steam environment were built successfully, and the full
desktop configuration evaluated successfully. ALVR's native settings parser
accepted every profile override and filled in the remaining defaults in an
isolated temporary session. ALVR's own FFmpeg completed a
90-frame AV1 NVENC encode using 10-bit `p010le` on the RTX 4090. This verifies
encoder availability, not full-resolution VR throughput or headset decoding.

The system changes still need activation. Headset pairing, controller bindings,
audio/microphone routing, game compatibility, and sustained wireless frame
timing require an actual connected Quest 3 test.

## Upstream references

- [ALVR Linux launch requirements](https://github.com/alvr-org/ALVR/wiki/Linux-troubleshooting)
- [ALVR settings and measurement guide](https://github.com/alvr-org/ALVR/wiki/Settings-tutorial)
- [SteamVR release announcements](https://store.steampowered.com/news/app/250820)
- [Valve Proton releases](https://github.com/ValveSoftware/Proton/releases)
- [Valve's Proton version guidance](https://github.com/ValveSoftware/Proton/wiki/Proton-Versions)
