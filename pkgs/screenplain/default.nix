{
  lib,
  python3Packages,
}:

python3Packages.buildPythonApplication rec {
  pname = "screenplain";
  version = "0.12.0";
  pyproject = true;

  src = python3Packages.fetchPypi {
    inherit pname version;
    hash = "sha256-PpfDK1284o6WI6Nkk21xQiIoN6Z9G5KUJiaE+hO9TDw=";
  };

  build-system = [ python3Packages.setuptools ];
  dependencies = [ python3Packages.reportlab ];

  pythonImportsCheck = [ "screenplain" ];

  meta = {
    description = "Convert Fountain screenplays to PDF, HTML, or FDX";
    homepage = "https://www.screenplain.com/";
    license = lib.licenses.mit;
    mainProgram = "screenplain";
  };
}
