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
  '';

  buildPhase = ''
  '';

  installPhase = ''
    mkdir -p $out/bin
    #zig build -Doptimize=ReleaseFast -Dtls=true -Dport=443 --prefix $out
    zig build -Doptimize=Debug -Dtls=false -Dport=9862 --prefix $out
    mv $out/bin/website $out/bin/mukigg
  '';

  outputs = [ "out" ];

  meta = {
    description = "The muki.gg website";
    homepage = "https://muki.gg";
    platforms = [ "x86_64-linux" ];
  };
}
