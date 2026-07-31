# GRUB theme selector

Choose a theme independently in each host file:

```nix
zac.grubTheme = "sekiro.shadow";
```

Sets use `collection.variant` names, for example `sekiro.normal`,
`sekiro.shadow`, `hollow-grub.godmaster`, and
`grub-themes.minimal.nixos`. Standalone themes use one name, such as
`cyber-xero`. Nix reports every allowed value if an unknown name is selected;
the complete list is also in the `zac.grubTheme` option description.

The [Gorgeous-GRUB](https://github.com/Jacksaur/Gorgeous-GRUB) repository is a
gallery of previews and external links, not a repository containing the
installable themes. The selector therefore pins the actual upstream
repositories used by its entries.

## Vendored theme

`CyberXero/` is CyberXero 0.01 by L. TechXero, downloaded from the
[KDE Store](https://store.kde.org/p/1502415/). The upstream package is tagged
CC-BY-SA and has no stable source repository or permanent download URL, so the
theme assets are kept here to make NixOS rebuilds reproducible.

Other themes are fetched from immutable upstream revisions in
`../grub-theme.nix`.
