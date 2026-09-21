# Hardware support for the ASUS Zenbook A14 (UX3407RA), Snapdragon X Elite
# (x1e80100).
#
# You should not need to edit this file, and changing it casually will most
# likely produce a machine that does not boot. Every setting here was needed
# to get this hardware up; the comments record what breaks without each one.
{
  lib,
  pkgs,
  ...
}:

{
  boot.blacklistedKernelModules = [
    # Takes the panel away from the firmware framebuffer and cannot bring it
    # back, blanking the display in early boot. The kernel command line below
    # repeats this, which is what actually takes effect during coldplug.
    "dispcc_x1e80100"
    # Crashes the kernel often enough not to be worth having.
    "qcom_iris"
  ];

  # Ubuntu's module list carries RAID aliases this kernel has no literal
  # modules for. Ubuntu's own loader ignores those failed probes.
  boot.initrd.allowMissingModules = true;
  boot.initrd.availableKernelModules = (import ./ubuntu-concept-initrd-modules.nix) ++ [
    # Ubuntu makes every kernel module available to udev. These are the
    # modular drivers the UX3407RA device tree matches which the reduced NixOS
    # initrd would otherwise leave out. `fixed` is not optional: without it
    # the RPMh regulator graph never registers, every USB and PCIe PHY stays
    # deferred, and no block device appears at all.
    "apr"
    "fixed"
    "gpi"
    "gpio_keys"
    "gpucc_x1p42100"
    "icc_bwmon"
    "lpasscc_sc8280xp"
    "nvmem_qcom_spmi_sdam"
    "phy_nxp_ptn3222"
    "pinctrl_sm8550_lpass_lpi"
    "pwrseq_qcom_wcn"
    "qcom_cpucp_mbox"
    "qcom_geni_serial"
    "qcom_pon"
    "qcom_stats"
    "rtc_pm8xxx"
    "sbsa_gwdt"
    "sdhci_msm"
    "spi_geni_qcom"

    # USB host and storage. `phy_nxp_ptn3222` above is the USB PHY repeater
    # the DTB names; without it the USB controller stays deferred.
    "phy_qcom_qmp_combo"
    "phy_snps_eusb2"
    "phy_qcom_eusb2_repeater"
    "tcsrcc_x1e80100"
    "usb_storage"
    "uas"

    # Internal keyboard, touchpad, NVMe, and display.
    "i2c_hid_of"
    "i2c_qcom_geni"
    "nvme"
    "dispcc_x1e80100"
    "gpucc_x1e80100"
    "phy_qcom_edp"
    "panel_samsung_atna33xc20"
    "msm"

    # USB-C orientation and DisplayPort alternate mode.
    "phy_qcom_qmp_usb"
    "ps883x"
    "pmic_glink_altmode"
    "qcom_pmic_tcpm"
    "qrtr"
    "typec_displayport"
    "ucsi_glink"
  ];
  boot.initrd.includeDefaultModules = false;
  boot.initrd.kernelModules = lib.mkForce [ ];
  # The known-good Ubuntu initramfs uses a scripted /init, and the systemd
  # initrd path is not validated on this machine. Note that scripted initrd is
  # deprecated in nixpkgs and scheduled for removal in 26.11.
  boot.initrd.systemd.enable = lib.mkForce false;

  # The Ubuntu Concept kernel image contains a small EFI loader and every
  # supported DTB, and selects the UX3407RA tree from DMI before starting
  # Linux. Passing a device tree from the bootloader would override that
  # selection, which is why hardware.deviceTree stays off below.
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.callPackage ./packages/ubuntu-x1e-kernel.nix { });

  boot.kernelParams = [
    "clk_ignore_unused"
    # The firmware's EFI runtime services are not usable here. A consequence
    # is that the system cannot write EFI boot variables, which is why GRUB is
    # installed to the removable-media fallback path below.
    "efi=noruntime"
    "module_blacklist=dispcc_x1e80100"
    "pd_ignore_unused"
    # With the native display stack blocked, the regulator core decides
    # VREG_EDP_3P3 is unused and powers off the panel behind the still-live
    # firmware framebuffer about 30 seconds into stage 2.
    "regulator_ignore_unused"
  ];

  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.grub = {
    device = "nodev";
    efiInstallAsRemovable = true;
    efiSupport = true;
    enable = true;
    # The firmware advertises an unusable upper 32 GiB. Match the known-good
    # Ubuntu Concept bootloader memory map.
    extraConfig = ''
      cutmem 0x8800000000 0x8fffffffff
    '';
  };
  boot.loader.systemd-boot.enable = false;

  hardware.deviceTree.enable = false;
  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;

  imports = [
    ./ubuntu-concept-udev.nix
  ];

  # There is no TPM driver for this machine, and systemd otherwise spends 90
  # seconds at boot waiting for one.
  systemd.tpm2.enable = false;
}
