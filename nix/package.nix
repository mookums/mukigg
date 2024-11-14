{ stdenvNoCC, zig }:

stdenvNoCC.mkDerivation {
  pname = "mukigg";
  version = "0.0.0";

  src = ./..;

  nativeBuildInputs = [ zig ];

  buildInputs = [ ];

  dontConfigure = true;

  preBuild = ''
    export HOME=$TMPDIR
    zig build --fetch --prefix $out
  '';

  buildPhase = ''
  '';

  installPhase = ''
    mkdir -p $out/bin
    zig build -Doptimize=ReleaseSafe --prefix $out
  '';

  outputs = [ "out" ];

  meta = {
    description = "The muki.gg website";
    homepage = "https://muki.gg";
    platforms = [ "x86_64-linux" ];
  };
}
