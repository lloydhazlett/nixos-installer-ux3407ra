{
  config,
  lib,
  pkgs,
  ...
}:

let
  ubuntuUdev = pkgs.callPackage ./packages/ubuntu-udev.nix { };
  ubuntuUdevWrapper = pkgs.writeText "ubuntu-udev-wrapper" ''
    #! @extraUtils@/bin/ash
    ux3407raUdevName=''${0##*/}

    ux3407raRunUdev() {
      @extraUtils@/lib/ld-linux-aarch64.so.1 \
        --argv0 "$ux3407raUdevName" \
        --library-path @extraUtils@/ubuntu/lib:@extraUtils@/lib \
        @extraUtils@/ubuntu/udevadm "$@"
    }

    if [ "$ux3407raUdevName" = systemd-udevd ]; then
      echo "UX3407RA udev: starting Ubuntu daemon with name resolution disabled..."
      exec @extraUtils@/lib/ld-linux-aarch64.so.1 \
        --argv0 "$ux3407raUdevName" \
        --library-path @extraUtils@/ubuntu/lib:@extraUtils@/lib \
        @extraUtils@/ubuntu/udevadm "$@" --resolve-names=never
    fi

    if [ "$1" = trigger ] && [ "$2" = --action=add ] && [ "$#" -eq 2 ]; then
      echo "UX3407RA udev: daemon returned; triggering subsystems..."
      ux3407raRunUdev trigger --type=subsystems --action=add || exit

      echo "UX3407RA udev: triggering devices..."
      exec @extraUtils@/lib/ld-linux-aarch64.so.1 \
        --argv0 "$ux3407raUdevName" \
        --library-path @extraUtils@/ubuntu/lib:@extraUtils@/lib \
        @extraUtils@/ubuntu/udevadm trigger --type=devices --action=add
    fi

    if [ "$1" = settle ]; then
      echo "UX3407RA udev: settling device coldplug..."
    fi

    exec @extraUtils@/lib/ld-linux-aarch64.so.1 \
      --argv0 "$ux3407raUdevName" \
      --library-path @extraUtils@/ubuntu/lib:@extraUtils@/lib \
      @extraUtils@/ubuntu/udevadm "$@"
  '';
in
lib.mkIf (lib.versionOlder config.boot.kernelPackages.kernel.version "7.0") {
  # The working Ubuntu Concept initramfs uses udev 257.4 and its matching base
  # rules. Stage 2 still keeps NixOS's systemd 261.
  boot.initrd.extraUdevRulesCommands = lib.mkAfter ''
    for ux3407raRule in \
      50-firmware.rules \
      50-udev-default.rules \
      60-block.rules \
      60-cdrom_id.rules \
      60-persistent-storage.rules \
      61-persistent-storage-android.rules \
      64-btrfs.rules \
      73-special-net-names.rules \
      75-net-description.rules \
      80-drivers.rules \
      80-net-setup-link.rules; do
      rm -f "$out/$ux3407raRule"
      cp -v "${ubuntuUdev}/lib/udev/rules.d/$ux3407raRule" "$out/"
    done
    substituteInPlace "$out/64-btrfs.rules" \
      --replace-fail /usr/bin/udevadm udevadm
  '';
  boot.initrd.extraUtilsCommands = lib.mkAfter ''
    rm -f "$out/bin/systemd-udevd" "$out/bin/udevadm"
    mkdir -p "$out/ubuntu/lib"
    cp -pv ${ubuntuUdev}/bin/udevadm "$out/ubuntu/"
    cp -pv ${ubuntuUdev}/lib/systemd/libsystemd-shared-257.so "$out/ubuntu/lib/"
    substitute ${ubuntuUdevWrapper} "$out/bin/udevadm" \
      --replace-fail @extraUtils@ "$out"
    chmod 0555 "$out/bin/udevadm"
    for ux3407raLibraryDirectory in ${
      lib.escapeShellArgs (map (dependency: "${lib.getLib dependency}/lib") ubuntuUdev.runtimeLibraries)
    }; do
      for ux3407raLibrary in "$ux3407raLibraryDirectory"/*.so.*; do
        [ -e "$ux3407raLibrary" ] || continue
        ux3407raLibraryTarget="$out/lib/$(basename "$ux3407raLibrary")"
        if [ ! -e "$ux3407raLibraryTarget" ]; then
          cp -Lpv "$ux3407raLibrary" "$ux3407raLibraryTarget"
        fi
      done
    done
    ln -s udevadm "$out/bin/systemd-udevd"
  '';
}
