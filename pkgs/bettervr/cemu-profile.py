"""Maintain a separate Cemu settings.xml for BetterVR sessions.

seed    <flat settings.xml> <vr settings.xml>   Create the VR profile once.
enforce <vr settings.xml>                       Re-apply settings BetterVR needs.

Seeding copies the flat profile so controllers, paths and audio carry over,
then applies the upstream BetterVR recommendations. Later in-game changes to
the VR profile are kept; enforce only touches settings the mod requires.
"""

import sys
import xml.etree.ElementTree as ET

BOTW = "graphicPacks/downloadedGraphicPacks/BreathOfTheWild"
COMMUNITY_GRAPHICS = f"{BOTW}/Graphics/rules.txt"
FPS_PP = f"{BOTW}/Mods/FPS++/rules.txt"
ENHANCEMENTS = f"{BOTW}/Enhancements/rules.txt"
DRAW_DISTANCE = f"{BOTW}/Mods/DrawDistance/rules.txt"
BETTERVR = "graphicPacks/BreathOfTheWild_BetterVR/rules.txt"
BETTERVR_GRAPHICS = "graphicPacks/BreathOfTheWild_BetterVR_Graphics/rules.txt"

# The VR Resolution Multiplier preset names start with a resolution computed
# for the headset at build time; match them by their multiplier suffix.
VR_RESOLUTION_SUFFIX = "(1.5x, Balanced Quality)"


def load(path):
    return ET.parse(path)


def child(parent, tag):
    node = parent.find(tag)
    if node is None:
        node = ET.SubElement(parent, tag)
    return node


def entry(packs, filename):
    for e in packs.findall("Entry"):
        if e.get("filename") == filename:
            return e
    return ET.SubElement(packs, "Entry", filename=filename)


def enable(packs, filename, presets=None):
    e = entry(packs, filename)
    e.attrib.pop("disabled", None)
    for category, preset in (presets or {}).items():
        for p in e.findall("Preset"):
            if p.findtext("category") == category:
                e.remove(p)
        p = ET.SubElement(e, "Preset")
        ET.SubElement(p, "category").text = category
        ET.SubElement(p, "preset").text = preset
    return e


def disable(packs, filename):
    e = entry(packs, filename)
    for p in list(e):
        e.remove(p)
    e.set("disabled", "true")


def vr_resolution_preset(rules_path):
    with open(rules_path, encoding="utf-8") as f:
        for line in f:
            if line.startswith("name =") and line.rstrip().endswith(VR_RESOLUTION_SUFFIX):
                return line.split("=", 1)[1].strip()
    sys.exit(f"no VR resolution preset ending in {VR_RESOLUTION_SUFFIX!r}")


def enforce(root):
    packs = child(root, "GraphicPack")
    # BetterVR renders through its own Graphics pack; two resolution packs
    # would fight over the same render targets.
    disable(packs, COMMUNITY_GRAPHICS)
    enable(packs, BETTERVR)
    # BetterVR crashes without FPS++.
    enable(packs, FPS_PP)
    if entry(packs, BETTERVR_GRAPHICS).find("Preset") is None:
        enable(packs, BETTERVR_GRAPHICS)
    graphic = child(root, "Graphic")
    child(graphic, "api").text = "1"  # Vulkan; the mod is a Vulkan layer
    child(graphic, "VSync").text = "0"
    child(graphic, "vkAccurateBarriers").text = "false"


def seed(root, graphics_rules):
    packs = child(root, "GraphicPack")
    enable(
        packs,
        BETTERVR_GRAPHICS,
        {
            "Recording Mode": "Disabled (Default)",
            "VR Resolution Multiplier": vr_resolution_preset(graphics_rules),
            "Anti-Aliasing": "NVIDIA FXAA",
            "Shadows": "High (200%)",
            "Shadow Draw Distance": "Very High (Recommended)",
        },
    )
    enable(
        packs,
        FPS_PP,
        {
            "Mode": "Normal Settings",
            "FPS Limit": "120FPS Limit",
            "Static Mode": "Disabled (Default, dynamically adjust game speed)",
            "Fence Type": "Performance Fence (Default)",
        },
    )
    enable(
        packs,
        ENHANCEMENTS,
        {
            "Anisotropic Filtering": "Extreme (16x)",
            # Screen-space depth of field blurs whatever the eyes converge on.
            "Depth Of Field": "Disabled (no performance gain)",
        },
    )
    # The mod is CPU-bound and renders every frame twice, so keep actor
    # distance moderate and spend headroom on GPU-side detail instead.
    enable(
        packs,
        DRAW_DISTANCE,
        {
            "NPC, Enemies And Other Entities": "High (1.25x)",
            "Terrain, Buildings, Bushes And Other Objects": "High (1.25x)",
            "Grass Blades Density": "High",
            "Trees (2D Billboards)": "Ultra",
            "Texture Distance Detail (LOD)": "Much higher(-3)",
        },
    )
    graphic = child(root, "Graphic")
    child(graphic, "AsyncCompile").text = "true"
    child(root, "fullscreen").text = "false"
    enforce(root)


def write(tree, path):
    ET.indent(tree, space="    ")
    tree.write(path, encoding="UTF-8", xml_declaration=True)


def main():
    cmd = sys.argv[1]
    if cmd == "seed":
        flat, vr, graphics_rules = sys.argv[2:5]
        tree = load(flat)
        seed(tree.getroot(), graphics_rules)
        write(tree, vr)
    elif cmd == "enforce":
        vr = sys.argv[2]
        tree = load(vr)
        enforce(tree.getroot())
        write(tree, vr)
    else:
        sys.exit(f"unknown command {cmd}")


if __name__ == "__main__":
    main()
