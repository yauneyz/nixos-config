# Stylix Wallpaper & Theme Configuration Guide

## Quick Reference (Current Setup)

Your Stylix config at `modules/core/stylix.nix` has two main controls:

### 1. Change Wallpaper
Edit line 8:
```nix
wallpaperPath = ../../wallpapers/otherWallpaper/gruvbox/forest_road.jpg;
```
Change to any image path, then rebuild.

### 2. Change Theme Mode
Edit line 5:
```nix
useWallpaperColors = false;  # Change to true for wallpaper-derived colors
```

## Detailed Options

### Option A: Use Pre-made Color Schemes (Recommended)
Keep `useWallpaperColors = false` and change the theme:

```nix
base16Scheme = "${pkgs.base16-schemes}/share/themes/THEME_NAME.yaml";
```

**Popular themes available:**
- `gruvbox-dark-hard.yaml` (current)
- `gruvbox-dark-medium.yaml`
- `gruvbox-dark-soft.yaml`
- `gruvbox-light-hard.yaml`
- `catppuccin-mocha.yaml`
- `catppuccin-macchiato.yaml`
- `dracula.yaml`
- `nord.yaml`
- `tokyo-night-dark.yaml`
- `tokyo-night-storm.yaml`
- `onedark.yaml`
- `solarized-dark.yaml`

**See all available themes:**
```bash
ls $(nix-build '<nixpkgs>' -A base16-schemes --no-out-link)/share/themes/
```

### Option B: Wallpaper-Derived Colors
Set `useWallpaperColors = true` and Stylix will automatically extract colors from your wallpaper image.

**Tips:**
- Works best with vibrant, colorful wallpapers
- Set `polarity = "dark"` or `"light"` to control brightness
- The wallpaper determines your entire color scheme

### Option C: Custom Base16 Scheme
Create your own color scheme file:

```nix
base16Scheme = {
  base00 = "1d2021";  # Background
  base01 = "3c3836";  # Lighter Background
  base02 = "504945";  # Selection Background
  base03 = "665c54";  # Comments
  base04 = "bdae93";  # Dark Foreground
  base05 = "d5c4a1";  # Foreground
  base06 = "ebdbb2";  # Light Foreground
  base07 = "fbf1c7";  # Light Background
  base08 = "fb4934";  # Red
  base09 = "fe8019";  # Orange
  base0A = "fabd2f";  # Yellow
  base0B = "b8bb26";  # Green
  base0C = "8ec07c";  # Cyan
  base0D = "83a598";  # Blue
  base0E = "d3869b";  # Purple
  base0F = "d65d0e";  # Brown
};
```

## Workflow Examples

### Quick Theme Switch:
```nix
# In modules/core/stylix.nix
base16Scheme = lib.mkIf (!useWallpaperColors)
  "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";  # Changed!
```
Then: `sudo nixos-rebuild switch`

### Wallpaper + Manual Theme:
```nix
useWallpaperColors = false;
wallpaperPath = ../../wallpapers/my-cool-image.png;  # Sets wallpaper
base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";  # Sets colors
```

### Wallpaper-Based Theme:
```nix
useWallpaperColors = true;  # Colors from wallpaper
wallpaperPath = ../../wallpapers/vibrant-sunset.jpg;
polarity = "dark";
```

## Advanced: Per-Application Overrides

If you want Stylix to theme most things but override specific apps:

```nix
stylix.targets = {
  firefox.enable = false;     # Manually configure Firefox
  kitty.enable = true;        # Let Stylix handle Kitty
  # etc...
};
```

## Current Configuration Summary

Your setup uses:
- **Wallpaper**: `wallpapers/otherWallpaper/gruvbox/forest_road.jpg`
- **Theme Mode**: Fixed color scheme (not wallpaper-derived)
- **Color Scheme**: Gruvbox Dark Hard
- **Polarity**: Dark
- **Font**: Maple Mono (monospace), DejaVu Sans/Serif

To change themes, edit `modules/core/stylix.nix` and rebuild with:
```bash
sudo nixos-rebuild switch
```
