{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  directx-shader-compiler,
  openxr-loader,
  glm,
  vulkan-headers,
  vulkan-loader,
  imgui,
  implot,
  xorg,
  cemu,
  python3,
  writeShellApplication,
  coreutils,
  procps,
  binutils,
  libglvnd,
  util-linux,
  steam,
  # Per-eye resolution SteamVR reports for the headset. ALVR's Quest 3 profile
  # emulates 2560 px wide eyes; the height follows the Quest 3's 2064x2208
  # per-eye aspect ratio. The VR Resolution Multiplier presets scale this.
  eyeWidth ? 2560,
  eyeHeight ? 2739,
}:
let
  version = "0.9.16-linux-unstable-2026-05-28";

  # Native Vulkan/OpenXR Linux port of Crementif's BetterVR. Upstream is
  # Windows-only (D3D12 interop); this fork was play-tested on NVIDIA +
  # SteamVR. See https://github.com/Crementif/BotW-BetterVR/issues/18.
  src = fetchFromGitHub {
    owner = "asingleoat";
    repo = "BotW-BetterVR-Linux";
    rev = "c41291ea1e492fe07c37ad86232f0723d7f2f6ce";
    hash = "sha256-LCIHJGDzrE0Ai2Ymmrq7T5Rs1O8JMO8eSgOVf6w0Sn4=";
  };

  # BetterVR's layer dlsym()s these Cemu HLE entry points. Stock Linux Cemu
  # defines DLLEXPORT as empty, so they never reach .dynsym.
  cemu-bettervr = cemu.overrideAttrs (old: {
    pname = "cemu-bettervr";
    postPatch = (old.postPatch or "") + ''
      sed -i 's/^\([[:space:]]*\)#define DLLEXPORT$/\1#define DLLEXPORT __attribute__((visibility("default")))/' \
        src/Common/precompiled.h
      grep -q 'define DLLEXPORT __attribute__((visibility("default")))' src/Common/precompiled.h
    '';
    cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DCMAKE_EXE_LINKER_FLAGS=-Wl,--export-dynamic" ];
  });

  layer = stdenv.mkDerivation {
    pname = "bettervr-layer";
    inherit version src;

    nativeBuildInputs = [
      cmake
      ninja
      pkg-config
      directx-shader-compiler
      python3
    ];

    buildInputs = [
      openxr-loader
      glm
      vulkan-headers
      vulkan-loader
      imgui
      implot
      xorg.libX11
    ];

    cmakeFlags = [ "-DCMAKE_BUILD_TYPE=Release" ];

    # The Windows launcher fills these placeholders from the headset's
    # OpenXR-recommended resolution at launch; resolve them for ALVR here.
    postPatch = ''
      python3 ${./resolve-resolutions.py} ${toString eyeWidth} ${toString eyeHeight} \
        resources/BreathOfTheWild_Graphics/rules.txt
    '';

    installPhase = ''
      runHook preInstall

      install -Dm755 lib/libBetterVR_Layer.so $out/lib/libBetterVR_Layer.so
      mkdir -p $out/share/vulkan/explicit_layer.d
      sed "s|\"library_path\": \".*\"|\"library_path\": \"$out/lib/libBetterVR_Layer.so\"|" \
        lib/BetterVR_Layer_linux.json > $out/share/vulkan/explicit_layer.d/BetterVR_Layer.json

      mkdir -p $out/share/bettervr/graphicPacks
      cp -r ../resources/BreathOfTheWild_BetterVR $out/share/bettervr/graphicPacks/
      cp -r ../resources/BreathOfTheWild_Graphics $out/share/bettervr/graphicPacks/BreathOfTheWild_BetterVR_Graphics
      install -Dm644 ../resources/controller_help.png $out/share/bettervr/controller_help.png

      runHook postInstall
    '';

    meta = {
      description = "Native Linux port of BetterVR, a 6DoF VR mod for Breath of the Wild in Cemu";
      homepage = "https://github.com/asingleoat/BotW-BetterVR-Linux";
      license = lib.licenses.mit;
      platforms = [ "x86_64-linux" ];
    };
  };

  # SteamVR's OpenXR runtime (vrclient.so) is loaded into Cemu's process and
  # expects these FHS libraries.
  vrclientLibs = lib.makeLibraryPath [
    libglvnd
    util-linux.lib
  ];
in
writeShellApplication {
  name = "botw-vr";
  runtimeInputs = [
    coreutils
    procps
    binutils
    python3
    steam
  ];
  text = ''
    export BETTERVR_LAYER=${layer}
    export BETTERVR_CEMU=${cemu-bettervr}/bin/Cemu
    export BETTERVR_VRCLIENT_LIBS=${vrclientLibs}
    export BETTERVR_PROFILE_TOOL=${./cemu-profile.py}
  ''
  + builtins.readFile ./botw-vr.sh;
  passthru = {
    inherit layer cemu-bettervr;
  };
  meta.mainProgram = "botw-vr";
}
