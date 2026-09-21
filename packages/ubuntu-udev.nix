{
  acl,
  dpkg,
  fetchurl,
  kmod,
  lib,
  libcap,
  libseccomp,
  libselinux,
  libxcrypt-legacy,
  linux-pam,
  openssl,
  stdenv,
  util-linux,
  xz,
  zstd,
}:

let
  version = "257.4-1ubuntu3.1";
  runtimeLibraries = [
    acl
    kmod
    libcap
    libseccomp
    libselinux
    libxcrypt-legacy
    linux-pam
    openssl
    util-linux
    xz
    zstd
  ];
  sharedDeb = fetchurl {
    hash = "sha256-DPArt1AAHOCOrXvuSN6D2sFDiyzLrSecWi40EoBlcrc=";
    url = "https://ports.ubuntu.com/ubuntu-ports/pool/main/s/systemd/libsystemd-shared_${version}_arm64.deb";
  };
  udevDeb = fetchurl {
    hash = "sha256-Eq6xcRSCAxxqTOCwjxhAkQuye7tLbgy27E6+ejbA5Rw=";
    url = "https://ports.ubuntu.com/ubuntu-ports/pool/main/s/systemd/udev_${version}_arm64.deb";
  };
in
stdenv.mkDerivation {
  pname = "ubuntu-udev";
  inherit version;

  dontPatchELF = true;
  dontStrip = true;
  dontUnpack = true;
  nativeBuildInputs = [
    dpkg
  ];
  passthru = {
    inherit runtimeLibraries;
  };

  installPhase = ''
    runHook preInstall

    dpkg-deb --extract ${udevDeb} udev
    dpkg-deb --extract ${sharedDeb} shared

    mkdir -p "$out/bin" "$out/lib/systemd" "$out/lib/udev"
    cp udev/usr/bin/udevadm "$out/bin/"
    cp shared/usr/lib/aarch64-linux-gnu/systemd/libsystemd-shared-257.so "$out/lib/systemd/"
    cp -a udev/usr/lib/udev/rules.d "$out/lib/udev/"

    runHook postInstall
  '';

  meta = {
    description = "Ubuntu Plucky udev matching the Snapdragon Concept initramfs";
    homepage = "https://packages.ubuntu.com/plucky/udev";
    license = lib.licenses.lgpl21Plus;
    platforms = [ "aarch64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
