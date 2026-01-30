{ stdenv, fetchFromGitHub, perl, ... }:

stdenv.mkDerivation {
  pname = "2048";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "Frost-Phoenix";
    repo = "2048-cli";
    rev = "e5b5e2b";
    sha256 = "sha256-DqOSfKQC7WdslEknzFByZPc20AsjX6+5PwKR3gqucOM=";
  };

  nativeBuildInputs = [ perl ];

  postPatch = ''
    substituteInPlace src/main.c \
      --replace-warn 'void signal_callback_handler()' 'void signal_callback_handler(int signum)'
    perl -0777 -i -pe 's/(void signal_callback_handler\\(int signum\\)\\s*\\{)/$1\\n    (void)signum;/s' src/main.c
  '';

  buildPhase = ''
    make release
  '';

  installPhase = ''
    mkdir -p $out/bin
    make install INSTALL_DIR=$out/bin
    chmod +x $out/bin/2048
  '';
}
