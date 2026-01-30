{ pkgs, ... }:
{
  home.packages = with pkgs; [ nautilus ];

  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      always-use-location-entry = true;
      default-folder-viewer = "list-view";
      default-sort-in-reverse-order = false;
      default-sort-order = "name";
      default-zoom-level = "small";
      enable-delete = false;
      search-filter-time-type = "last-modified";
      show-hidden-files = true;
      thumbnail-limit = 10485760;
    };

    "org/gnome/nautilus/list-view" = {
      default-column-order = [ "name" "size" "type" "date_modified" ];
      default-visible-columns = [ "name" "size" "type" "date_modified" ];
      default-zoom-level = "small";
      use-tree-view = true;
    };

    "org/gnome/nautilus/window-state" = {
      maximized = true;
      sidebar-width = 220;
      start-with-sidebar = true;
    };
  };
}
