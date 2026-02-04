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

      debloater = pkgs.writeShellApplication {
        name = "adb-debloater";
        runtimeInputs = with pkgs; [jq android-tools];

        text = builtins.readFile ./src/debloat.sh;

        excludeShellChecks = ["SC2086"];
        bashOptions = ["nounset"];
      };
      debloater-with-json = pkgs.runCommand ''adb-debloater'' {} ''
        mkdir -p $out/bin
        cp -r ${./.}/JSON $out
        ln -s ${pkgs.lib.getExe debloater} $out/bin
      '';
    in {
      packages.default = debloater-with-json;
    });
}
