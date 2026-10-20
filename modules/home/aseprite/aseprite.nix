{ pkgs, ... }:
{
  home.packages = [
    # fmt 12 dropped the implicit fmt::format re-export that aseprite's
    # source relies on without including <fmt/format.h> directly, breaking
    # the build ("no member named 'format' in namespace 'fmt'"). Pin to
    # fmt_11 until upstream aseprite adapts.
    # Aseprite also installs bundled libarchive tools and manual pages. Prefer
    # the standalone libarchive package when Home Manager merges the profile.
    (pkgs.lib.lowPrio (pkgs.aseprite.override { fmt = pkgs.fmt_11; }))
  ];
}
