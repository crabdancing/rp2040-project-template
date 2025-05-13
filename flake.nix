# FIXME: `cargo run` should automatically flash pico
{
  description = "Build a cargo project without extra checks";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    crane,
    flake-utils,
    rust-overlay,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [(import rust-overlay)];
      };
      rust = pkgs.rust-bin.stable.latest.default.override {
        extensions = ["rust-analyzer" "rust-src"];
        targets = ["x86_64-unknown-linux-gnu" "thumbv6m-none-eabi"];
      };

      nativeBuildInputs = with pkgs; [
        openocd-rp2040
        probe-rs
        flip-link
        elf2uf2-rs
      ];
      craneLib = (crane.mkLib pkgs).overrideToolchain rust;

      my-crate =
        (craneLib.buildPackage {
          src = ./.; #craneLib.cleanCargoSource (craneLib.path ./.);
          strictDeps = true;
          # strictDeps = false;
          # cargoExtraArgs = "--features rp-pico/cortex-m-rt --features rp2040-hal/rt";

          inherit nativeBuildInputs;
          # Breaks on cross compile for RP2040
          doCheck = false;
          # c = ''
          #   mkdir -p "$out"
          #   echo "OUT: $out"
          #   ls -lah $out
          #   echo "OUT_DIR: $OUT_DIR"
          #   cp -a ${./memory.x} "$OUT_DIR/memory.x"
          #   rm -rf $out/src/bin/crane-dummy-*
          # '';
          extraDummyScript = ''
            cp -a ${./memory.x} $out/memory.x
            (shopt -s globstar; rm -rf $out/**/src/bin/crane-dummy-*)
          '';
          buildInputs =
            [
              # Add additional build inputs here
            ]
            ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
              # Additional darwin specific inputs can be set here
              pkgs.libiconv
            ];
        })
        .overrideAttrs (old: {
          patchPhase =
            (old.patchPhase
              or "")
            + ''
            '';
        });
    in {
      checks = {
        inherit my-crate;
      };

      packages.default = my-crate;

      apps.default = flake-utils.lib.mkApp {
        drv = my-crate;
      };

      devShells.default = craneLib.devShell {
        # Inherit inputs from checks.
        checks = self.checks.${system};
        inherit nativeBuildInputs;

        # Additional dev-shell environment variables can be set directly
        # MY_CUSTOM_DEVELOPMENT_VAR = "something else";

        # Extra inputs can be added here; cargo and rustc are provided by default.
        packages = [
          # pkgs.ripgrep
        ];
      };
    });
}
