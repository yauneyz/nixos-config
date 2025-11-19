{ config, pkgs, ... }:
let
  colors = config.lib.stylix.colors;
  hexColors = colors.withHashtag;
  fonts = config.stylix.fonts;
  sansFont = fonts.sansSerif.name;
  monoFont = fonts.monospace.name;
  normalizeSize =
    size:
    if builtins.isFloat size then builtins.floor (size + 0.5) else size;
  fontSize = "${toString (normalizeSize fonts.sizes.applications)}px";
  firefoxAddons = pkgs.nur.repos.rycee.firefox-addons;

  userChromeBase = ''
    :root {
      color-scheme: dark;
      --fp-bg: ${hexColors.base00};
      --fp-surface: ${hexColors.base01};
      --fp-surface-alt: ${hexColors.base02};
      --fp-border: ${hexColors.base03};
      --fp-muted: ${hexColors.base04};
      --fp-fg: ${hexColors.base05};
      --fp-accent: ${hexColors.base0D};
      --fp-accent-soft: ${hexColors.base0C};
      --fp-danger: ${hexColors.base08};
    }

    #nav-bar,
    #TabsToolbar,
    #navigator-toolbox,
    #titlebar {
      background-color: var(--fp-surface) !important;
      color: var(--fp-fg) !important;
      font-family: "${sansFont}", sans-serif !important;
      font-size: ${fontSize} !important;
      border: none !important;
      box-shadow: none !important;
    }

    #nav-bar {
      border-block-end: 1px solid var(--fp-border) !important;
    }

    toolbarbutton,
    .toolbarbutton-text,
    .toolbarbutton-icon {
      color: var(--fp-fg) !important;
      fill: var(--fp-fg) !important;
    }

    .toolbarbutton-icon,
    .toolbarbutton-1 {
      border-radius: 6px !important;
    }

    #urlbar-background,
    #searchbar {
      background-color: var(--fp-bg) !important;
      color: var(--fp-fg) !important;
      border: 1px solid var(--fp-border) !important;
      border-radius: 8px !important;
      box-shadow: none !important;
    }

    #urlbar-input,
    #searchbar {
      font-family: "${sansFont}", sans-serif !important;
    }

    #PopupAutoCompleteRichResult,
    #urlbar-results {
      background-color: var(--fp-bg) !important;
      color: var(--fp-fg) !important;
      border: 1px solid var(--fp-border) !important;
    }

    .urlbarView-row[selected],
    .autocomplete-richlistitem[selected] {
      background-color: color-mix(in srgb, var(--fp-accent) 25%, transparent) !important;
    }

    .tabbrowser-tab {
      font-family: "${sansFont}", sans-serif !important;
    }

    .tabbrowser-tab .tab-background {
      border-radius: 8px 8px 0 0 !important;
      margin-block-end: 0 !important;
    }

    .tabbrowser-tab[selected] .tab-background {
      background: var(--fp-accent) !important;
      color: var(--fp-bg) !important;
    }

    .tabbrowser-tab[selected] .tab-label {
      color: var(--fp-bg) !important;
      font-variation-settings: "wght" 550;
    }

    .tabbrowser-tab:not([selected]) .tab-label {
      color: var(--fp-muted) !important;
    }

    .tab-close-button:hover {
      background-color: color-mix(in srgb, var(--fp-danger) 30%, transparent) !important;
    }

    menupopup,
    panel,
    panelview {
      background-color: var(--fp-bg) !important;
      color: var(--fp-fg) !important;
      font-family: "${sansFont}", sans-serif !important;
      font-size: ${fontSize} !important;
      border: 1px solid var(--fp-border) !important;
    }

    toolbarseparator,
    menuseparator {
      border-color: var(--fp-border) !important;
    }

    :root {
      scrollbar-width: thin !important;
      scrollbar-color: ${hexColors.base05} ${hexColors.base01} !important;
    }
  '';

  userContentBase = ''
    :root {
      color-scheme: dark !important;
    }

    html,
    body {
      background-color: ${hexColors.base00} !important;
      color: ${hexColors.base05} !important;
      font-family: "${sansFont}", sans-serif !important;
      font-size: ${fontSize} !important;
    }

    code,
    pre,
    kbd {
      font-family: "${monoFont}", monospace !important;
    }

    @-moz-document url("about:blank"),
    url-prefix("about:home"),
    url-prefix("about:newtab"),
    url-prefix("about:privatebrowsing") {
      body {
        background-color: ${hexColors.base00} !important;
        color: ${hexColors.base05} !important;
        font-family: "${sansFont}", sans-serif !important;
      }
    }
  '';

  searchConfig = {
    default = "google";
    privateDefault = "bing";
    order = [
      "google"
      "bing"
      "nix-packages"
      "nixos-options"
      "wikipedia"
      "youtube"
      "ddg"
    ];
    engines = {
      "nix-packages" = {
        urls = [{
          template = "https://search.nixos.org/packages";
          params = [
            {
              name = "type";
              value = "packages";
            }
            {
              name = "query";
              value = "{searchTerms}";
            }
          ];
        }];
        icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        definedAliases = [ "@np" ];
      };
      "nixos-options" = {
        urls = [{
          template = "https://search.nixos.org/options";
          params = [
            {
              name = "type";
              value = "options";
            }
            {
              name = "query";
              value = "{searchTerms}";
            }
          ];
        }];
        icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        definedAliases = [ "@no" ];
      };
      "youtube" = {
        urls = [{
          template = "https://www.youtube.com/results";
          params = [{
            name = "search_query";
            value = "{searchTerms}";
          }];
        }];
        definedAliases = [ "@yt" ];
      };
    };
  };

  stylixAwareSettings = {
    "browser.display.background_color" = hexColors.base00;
    "browser.display.foreground_color" = hexColors.base05;
    "layout.css.prefers-color-scheme.content-override" = 0;
  };

  privacySettings = {
    "privacy.donottrackheader.enabled" = true;
    "privacy.query_stripping.enabled" = true;
    "privacy.resistFingerprinting" = false;
    "dom.security.https_only_mode" = true;
    "network.trr.mode" = 2;
  };

  performanceSettings = {
    "gfx.webrender.all" = true;
    "media.ffmpeg.vaapi.enabled" = true;
    "media.hardwaremediakeys.enabled" = true;
    "media.videocontrols.picture-in-picture.media-control.enabled" = true;
    "widget.use-xdg-desktop-portal.file-picker" = true;
  };

  chromeSettings = {
    "browser.compactmode.show" = true;
    "browser.uidensity" = 1;
    "browser.tabs.unloadOnLowMemory" = true;
    "browser.tabs.loadInBackground" = true;
    "browser.tabs.firefox-view" = false;
    "browser.urlbar.quicksuggest.enabled" = false;
    "browser.urlbar.showSearchSuggestionsFirst" = false;
    "browser.toolbars.bookmarks.visibility" = "never";
    "browser.shell.checkDefaultBrowser" = false;
    "general.autoScroll" = true;
    "signon.rememberSignons" = false;
    "devtools.chrome.enabled" = true;
    "svg.context-properties.content.enabled" = true;
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
  };

  baseSettings =
    stylixAwareSettings
    // privacySettings
    // performanceSettings
    // chromeSettings;

  mkProfile =
    {
      name,
      id,
      homepage,
      extensionPackages ? [ ],
      extraSettings ? { },
      extraChrome ? "",
      extraContent ? ""
    }:
    {
      inherit id;
      isDefault = name == "default";
      search = searchConfig;
      settings = baseSettings // {
        "browser.startup.page" = 1;
        "browser.startup.homepage" = homepage;
        "browser.newtabpage.enable-state-for-interactions" = false;
      } // extraSettings;
      userChrome = userChromeBase + extraChrome;
      userContent = userContentBase + extraContent;
      extensions.packages = extensionPackages;
    };

  defaultExtensions = with firefoxAddons; [
    ublock-origin
    bitwarden
    darkreader
    multi-account-containers
    sponsorblock
    enhancer-for-youtube
  ];

  keepExtensions = with firefoxAddons; [
    ublock-origin
  ];

  musicExtensions = with firefoxAddons; [
    ublock-origin
    enhancer-for-youtube
    sponsorblock
    return-youtube-dislikes
  ];

  firefoxDesktopFile = "firefox.desktop";

  browserMimeTypes = [
    "application/x-extension-shtml"
    "application/x-extension-xhtml"
    "application/x-extension-html"
    "application/x-extension-xht"
    "application/x-extension-htm"
    "x-scheme-handler/unknown"
    "x-scheme-handler/mailto"
    "x-scheme-handler/chrome"
    "x-scheme-handler/about"
    "x-scheme-handler/https"
    "x-scheme-handler/http"
    "application/xhtml+xml"
    "application/json"
    "text/html"
  ];

  firefoxAssociations = builtins.listToAttrs (map (name: { inherit name; value = firefoxDesktopFile; }) browserMimeTypes);
