{ pkgs ? import <nixpkgs> {} }:
let
in
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    openocd-rp2040
    probe-rs
    flip-link
    elf2uf2-rs
  ];
  buildInputs = [
  ];
  # LD_LIBRARY_PATH= pkgs.lib.makeLibraryPath [ pkgs.libusb ];
  shellHook = ''
    exec env SHELL=nu $SHELL
  '';
}


