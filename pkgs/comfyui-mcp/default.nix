{
  lib,
  buildNpmPackage,
  fetchurl,
  jq,
  nodejs,
  python3,
}:
# MCP server that lets Claude Code drive the local ComfyUI
# (https://github.com/artokun/comfyui-mcp). Built from the published npm
# tarball, which ships prebuilt dist/ but no lockfile; package-lock.json here
# was generated from that tarball's package.json with
#   npm install --package-lock-only --ignore-scripts --omit=dev
# To bump: change version + hash, regenerate the lockfile, then npmDepsHash.
buildNpmPackage rec {
  pname = "comfyui-mcp";
  version = "0.52.206";

  src = fetchurl {
    url = "https://registry.npmjs.org/comfyui-mcp/-/comfyui-mcp-${version}.tgz";
    hash = "sha256-fLmGoGlj0h15wB0coioNNxkMo8Twq3+OwTMRkQnAF/M=";
  };
  sourceRoot = "package";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
    # dist/ ships compiled; npmInstallHook's `npm pack` would run `prepare` (tsc).
    ${lib.getExe jq} 'del(.scripts.prepare)' package.json > package.json.new
    mv package.json.new package.json
  '';

  inherit nodejs;
  npmDepsHash = "sha256-63Gxi7m8NZr7NtVeZqpwqtLKnqcMvppYc9JF8z/lBw0=";
  npmFlags = [ "--omit=dev" ];
  dontNpmBuild = true;
  # Dependency install scripts fetch binaries from the network (cloudflared,
  # better-sqlite3 prebuilds). Skip them all and build the one native addon
  # the server needs from source below.
  npmRebuildFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [ python3 ];
  # No autoPatchelfHook: patching sharp's prebuilt libvips-cpp makes it
  # segfault on load. It needs no patching anyway — libvips is found via
  # $ORIGIN and libstdc++ is already loaded by node. The optional panel agent
  # binaries (codex, claude-agent-sdk) stay unpatched and unused by the server.

  preInstall = ''
    (cd node_modules/better-sqlite3 && npm run build-release --offline)
  '';

  meta = {
    description = "MCP server for driving ComfyUI from AI agents";
    homepage = "https://github.com/artokun/comfyui-mcp";
    license = lib.licenses.mit;
    mainProgram = "comfyui-mcp";
  };
}