in
{
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;

    policies = {
      DisableAppUpdate = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePasswordReveal = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      OfferToSaveLogins = false;
      PasswordManagerEnabled = false;
      PromptForDownloadLocation = true;
      SearchSuggestEnabled = false;
      ExtensionSettings = {
        "*" = {
          installation_mode = "allowed";
        };
      };
      Preferences = {
        "browser.download.dir" = "${config.home.homeDirectory}/Downloads";
        "browser.download.alwaysOpenPanel" = false;
      };
    };

    profiles = {
      default = mkProfile {
        name = "default";
        id = 0;
        homepage = "https://start.duckduckgo.com/";
        extensionPackages = defaultExtensions;
      };

      "keep-profile" = mkProfile {
        name = "keep-profile";
        id = 1;
        homepage = "https://keep.google.com/u/0/";
        extensionPackages = keepExtensions;
        extraSettings = {
          "browser.tabs.warnOnClose" = false;
          "ui.systemUsesDarkTheme" = 1;
        };
      };

      "music-youtube" = mkProfile {
        name = "music-youtube";
        id = 2;
        homepage = "https://music.youtube.com/";
        extensionPackages = musicExtensions;
        extraSettings = {
          "media.block-autoplay-until-in-foreground" = false;
          "media.autoplay.default" = 0;
        };
      };
    };
  };

  xdg.mimeApps = {
    enable = true;
    associations.added = firefoxAssociations;
    defaultApplications = firefoxAssociations;
  };

  stylix.targets.firefox.profileNames = [
    "default"
    "keep-profile"
    "music-youtube"
  ];
}
