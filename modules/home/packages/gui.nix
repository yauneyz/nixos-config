{ pkgs, lib, ... }:
let
  hasThinky = pkgs.thinky.appimageAvailable or false;
  hasTalysman = pkgs.talysman.appimageAvailable or false;
  hasDreamrunner = pkgs.dreamrunner.releaseAvailable or false;
  metabasePort = "3010";
  metabaseWrapped = pkgs.symlinkJoin {
    name = "metabase-wrapped";
    paths = [ pkgs.metabase ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/metabase \
        --set-default MB_JETTY_PORT ${metabasePort}
    '';
  };
in
{
  warnings =
    lib.optional (!hasThinky) ''
      Skipping Thinky package: AppImage source is unavailable.
      Rebuild it from the electron repo with `npm run release:local`
      (writes and stages pkgs/thinky/releases/<host>.nix), then rebuild NixOS.
    ''
    ++ lib.optional (!hasTalysman) ''
      Skipping Talysman package: AppImage source is unavailable.
      Build it from the Talysman source repo with `talysman-dist` (pnpm run release:local)
      (writes and stages pkgs/snorlax/releases/<host>.nix), then rebuild NixOS.
    ''
    ++ lib.optional (!hasDreamrunner) ''
      Skipping Dreamrunner package: local release is unavailable.
      Run `dreamrunner-update` from the Dreamrunner checkout setup to stage the
      Rust binary and rebuild NixOS.
    '';

  home.packages =
    with pkgs;
    [
      ## Browser
      google-chrome

      ## VPN
      proton-vpn

      ## Multimedia
      audacity
      easyeffects
      gimp
      gpu-screen-recorder
      gpu-screen-recorder-gtk
      jellyfin-desktop
      kodi-wayland
      loupe
      media-downloader
      moonlight-qt
      obs-studio
      pavucontrol
      shotcut
      wf-recorder # Wayland screen recorder
      spotify
      soundwireserver
      video-trimmer

      ## Office
      (lib.getAttr "anki-bin" pkgs)
      chatgpt-linux
      claude-desktop
      libreoffice
      gnome-calculator
      readfence
      typora

      ## PDF / ebook readers
      sioyek # PDF, built for papers: smart jump to refs/figures, portals
      kdePackages.okular # PDF/EPUB/DjVu, best annotation + form support
      readest # EPUB/PDF reader with cross-device sync
      # simple GTK ebook library/reader. Its WebKitGTK page view crashes on
      # NVIDIA + Wayland (Gdk "Error 71 (Protocol error)") via WebKit's dmabuf
      # renderer; disabling just that renderer keeps it native Wayland.
      (symlinkJoin {
        name = "bookworm-wrapped";
        paths = [
          # Upstream bug: reading the scroll position runs JS and then reads the
          # page title; when the title is null it calls int.parse(null) and
          # segfaults (on Return to Library / Info / close). Treat null as "".
          (bookworm.overrideAttrs (old: {
            postPatch = (old.postPatch or "") + ''
              substituteInPlace src/utils.vala \
                --replace-fail \
                  'selectedText = BookwormApp.AppWindow.aWebView.get_title ();' \
                  'selectedText = BookwormApp.AppWindow.aWebView.get_title () ?? "";'
            '';
          }))
        ];
        nativeBuildInputs = [ makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/com.github.babluboy.bookworm \
            --set WEBKIT_DISABLE_DMABUF_RENDERER 1
        '';
      })

      ## PDF tools
      ocrmypdf # add a searchable text layer to scanned PDFs
      pdfarranger # merge / split / reorder / rotate pages
      briss # crop PDF margins (great before sending to the Kindle)
      recoll # full-text desktop search across PDFs/EPUBs/docs
      # Zotero bundles Firefox libs (e.g. libfreeblpriv3.so) that collide with nss.
      (lib.lowPrio zotero)
    ]
    ++ lib.optional hasThinky thinky
    ++ lib.optional hasTalysman talysman
    ++ lib.optional hasDreamrunner dreamrunner
    ++ [
      ## Utility
      dconf-editor
      dbeaver-bin
      gnome-disk-utility
      metabaseWrapped
      qdirstat
      mission-center # GUI resources monitor
      overskride # Modern Bluetooth manager
      sillytavern
      zenity
      zoom-us

      ## Level editor
      ldtk
      tiled
    ];

  home.file.".local/share/applications/metabase.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Metabase
    Comment=Metabase on port ${metabasePort}
    Exec=metabase
    Terminal=true
    Categories=Office;Database;
    StartupNotify=true
  '';
}
