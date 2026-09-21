# NixOS installer for the ASUS Zenbook A14 (UX3407RA)

A bootable NixOS installer image for the Snapdragon X Elite (`x1e80100`)
ASUS Zenbook A14, model **UX3407RA**. The stock NixOS AArch64 installer does
not boot on this machine: the display blanks during early device coldplug and
neither the USB drive nor the internal NVMe ever reaches the block layer.

This image fixes both problems and boots to a usable text install environment.

Other "A14" laptops are unrelated hardware. The UX3407QA is a different SoC
and is not covered here.

## What works

Internal OLED console, USB boot media, internal NVMe, Wi-Fi, USB-C Ethernet
(Realtek, ASIX, Aquantia and CDC adapters), NetworkManager, and SSH.

## What does not

The image runs on the EFI firmware framebuffer, not the native Qualcomm
display stack — `dispcc_x1e80100` is blacklisted because loading it blanks the
panel. There is therefore no GPU acceleration and no USB-C DisplayPort. Audio,
Bluetooth and the camera are not addressed by the installer.

## How it differs from the stock installer

Four changes, each needed to reach a shell:

- **Ubuntu Concept 6.16 kernel** instead of the nixpkgs kernel. Its embedded
  EFI loader picks the UX3407RA device tree from DMI, so `hardware.deviceTree`
  stays off and no DTB is passed from the bootloader.
- **A wider initrd module closure.** Every modular driver the selected DTB
  matches, notably `fixed` (without it the RPMh regulators never register and
  no storage appears at all) and `phy_nxp_ptn3222` (the USB PHY repeater).
- **`module_blacklist=dispcc_x1e80100` and `regulator_ignore_unused`.** The
  first keeps the firmware framebuffer alive; the second stops the regulator
  core powering off `VREG_EDP_3P3` behind it about 30 seconds into stage 2.
- **`cutmem 0x8800000000 0x8fffffffff` in GRUB.** The firmware advertises an
  unusable upper 32 GiB. This matches the Ubuntu Concept memory map and is
  applied by repacking the ISO's GRUB image after the NixOS build.

The image also uses NixOS's scripted initrd with Ubuntu's udev 257.4 and its
matching base rules, because that is the early userspace known to work here.

## Build

Requires an **x86_64 Linux** machine with Nix and flakes enabled. The image is
cross compiled to AArch64; no emulation or remote builder is needed.

```console
nix build github:lloydhazlett/nixos-installer-ux3407ra#installer-iso
ls -lh result/iso/nixos-ux3407ra-installer.iso
```

Expect roughly 1.6 GiB of output and a long first build, most of it fetching
and cross compiling the base system.

## Write to a USB drive

Use a drive of at least 2 GiB. **Check the destination device carefully — this
erases it.**

```console
lsblk
sudo dd if=result/iso/nixos-ux3407ra-installer.iso of=/dev/sdX bs=4M \
  status=progress conv=fdatasync
```

## Boot it

1. Enter firmware setup (F2 at power-on) and **disable Secure Boot**. The
   image is unsigned.
2. Select the USB drive from the boot menu (Esc or F8 at power-on).
3. If the firmware does not offer it, use the "boot from file" entry and
   select `EFI/BOOT/BOOTAA64.EFI` on the USB drive.

GRUB waits indefinitely for a selection; press Enter on the default entry.
Kernel messages stay visible through boot, which is deliberate — this is a
bring-up image and the boot log is the main diagnostic if something fails.

You should reach an automatic login as `nixos` on `tty1`. Useful checks:

```console
uname -a
cat /proc/device-tree/model
ip -brief link
lsblk
journalctl -b -k | grep -Ei 'drm|msm|panel|typec|usb|r8152|cdc|ax88179|aqc111'
```

## Networking and SSH

Use `nmtui` for Wi-Fi or a USB-C Ethernet adapter.

`sshd` runs, but the live `nixos` user has no password and no authorised key,
and `sshd` rejects empty passwords. To log in remotely, set a password on the
console first:

```console
passwd
```

Then connect as `nixos@<address>`. If you would rather use a key, append it to
`~/.ssh/authorized_keys` on the live system, or add your own module to
`installer.nix` and rebuild the image.

## Install NixOS

Partition and format as you prefer — the image ships `parted`, `gptfdisk`,
`cryptsetup` and the usual `mkfs` tools. Mount the target root at `/mnt` and
the EFI system partition at `/mnt/boot`, then:

```console
sudo nixos-generate-config --root /mnt
sudo nixos-install --root /mnt
```

Partitioning is destructive, and this machine normally ships with Windows.
Identify the internal NVMe and preserve any partitions you want to keep.

Your installed configuration needs the same hardware workarounds this image
uses, or it will not boot. At minimum:

- the Ubuntu Concept kernel from [`packages/ubuntu-x1e-kernel.nix`](packages/ubuntu-x1e-kernel.nix),
  with `hardware.deviceTree.enable = false`;
- the initrd module list from [`installer.nix`](installer.nix), including
  `fixed` and `phy_nxp_ptn3222`;
- `boot.kernelParams` containing `efi=noruntime`,
  `module_blacklist=dispcc_x1e80100` and `regulator_ignore_unused`;
- GRUB rather than systemd-boot, with `efiInstallAsRemovable = true`,
  `canTouchEfiVariables = false`, and the `cutmem` line above in
  `boot.loader.grub.extraConfig`.

`efi=noruntime` means the install cannot write EFI variables, so GRUB is
installed to the removable-media fallback path `EFI/BOOT/BOOTAA64.EFI`.

## Notes

- The Ubuntu Concept kernel is a bring-up kernel, not a maintained security
  update path. Move to a supported mainline kernel once its display path works
  on this machine.
- Scripted initrd is deprecated in nixpkgs and scheduled for removal in 26.11.
  This image depends on it, so it will need reworking before then.
- Hardware support comes from
  [kuruczgy/x1e-nixos-config](https://github.com/kuruczgy/x1e-nixos-config).
  There is no UX3407RA profile upstream, so this extends the Yoga Slim 7x ISO
  and replaces its kernel, device-tree handling and module closure.
- The kernel and udev packages are repackaged Ubuntu binaries fetched at build
  time from the [ubuntu-concept/x1e PPA](https://launchpad.net/~ubuntu-concept/+archive/ubuntu/x1e)
  and Ubuntu ports. Nothing proprietary is redistributed here.

## Licence

MIT. See [LICENSE](LICENSE).
