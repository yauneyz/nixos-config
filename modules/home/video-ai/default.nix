{
  lib,
  pkgs,
  userPaths,
  ...
}:
let
  gamesRoot = "${userPaths.home}/Games";
  root = "${gamesRoot}/VideoAI";
  models = "${userPaths.models}/VideoAI";
  apps = "${root}/apps";
  envs = "${root}/envs";
  cache = "${root}/cache";
  state = "${root}/state";
  projects = "${root}/projects";
  work = "${root}/work";
  exports = "${root}/exports";
  tmp = "${root}/tmp";

  appsManifest = ./manifests/apps.json;
  modelsManifest = ./manifests/models.json;
  workflowsManifest = ./manifests/workflows.json;
  voiceScript = ./python/voice.py;

  runtimeLibraryPath =
    lib.makeLibraryPath [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.libGL
      pkgs.libglvnd
      pkgs.glib
      pkgs.libxcrypt-legacy
      pkgs.libx11
      pkgs.libxext
      pkgs.libxcb
    ]
    # CUDA wheels load the host driver dynamically. NixOS exposes the active
    # driver through this stable runtime symlink rather than a package-specific
    # store path, so keep it outside the immutable library list above.
    + ":/run/opengl-driver/lib";

  commonEnvironment = ''
    export VIDEO_AI_ROOT=${lib.escapeShellArg root}
    export VIDEO_AI_GAMES_ROOT=${lib.escapeShellArg gamesRoot}
    export VIDEO_AI_MODELS=${lib.escapeShellArg models}
    export VIDEO_AI_APPS=${lib.escapeShellArg apps}
    export VIDEO_AI_ENVS=${lib.escapeShellArg envs}
    export VIDEO_AI_CACHE=${lib.escapeShellArg cache}
    export VIDEO_AI_STATE=${lib.escapeShellArg state}
    export VIDEO_AI_PROJECTS=${lib.escapeShellArg projects}
    export VIDEO_AI_WORK=${lib.escapeShellArg work}
    export VIDEO_AI_EXPORTS=${lib.escapeShellArg exports}
    export VIDEO_AI_TMP=${lib.escapeShellArg tmp}
    export VIDEO_AI_PYTHON=${lib.escapeShellArg "${pkgs.python311}/bin/python3.11"}
    export LD_LIBRARY_PATH=${lib.escapeShellArg runtimeLibraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
  '';

  comfyModelPaths = pkgs.writeText "video-ai-comfy-extra-model-paths.yaml" ''
    video_ai:
      base_path: ${models}/comfy
      is_default: true
      checkpoints: checkpoints
      clip_vision: clip_vision
      controlnet: controlnet
      diffusion_models: diffusion_models
      loras: loras
      text_encoders: text_encoders
      upscale_models: upscale_models
      vae: vae
      custom_nodes: ${state}/comfyui/custom_nodes
  '';

  mkLauncher =
    {
      name,
      script,
      runtimeInputs ? [ ],
      extraEnvironment ? "",
    }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = runtimeInputs;
      text = ''
        ${commonEnvironment}
        ${extraEnvironment}
        ${builtins.readFile script}
      '';
    };

  videoAi = mkLauncher {
    name = "video-ai";
    script = ./scripts/video-ai.sh;
    runtimeInputs = with pkgs; [
      coreutils
      curl
      ffmpeg
      findutils
      gawk
      git
      gnused
      jq
      procps
      python311
      util-linux
      unzip
      uv
    ];
    extraEnvironment = ''
      export VIDEO_AI_APPS_MANIFEST=${lib.escapeShellArg appsManifest}
      export VIDEO_AI_MODELS_MANIFEST=${lib.escapeShellArg modelsManifest}
      export VIDEO_AI_WORKFLOWS_MANIFEST=${lib.escapeShellArg workflowsManifest}
    '';
  };

  comfyLauncher = mkLauncher {
    name = "video-ai-comfy";
    script = ./scripts/video-ai-comfy.sh;
    runtimeInputs = with pkgs; [
      coreutils
      ffmpeg
    ];
    extraEnvironment = ''
      export VIDEO_AI_COMFY_MODEL_PATHS=${lib.escapeShellArg comfyModelPaths}
    '';
  };

  wangpLauncher = mkLauncher {
    name = "video-ai-wangp";
    script = ./scripts/video-ai-wangp.sh;
    runtimeInputs = with pkgs; [
      coreutils
      ffmpeg
    ];
  };

  aceStepLauncher = mkLauncher {
    name = "video-ai-ace-step";
    script = ./scripts/video-ai-ace-step.sh;
    runtimeInputs = with pkgs; [
      coreutils
      ffmpeg
    ];
  };

  captionLauncher = mkLauncher {
    name = "video-ai-caption";
    script = ./scripts/video-ai-caption.sh;
    runtimeInputs = with pkgs; [
      coreutils
      ffmpeg
    ];
  };

  voiceLauncher = mkLauncher {
    name = "video-ai-voice";
    script = ./scripts/video-ai-voice.sh;
    runtimeInputs = with pkgs; [
      coreutils
      ffmpeg
    ];
    extraEnvironment = ''
      export VIDEO_AI_VOICE_SCRIPT=${lib.escapeShellArg voiceScript}
    '';
  };

  oviLauncher = mkLauncher {
    name = "video-ai-ovi";
    script = ./scripts/video-ai-ovi.sh;
    runtimeInputs = with pkgs; [
      coreutils
      ffmpeg
    ];
  };

  rifeLauncher = mkLauncher {
    name = "video-ai-rife";
    script = ./scripts/video-ai-rife.sh;
    runtimeInputs = with pkgs; [
      coreutils
      ffmpeg
    ];
  };

  serviceEnvironment = [
    "VIDEO_AI_ROOT=${root}"
    "VIDEO_AI_GAMES_ROOT=${gamesRoot}"
    "VIDEO_AI_MODELS=${models}"
    "VIDEO_AI_APPS=${apps}"
    "VIDEO_AI_ENVS=${envs}"
    "VIDEO_AI_CACHE=${cache}"
    "VIDEO_AI_STATE=${state}"
    "VIDEO_AI_PROJECTS=${projects}"
    "VIDEO_AI_WORK=${work}"
    "VIDEO_AI_EXPORTS=${exports}"
    "VIDEO_AI_TMP=${tmp}"
  ];

  mkGpuService =
    {
      description,
      execStart,
      conflicts,
    }:
    {
      Unit = {
        Description = description;
        ConditionPathIsMountPoint = gamesRoot;
        Conflicts = conflicts;
      };
      Service = {
        Type = "simple";
        ExecStart = execStart;
        Environment = serviceEnvironment;
        Restart = "on-failure";
        RestartSec = 5;
        UMask = "0077";
        Nice = 5;
      };
    };
