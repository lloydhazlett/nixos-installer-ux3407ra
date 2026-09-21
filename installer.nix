# NixOS installer image for the ASUS Zenbook A14 (UX3407RA), Snapdragon X
# Elite (x1e80100). This extends the x1e-nixos-config Yoga Slim 7x ISO with
# the boot path validated on this machine: the Ubuntu Concept 6.16 kernel, a
# module closure wide enough for the UX3407RA device tree, and the firmware
# framebuffer in place of the not-yet-working native display stack.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  ubuntuConceptInitrdModules = import ./ubuntu-concept-initrd-modules.nix;
in
{
  # The base x1e installer module blacklists qcom_q6v5_pas. Ubuntu's working
  # concept initrd deliberately loads it, so match that known-good behaviour.
  boot.blacklistedKernelModules = lib.mkForce [
    "dispcc_x1e80100"
    "qcom_iris"
  ];
  boot.consoleLogLevel = 7;
  # Ubuntu's generic /conf/modules contains RAID aliases that this kernel does
  # not provide as literal modules. Its loader ignores those failed probes.
  boot.initrd.allowMissingModules = lib.mkForce true;
  boot.initrd.availableKernelModules = ubuntuConceptInitrdModules ++ [
    # Ubuntu makes every kernel module available to udev. Include every
    # modular driver matched by the selected Zenbook DTB that is otherwise
    # absent from this reduced initrd. `fixed` supplies the RPMh regulator
    # graph; `phy_nxp_ptn3222` supplies the remaining USB PHY repeater.
    # Without those two the RPMh regulators never register, so neither the
    # internal NVMe nor the installer USB reaches the block layer.
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

    # USB host and storage support. Most controller pieces are built into the
    # Ubuntu kernel, but listing them also documents the required boot path.
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

    # Common USB-C Ethernet adapters.
    "usbnet"
    "aqc111"
    "ax88179_178a"
    "cdc_ether"
    "cdc_ncm"
    "r8152"
  ];
  boot.initrd.includeDefaultModules = false;
  boot.initrd.kernelModules = lib.mkForce [
    # Live-ISO filesystem modules from the base installer configuration.
    "loop"
    "nls_cp437"
    "nls_iso8859-1"
    "overlay"
    "vfat"
  ];
  # Ubuntu starts udev and completes its initial coldplug before loading
  # /conf/modules. NixOS normally loads boot.initrd.kernelModules first, so run
  # Ubuntu's explicit sequence here, after the scripted initrd's udev pass.
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    for ux3407raModule in ${lib.escapeShellArgs ubuntuConceptInitrdModules}; do
      echo "loading Ubuntu Concept module $ux3407raModule..."
      modprobe "$ux3407raModule"
    done
  '';
  # Ubuntu's known-good initramfs uses initramfs-tools' scripted /init. Keep
  # systemd out of the only remaining materially different early-userspace
  # path while the hand-off to the live filesystem depends on matching it.
  boot.initrd.systemd.enable = lib.mkForce false;
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.callPackage ./packages/ubuntu-x1e-kernel.nix { });
  boot.kernelParams = lib.mkForce [
    "boot.shell_on_fail"
    "clk_ignore_unused"
    "console=tty0"
    "efi=noruntime"
    # The native display clock driver takes the panel away from the firmware
    # framebuffer and then fails to bring it back, blanking the screen during
    # early boot. Block it until the native display stack works here.
    "module_blacklist=dispcc_x1e80100"
    "pd_ignore_unused"
    # With the native display stack blocked, the regulator core sees
    # VREG_EDP_3P3 as unused and powers off the panel behind the still-active
    # firmware framebuffer roughly 30 seconds into stage 2.
    "regulator_ignore_unused"
    "root=LABEL=${config.isoImage.volumeID}"
  ];
  # An indefinite GRUB timeout also emits the `set timeout=-1` line that the
  # flake's cutmem patch matches. Changing it breaks that substitution.
  boot.loader.timeout = lib.mkForce null;
  boot.supportedFilesystems.cifs = lib.mkForce false;
  boot.supportedFilesystems.zfs = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    cryptsetup
    ethtool
    git
    pciutils
    usbutils
  ];

  # The Ubuntu kernel contains a small EFI loader and all supported DTBs. It
  # selects the UX3407RA tree from DMI data before starting Linux.
  hardware.deviceTree.enable = lib.mkForce false;
  hardware.enableAllHardware = lib.mkForce false;
  hardware.enableRedistributableFirmware = true;

  image.baseName = lib.mkOverride 40 "nixos-ux3407ra-installer";

  imports = [
    ./ubuntu-concept-udev.nix
  ];

  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  # The live `nixos` user has no password and no key, so sshd will reject
  # every login until one is set. See the README.
  services.openssh.enable = true;

  system.nixos.label = lib.mkOverride 90 "UX3407RA";
}
