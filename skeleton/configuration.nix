# A starting point for a NixOS system on the ASUS Zenbook A14 (UX3407RA).
#
# Everything marked EDIT is yours to change. The machine-specific settings
# live in hardware.nix and are best left alone; the disk layout lives in
# filesystems.nix and must match how you partitioned.
{ pkgs, ... }:

{
  console.keyMap = "us"; # EDIT

  environment.systemPackages = with pkgs; [
    cryptsetup
    ethtool
    git
    pciutils
    usbutils
    vim
  ];

  i18n.defaultLocale = "en_US.UTF-8"; # EDIT

  networking.hostName = "zenbook"; # EDIT, and keep flake.nix in sync
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [
    "flakes"
    "nix-command"
  ];

  # GNOME is usable on this machine, but only through the firmware
  # framebuffer: there is no GPU acceleration and no USB-C DisplayPort while
  # dispcc_x1e80100 stays blacklisted. Get a console boot working first, then
  # uncomment these two lines if you want a desktop.
  #
  # services.desktopManager.gnome.enable = true;
  # services.displayManager.gdm.enable = true;

  services.openssh = {
    enable = true;
    openFirewall = true;
    # Key-only by default. If you have not added a key below, leave this true
    # until you have logged in on the console and can add one.
    settings.PasswordAuthentication = false;
  };

  # Leave this at the NixOS release you first installed. It is not a version
  # to keep current; changing it on an existing system can lose data.
  system.stateVersion = "26.05";

  time.timeZone = "UTC"; # EDIT

  # EDIT: your account.
  users.users.you = {
    description = "Your Name";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    # Change this immediately after the first boot with `passwd`. It is
    # stored in the world-readable Nix store until you do.
    initialPassword = "changeme";
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      # "ssh-ed25519 AAAA... you@example"
    ];
  };

  zramSwap.enable = true;
}
