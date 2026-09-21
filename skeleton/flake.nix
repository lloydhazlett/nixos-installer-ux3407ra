# NixOS for the ASUS Zenbook A14 (UX3407RA).
#
# Usage:
#   sudo nixos-install --root /mnt --flake /mnt/etc/nixos#zenbook
#   sudo nixos-rebuild switch --flake /etc/nixos#zenbook
{
  description = "NixOS for the ASUS Zenbook A14 (UX3407RA)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs =
    { nixpkgs, ... }:
    {
      # EDIT: rename `zenbook` to your hostname and keep it in sync with
      # networking.hostName in configuration.nix.
      nixosConfigurations.zenbook = nixpkgs.lib.nixosSystem {
        modules = [
          ./configuration.nix
          ./filesystems.nix
          ./hardware.nix
        ];
        system = "aarch64-linux";
      };
    };
}
