{ lib, pkgs, ... }:
let

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
    "browser.toolbars.bookmarks.visibility" = "always";
    "browser.shell.checkDefaultBrowser" = false;
    "general.autoScroll" = true;
    "devtools.chrome.enabled" = true;
    "svg.context-properties.content.enabled" = true;
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
  };

  mkProfile =
    {
      name,
      id,
      homepage ? "about:home",
      extensionPackages ? [ ],
      extraSettings ? { }
    }:
    {
      inherit id;
      isDefault = name == "default";
      search = searchConfig;
      settings =
        privacySettings
        // performanceSettings
        // chromeSettings
        // {
          "browser.startup.page" = 1;
          "browser.startup.homepage" = homepage;
          "browser.newtabpage.enable-state-for-interactions" = false;
          "browser.download.useDownloadDir" = false;
        }
        // extraSettings;
      extensions.packages = extensionPackages;
    };

  firefoxDesktopFile = "firefox.desktop";
  firefoxProfiles = [
    "default"
    "keep-profile"
    "music-youtube"
  ];

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

    profiles = {
      default = mkProfile {
        name = "default";
        id = 0;
      };

      "keep-profile" = mkProfile {
        name = "keep-profile";
        id = 1;
        extraSettings = {
          "browser.tabs.warnOnClose" = false;
          "ui.systemUsesDarkTheme" = 1;
        };
      };

      "music-youtube" = mkProfile {
        name = "music-youtube";
        id = 2;
        homepage = "https://music.youtube.com/";
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

  home.file =
    lib.mkMerge (
      map
        (profile:
          {
            ".mozilla/firefox/${profile}/search.json.mozlz4" = {
              force = lib.mkForce true;
            };
          }
        )
        firefoxProfiles
    );

  stylix.targets.firefox.enable = false;
}
