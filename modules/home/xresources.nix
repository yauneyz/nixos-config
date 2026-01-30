{ config, ... }:
{
  xresources.properties = {
    "XTerm*renderFont" = true;
    "XTerm*faceName" = config.stylix.fonts.monospace.name;
    "XTerm*faceSize" = config.stylix.fonts.sizes.terminal;
  };
}
