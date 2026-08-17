{ pkgs, ... }:
let
  scriptDir = ./scripts;
  scriptEntries = builtins.readDir scriptDir;

  regularFiles = builtins.filter (name: scriptEntries.${name} == "regular") (
    builtins.attrNames scriptEntries
  );

  shellScripts = builtins.filter (name: builtins.match ".*\\.sh$" name != null) regularFiles;

  mkScript = name: {
    name = name;
    value = pkgs.writeScriptBin (builtins.replaceStrings [ ".sh" ] [ "" ] name) (
      builtins.readFile (scriptDir + "/${name}")
    );
  };

  scriptsSet = builtins.listToAttrs (map mkScript shellScripts);
  scripts = builtins.attrValues scriptsSet;
  rebuildScript = pkgs.writeScriptBin "rebuild" (builtins.readFile ../../../scripts/rebuild.sh);
  llmServeSource = pkgs.writeText "llm-serve.py" (builtins.readFile ./scripts/llm-serve.py);
  llmServe = pkgs.writeShellApplication {
    name = "llm-serve";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      exec python3 ${llmServeSource} "$@"
    '';
  };
in
{
  home.packages = scripts ++ [
    rebuildScript
    llmServe
  ];

  xdg.configFile."llm-serve/config.toml".source = ./llm-serve.toml;
}
