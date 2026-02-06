{ host, ... }:
let
  rebuildAlias =
    if host == "desktop" then
      "cd ~/nixos-config && sudo nixos-rebuild switch --flake .#desktop"
    else
      "cd ~/nixos-config && sudo nixos-rebuild switch --flake .#laptop";
  llamaServeAlias = "llama-serve";
in
{
  programs.zsh = {
    shellAliases = {
      ############################
      # Directory shortcuts
      ############################

      nc    = "cd ~/nixos-config";
      mc  = "cd ~/nixos-config/modules/core";
      mh  = "cd ~/nixos-config/modules/home";
      hypr  = "cd ~/nixos-config/modules/home/hyprland";

      res   = "cd ~/development/research/";
      ai    = "cd ~/development/research/ai";
      koop  = "cd ~/development/research/ai/koopman";
      mem   = "cd ~/development/research/ai/memory";

      lando = "cd ~/development/Lando/lando-video";
      f2    = "cd ~/development/tools/focusd";

      gos   = "cd ~/development/go/gophercises";
      com   = "cd ~/development/go/compass";
      pylon = "cd ~/development/go/pylon";
      dex   = "cd ~/development/go/wikidex";

      focus = "cd ~/development/tools/focus";
      dev   = "cd ~/development";
      llm   = "cd ~/development/llm";
      #sd    = "cd ~/development/stable-diffusion";
      comfy = "cd ~/development/stable-diffusion/ComfyUI";

      home  = "cd ~";

      anki  = "cd ~/development/anki";
      org   = "cd ~/development/org";

      owl   = "cd ~/development/clojure/owl";
      ou    = "cd ~/development/clojure/owl/electron";
      ob    = "cd ~/development/clojure/owl/site";
      thc   = "cd ~/.config/Thinky";
      antei   = "cd ~/development/clojure/owl/antei";

      dot   = "cd ~/dotfiles";
      edot  = "cd ~/.emacs.d";


      ############################
      # Config / file editing shortcuts
      ############################

      # Edit zsh config in NixOS (updated from ~/.bashrc)
      vbrc  = "vim ~/nixos-config/modules/home/zsh/zsh.nix";
      valias  = "vim ~/nixos-config/modules/home/zsh/zsh_alias.nix";

      # Hyperland config (was i3: ii → now hh, opens Hyprland nix)
      hh   = "vim ~/nixos-config/modules/home/hyprland/hyprland.nix";

      # Waybar config (was polybar)
      wbar = "vim ~/nixos-config/modules/home/waybar/waybar.nix";

      # Neovim config via Nix (was ~/.config/nvim/init.vim)
      vv   = "vim ~/nixos-config/modules/home/nvim.nix";

      # Emacs init
      ee   = "vim ~/.emacs.d/init.el";

      # focusd config
      blocklist = "sudo vim /etc/blocklist.yml";
      focus-reload = "sudo systemctl restart focusd";


      ############################
      # General commands / tooling
      ############################
			cpy = "copy <";

      # Focus tool
      disable = "sudo focusd disable && focus-reload";
      enable  = "sudo focusd enable && focus-reload";

      # NixOS
      rebuild = rebuildAlias;

      # Thinky package management
      thinky-hash = "bash ~/nixos-config/pkgs/thinky/update-hash.sh";
      thinky-install = "bash ~/nixos-config/pkgs/thinky/update-hash.sh && ${rebuildAlias}";

      # LLM server
      llmserve = llamaServeAlias;

      # Motion helpers
      cd = "z";
      c  = "z";

      # Utils
      tt    = "gtrash put";
      cat   = "bat";
      nano  = "micro";
      "mod+g" = "micro";
      code  = "codium";
      diff  = "delta --diff-so-fancy --side-by-side";
      less  = "bat";
      copy  = "wl-copy";
      f     = "superfile";
      ipy   = "ipython";
      icat  = "kitten icat";
      dsize = "du -hs";
      pdf   = "tdf";
      open  = "xdg-open";
      space = "ncdu";
      man   = "batman";

      # Listing
      l    = "eza --icons -a --group-directories-first -1 --no-user --long"; # EZA_ICON_SPACING=2
      tree = "eza --icons --tree --group-directories-first";

      # Nix / nh / nom
      #ns  = "nom-shell --run zsh";
      #nd  = "nom develop --command zsh";
      #nb  = "nom build";
      #nc  = "nh-notify nh clean all --keep 5";
      #nft = "nh-notify nh os test";
      #nfs = "nh-notify nh os switch";
      #nfu = "nh-notify nh os switch --update";
      # nix-search = "nh search";

      # Python env helpers
      piv = "python -m venv .venv";
      psv = "source .venv/bin/activate";

			cl = "claude";
			clr = "claude --resume";


      ############################
      # Safety
      ############################

      rm = "rm -i";
      mv = "mv -i";
      cp = "cp -i";
      # alias rm="gio trash"


      ############################
      # Listing / directories / motion
      ############################

      ls      = "ls --color";
      ll      = "ls -alrtF --color";
      la      = "ls -A";
      lal     = "ls -al";
      dir     = "ls --color=auto --format=vertical";
      vdir    = "ls --color=auto --format=long";
      m       = "less";
      ".."    = "cd ..";
      "..."   = "cd ..; cd ..";
      md      = "mkdir";
      du      = "du -ch --max-depth=1";
      treeacl = "tree -A -C -L 2";

      grep = "grep -n --color=auto";
      gg   = "grep -rn --color=auto";


      ############################
      # Standard dirs / language helpers
      ############################

      # Standard Directories
      # (home already defined above in directory section)

      # Python
      p       = "python";
      pip     = "pip3";
      freeze  = "pip freeze";
      freezer = "pip freeze >| requirements.txt";

      # Heroku Git
      ph = "git push heroku master";
      po = "git push origin master";

      # Virtual env
      va = "source .venv/bin/activate";
      da = "deactivate";

      # Editors
      vim = "nvim";
      v   = "vim";


      ############################
      # Node shortcuts
      ############################

      # Keep nom/nh meanings for ns/nd/nb/nc; use separate names for Node
      ns   = "npm run start";
      nd = "npm run develop";
      na = "shadow-cljs watch antei-lib";
			test = "npx shadow-cljs compile test";
			tw = "npx shadow-cljs watch test";
      ac = "npm run antei:compile";
      at = "npm run antei";


      ############################
      # Misc config / apps
      ############################

      # Hyperland display sleep toggle (same key combo wakes it)
      slp = "sleep 3; hyprctl dispatch dpms toggle";

      # Apps / shortcuts
      rg = "ranger";
      ex = "exit";

      ############################
      # Heroku
      ############################

      ho = "heroku open";
      hl = "heroku local";


      ############################
      # Projects / scripts
      ############################

      # Screenplay
      mkft = "screenplain ~/development/screenplay/markov/markov.fountain ~/development/screenplay/markov/markov.pdf";

      # Jekyll
      js = "bundle exec jekyll serve";


      ############################
      # System / misc tools
      ############################

      smi        = "nvidia-smi";
      audio      = "wpctl status";
      unmount    = "sudo umount -l /media/usb";
      "mount-key" = "sudo mount /dev/sdc2 /media/usb";


      ############################
      # Clojure
      ############################

      cljs    = "shadow-cljs";
      default = "cp -f electron/resources/default-state.edn electron/resources/storage/app-state.edn";
      ld      = "set -a; source .env; set +a; lein ring server-headless 3000";
    };
  };
}