in
{
  home.sessionVariables = {
    VIDEO_AI_ROOT = root;
    VIDEO_AI_GAMES_ROOT = gamesRoot;
    VIDEO_AI_MODELS = models;
    VIDEO_AI_APPS = apps;
    VIDEO_AI_ENVS = envs;
    VIDEO_AI_CACHE = cache;
    VIDEO_AI_STATE = state;
    VIDEO_AI_PROJECTS = projects;
    VIDEO_AI_WORK = work;
    VIDEO_AI_EXPORTS = exports;
    VIDEO_AI_TMP = tmp;
  };

  home.packages = [
    videoAi
    comfyLauncher
    wangpLauncher
    aceStepLauncher
    captionLauncher
    voiceLauncher
    oviLauncher
    rifeLauncher
    pkgs.davinci-resolve
    pkgs.mediainfo
    pkgs.realesrgan-ncnn-vulkan
    pkgs.vulkan-tools
  ];

  xdg.configFile."video-ai/comfy-extra-model-paths.yaml".source = comfyModelPaths;
  xdg.configFile."video-ai/apps.json".source = appsManifest;
  xdg.configFile."video-ai/models.json".source = modelsManifest;
  xdg.configFile."video-ai/workflows.json".source = workflowsManifest;

  home.activation.videoAiLayout = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mount_target="$(${pkgs.util-linux}/bin/findmnt -n -o TARGET -T ${lib.escapeShellArg gamesRoot})"
    if [ "$mount_target" != ${lib.escapeShellArg gamesRoot} ]; then
      echo "video-ai: refusing activation because ${gamesRoot} is not its own mount" >&2
      exit 1
    fi
    ${pkgs.coreutils}/bin/mkdir -p \
      ${lib.escapeShellArg root} \
      ${lib.escapeShellArg models} \
      ${lib.escapeShellArg state} \
      ${lib.escapeShellArg projects} \
      ${lib.escapeShellArg work} \
      ${lib.escapeShellArg exports} \
      ${lib.escapeShellArg tmp}
    ${pkgs.coreutils}/bin/chmod 700 ${lib.escapeShellArg state} ${lib.escapeShellArg projects}
  '';

  systemd.user.services = {
    comfyui = mkGpuService {
      description = "ComfyUI video generation workstation";
      execStart = "${comfyLauncher}/bin/video-ai-comfy";
      conflicts = [
        "wangp.service"
        "ace-step.service"
        "ovi.service"
      ];
    };
    wangp = mkGpuService {
      description = "WanGP model experimentation workstation";
      execStart = "${wangpLauncher}/bin/video-ai-wangp";
      conflicts = [
        "comfyui.service"
        "ace-step.service"
        "ovi.service"
      ];
    };
    ace-step = mkGpuService {
      description = "ACE-Step local music generation API";
      execStart = "${aceStepLauncher}/bin/video-ai-ace-step";
      conflicts = [
        "comfyui.service"
        "wangp.service"
        "ovi.service"
      ];
    };
    ovi = mkGpuService {
      description = "Ovi synchronized audio-video workstation";
      execStart = "${oviLauncher}/bin/video-ai-ovi";
      conflicts = [
        "comfyui.service"
        "wangp.service"
        "ace-step.service"
      ];
    };
  };
}
