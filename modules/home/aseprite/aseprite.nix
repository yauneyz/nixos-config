{ pkgs, ... }:
{
  home.packages = [
    # fmt 12 dropped the implicit fmt::format re-export that aseprite's
    # source relies on without including <fmt/format.h> directly, breaking
    # the build ("no member named 'format' in namespace 'fmt'"). Pin to
    # fmt_11 until upstream aseprite adapts.
    (pkgs.aseprite.override { fmt = pkgs.fmt_11; })
  ];
}
