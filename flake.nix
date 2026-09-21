# Usage:
# nix build .#installer-iso
{
  description = "NixOS installer image for the ASUS Zenbook A14 (UX3407RA)";

  inputs = {
    # Build tools for the ISO repack step. These run on the build machine, so
    # they are deliberately not the pinned installer nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    # The installer itself is cross compiled to aarch64 from this pinned
    # revision, which is the one x1e-nixos-config's ISO is known to build
    # against. Do not make it follow the tooling nixpkgs above.
    nixpkgs-installer.url = "github:nixos/nixpkgs/c71d88ec038d9c37b55b414d1c2d49f786592604";
    # Snapdragon X Elite (x1e80100) hardware support.
    x1e-installer = {
      inputs.nixpkgs.follows = "nixpkgs-installer";
      url = "github:kuruczgy/x1e-nixos-config/14f28d2791781570ee125659353df04a13ddb25f";
    };
  };

  outputs =
    {
      nixpkgs,
      x1e-installer,
      ...
    }:
    let
      # There is no UX3407RA profile upstream. The Yoga Slim 7x ISO is the
      # closest x1e80100 base; installer.nix replaces its kernel, device-tree
      # handoff, and module closure with the ones validated on this machine.
      installer-base =
        x1e-installer.nixosConfigurationsForBuildSystem.x86_64-linux.lenovo-yoga-slim7x-iso;
      installer-pkgs = installer-base.pkgs.extend (
        _final: prev: {
          # Nixpkgs c71d88e omits target headers when cross compiling
          # systemd's optional BPF objects. The installer does not use them.
          systemd = prev.systemd.override {
            withLibBPF = false;
          };
        }
      );
      installer-raw =
        (installer-base.extendModules {
          modules = [
            ./installer.nix
            {
              nixpkgs.pkgs = nixpkgs.lib.mkForce installer-pkgs;
            }
          ];
        }).config.system.build.isoImage;
      installer-tools = nixpkgs.legacyPackages.x86_64-linux;
      installer-iso =
        installer-tools.runCommand "nixos-ux3407ra-installer.iso-aarch64-unknown-linux-gnu"
          {
            nativeBuildInputs = [
              installer-pkgs.buildPackages.grub2_efi
              installer-tools.mtools
              installer-tools.xorriso
            ];
          }
          ''
            rawIso=${installer-raw}/iso/nixos-ux3407ra-installer.iso

            mkdir -p "$out/iso" "$out/nix-support"
            xorriso -osirrox on -indev "$rawIso" \
              -extract /EFI/BOOT/grub.cfg grub.cfg \
              -extract /boot/efi.img efi.img

            substituteInPlace grub.cfg \
              --replace-fail \
              'set timeout=-1' \
              'set timeout=-1

            # Snapdragon X Elite firmware exposes an unusable upper 32 GiB.
            # Match the known-good Ubuntu Concept bootloader memory map.
            cutmem 0x8800000000 0x8fffffffff'

            grub-mkimage \
              --directory=${installer-pkgs.grub2_efi}/lib/grub/${installer-pkgs.grub2_efi.grubTarget} \
              --output=BOOTAA64.EFI \
              --prefix=/EFI/BOOT \
              --format=${installer-pkgs.grub2_efi.grubTarget} \
              fat iso9660 part_gpt part_msdos \
              normal boot linux configfile loopback chain halt \
              efifwsetup efi_gop ls \
              search search_label search_fs_uuid search_fs_file echo \
              serial gfxmenu gfxterm gfxterm_background gfxterm_menu \
              test loadenv all_video videoinfo png mmap

            chmod u+w efi.img
            mcopy -o -i efi.img grub.cfg ::/EFI/BOOT/grub.cfg
            mcopy -o -i efi.img BOOTAA64.EFI ::/EFI/BOOT/BOOTAA64.EFI

            xorriso \
              -indev "$rawIso" \
              -outdev "$out/iso/nixos-ux3407ra-installer.iso" \
              -boot_image any replay \
              -update grub.cfg /EFI/BOOT/grub.cfg \
              -update BOOTAA64.EFI /EFI/BOOT/BOOTAA64.EFI \
              -update efi.img /boot/efi.img \
              -commit

            cp ${installer-raw}/nix-support/system "$out/nix-support/system"
            echo "file iso $out/iso/nixos-ux3407ra-installer.iso" \
              > "$out/nix-support/hydra-build-products"
          '';
    in
    {
      packages.x86_64-linux = {
        default = installer-iso;
        inherit installer-iso;
      };
    };
}
