# Disk layout. EDIT THIS to match how you partitioned the machine.
#
# As written this expects two filesystems, found by label so you do not have
# to paste UUIDs in after formatting:
#
#   - a FAT32 EFI system partition labelled BOOT, mounted at /boot
#   - an ext4 root filesystem labelled root, mounted at /
#
# Set those labels while formatting, for example:
#
#   mkfs.vfat -F 32 -n BOOT /dev/nvme0n1p5
#   mkfs.ext4 -L root /dev/nvme0n1p6
#
# This machine normally ships with Windows. Identify the internal NVMe and
# preserve any partitions you want to keep before formatting anything.
{ ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-label/root";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
  };

  swapDevices = [ ];

  # Whole-disk encryption, optional. The root filesystem lives inside a LUKS2
  # container unlocked by a passphrase prompt on the console at boot. The ESP
  # must stay unencrypted so the firmware can read the bootloader.
  #
  # To use it: give the LUKS partition the GPT partition label `cryptroot`
  # when partitioning, put the ext4 `root` filesystem inside the opened
  # container, and uncomment the block below.
  #
  #   cryptsetup luksFormat /dev/nvme0n1p6
  #   cryptsetup open /dev/nvme0n1p6 cryptroot
  #   mkfs.ext4 -L root /dev/mapper/cryptroot
  #
  # boot.initrd.luks.devices.cryptroot = {
  #   # SSD TRIM. Leaks a little metadata about used blocks; standard on laptops.
  #   allowDiscards = true;
  #   device = "/dev/disk/by-partlabel/cryptroot";
  # };
}
