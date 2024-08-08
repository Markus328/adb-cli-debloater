{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };

      debloater = pkgs.runCommand "adb-debloater" {buildInputs = with pkgs; [jq android-tools];} ''
        mkdir -p $out/bin
        cp ${./src/debloat.sh} $out/bin/adb-debloater
        sed -i "2 i export PATH=$PATH:\$PATH" $out/bin/adb-debloater'';
    in {
      packages.default = debloater;
    });
}
