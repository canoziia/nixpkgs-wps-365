{
  description = "WPS Office 365 Nix Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        packages.default = pkgs.callPackage ./default.nix { };

        apps = {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/wps";
          };
          wps = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/wps";
          };
          wpp = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/wpp";
          };
          et = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/et";
          };
          pdf = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/pdf";
          };
        };
      }
    );
}
