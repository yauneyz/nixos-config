# Unity PC VR development

The desktop Home Manager profile imports `modules/home/unity.nix`. It installs
Unity Hub and two commands, and exports `UNITY_EDITOR` for project scripts.
The existing NVIDIA, SteamVR and ALVR configuration stays in charge of VR.

## First installation

After rebuilding the desktop configuration, open a new terminal:

```bash
unity-install-editor
unityhub
```

The installer requests Unity **6000.0.66f2**, changeset **b20bc5da3050**, through
the packaged Hub's headless CLI. Editor files live at
`/data/zac/zac/Unity/Hub/Editor/6000.0.66f2/` on desktop. The Linux editor includes
the native Linux Mono player support needed by the demo; Android tools are not
needed for PC VR through ALVR. The installer does not download on every rebuild.

In Hub, sign in with your Unity account and activate the appropriate license
(Unity Personal for eligible users). Add the existing project at
`~/development/xr/demo`; do not create a new project over it. If the installed
Hub no longer supports its legacy headless CLI, install that exact editor from
the release page below using Hub, with the editor location set to
`/data/zac/zac/Unity/Hub/Editor` in Hub preferences.

## Open, test, build, play

```bash
cd ~/development/xr/demo
bash tools/unity.sh editor
# Close the editor before running these batch commands:
bash tools/unity.sh test
bash tools/unity.sh build-linux
# Connect Quest 3 through ALVR and SteamVR before playing:
bash tools/play.sh
```

`unity-editor` launches the pinned editor in Nixpkgs' Unity Hub FHS environment
with Vulkan. This is the same native-library environment Hub uses for its editor
children. The wrapper checks both the data-partition install and Hub's usual
`~/Unity/Hub/Editor` location. A custom location can be selected with
`UNITY_EDITOR_BINARY=/absolute/path/to/Editor/Unity`.

The demo supports fast testing with the editor Play button. Its initial scene
is empty because the room and gameplay objects are generated when Play starts.
Standalone output is `Builds/Linux/`; keep its executable, data and plugins
together. Logs are under `demo/Logs/`, and test results are
`demo/Builds/test-results.xml`.

Unity account sign-in/license activation and headset tests are separate from
installing the Nix packages. Neither is completed by rebuilding NixOS.

References:

- [Pinned editor release and downloads](https://unity.com/releases/editor/whats-new/6000.0.66f2)
- [Hub CLI reference](https://docs.unity.com/en-us/hub/hub-cli-reference)
- [ALVR setup](vr-setup.md)
