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

      rp2040-project-template = craneLib.buildPackage {
        src = ./.; #craneLib.cleanCargoSource (craneLib.path ./.);
        strictDeps = true;

        inherit nativeBuildInputs;
        doCheck = false;
        buildInputs = [
        ];
        RUSTFLAGS = "-C link-arg=--library-path=.";
      };
    in {
      checks = {
        inherit rp2040-project-template;
      };

      packages.default = rp2040-project-template;

      apps.default = flake-utils.lib.mkApp {
        drv = rp2040-project-template;
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
