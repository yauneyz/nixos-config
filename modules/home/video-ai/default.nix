{
  config,
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
  # LTX Desktop keeps its Python env (~10 GB) and model weights under
  # $XDG_DATA_HOME/LTXDesktop; the root partition is too small for that.
  ltxDesktopData = "${root}/ltx-desktop";

  appsManifest = ./manifests/apps.json;
  modelsManifest = ./manifests/models.json;
  workflowsManifest = ./manifests/workflows.json;
  voiceScript = ./python/voice.py;
  transcriptScript = ./python/transcript.py;
  pipelineScript = ./python/pipeline.py;
  projectTemplates = ./templates;
  guideDoc = ./TOOLS.md;
  workflowGuideDoc = ./WORKFLOW.md;

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
    # Numba cannot derive a writable cache location for Python modules reached
    # through immutable Nix/store-backed environments. Give every launcher one
    # explicit cache so audio imports and diagnostics behave identically.
    export NUMBA_CACHE_DIR=${lib.escapeShellArg "${cache}/numba"}
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
      latent_upscale_models: latent_upscale_models
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
      inherit runtimeInputs;
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
      sox
      util-linux
      unzip
      uv
      yt-dlp-light
    ];
    extraEnvironment = ''
      export VIDEO_AI_APPS_MANIFEST=${lib.escapeShellArg appsManifest}
      export VIDEO_AI_MODELS_MANIFEST=${lib.escapeShellArg modelsManifest}
      export VIDEO_AI_WORKFLOWS_MANIFEST=${lib.escapeShellArg workflowsManifest}
      export VIDEO_AI_TRANSCRIPT_SCRIPT=${lib.escapeShellArg transcriptScript}
      export VIDEO_AI_PIPELINE_SCRIPT=${lib.escapeShellArg pipelineScript}
      export VIDEO_AI_TEMPLATES=${lib.escapeShellArg projectTemplates}
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

  qwenTtsLauncher = mkLauncher {
    name = "video-ai-qwen-tts";
    script = ./scripts/video-ai-qwen-tts.sh;
    runtimeInputs = with pkgs; [
      coreutils
      ffmpeg
      sox
    ];
  };

  oviLauncher = mkLauncher {
    name = "video-ai-ovi";
    script = ./scripts/video-ai-ovi.sh;
    runtimeInputs = with pkgs; [
      coreutils
      ffmpeg
    ];
  };

  videoGuide = pkgs.writeShellApplication {
    name = "video-guide";
    runtimeInputs = [ pkgs.glow ];
    text = ''
      exec glow --pager ${lib.escapeShellArg guideDoc} "$@"
    '';
  };

  workflowGuide = pkgs.writeShellApplication {
    name = "workflow-guide";
    runtimeInputs = [ pkgs.glow ];
    text = ''
      exec glow --pager ${lib.escapeShellArg workflowGuideDoc} "$@"
    '';
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

  gpuServiceNames = [
    "comfyui"
    "wangp"
    "ace-step"
    "ovi"
    "qwen-tts"
  ];

  mkGpuService =
    name:
    { description, execStart }:
    {
      Unit = {
        Description = description;
        ConditionPathIsMountPoint = gamesRoot;
        # Only one large GPU service at a time: 24 GB is not shared well.
        Conflicts = map (other: "${other}.service") (lib.remove name gpuServiceNames);
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
  home = {
    sessionVariables = {
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

    packages = [
      videoAi
      videoGuide
      workflowGuide
      comfyLauncher
      wangpLauncher
      aceStepLauncher
      captionLauncher
      voiceLauncher
      qwenTtsLauncher
      oviLauncher
      rifeLauncher
      pkgs.ltx-desktop
      pkgs.davinci-resolve
      pkgs.mediainfo
      pkgs.realesrgan-ncnn-vulkan
      pkgs.vulkan-tools
    ];

    activation.videoAiLayout = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
        ${lib.escapeShellArg tmp} \
        ${lib.escapeShellArg ltxDesktopData}
      ${pkgs.coreutils}/bin/chmod 700 ${lib.escapeShellArg state} ${lib.escapeShellArg projects}
    '';
  };

  xdg = {
    dataFile."LTXDesktop".source = config.lib.file.mkOutOfStoreSymlink ltxDesktopData;
    configFile = {
      "video-ai/comfy-extra-model-paths.yaml".source = comfyModelPaths;
      "video-ai/apps.json".source = appsManifest;
      "video-ai/models.json".source = modelsManifest;
      "video-ai/workflows.json".source = workflowsManifest;
    };
  };

  systemd.user.services = lib.mapAttrs mkGpuService {
    comfyui = {
      description = "ComfyUI video generation workstation";
      execStart = "${comfyLauncher}/bin/video-ai-comfy";
    };
    wangp = {
      description = "WanGP model experimentation workstation";
      execStart = "${wangpLauncher}/bin/video-ai-wangp";
    };
    ace-step = {
      description = "ACE-Step local music generation API";
      execStart = "${aceStepLauncher}/bin/video-ai-ace-step";
    };
    ovi = {
      description = "Ovi synchronized audio-video workstation";
      execStart = "${oviLauncher}/bin/video-ai-ovi";
    };
    qwen-tts = {
      description = "Qwen3-TTS voice design and cloning web UI";
      execStart = "${qwenTtsLauncher}/bin/video-ai-qwen-tts";
    };
  };
}
