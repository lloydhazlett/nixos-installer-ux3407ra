{
  baseVersion ? "6.16.0",
  dpkg,
  features ? { },
  fetchurl,
  kernelPatches ? [ ],
  kmod,
  lib,
  modDirVersion ? "6.16.0-27-qcom-x1e",
  randstructSeed ? "",
  sourceHash ? "sha256-oNIY9SjxcWGTn3dNr/nAiMGziH29R0EA+e4L0xkk4iE=",
  stdenvNoCC,
  version ? "6.16.0-27.27",
}:

let
  kernelFeatures = features;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "linux-ubuntu-qcom-x1e";
  inherit version;

  src = fetchurl {
    hash = sourceHash;
    url = "https://ppa.launchpadcontent.net/ubuntu-concept/x1e/ubuntu/pool/main/l/linux-qcom-x1e/linux-modules-${modDirVersion}_${version}_arm64.deb";
  };

  dontConfigure = true;
  dontPatchELF = true;
  dontStrip = true;
  nativeBuildInputs = [
    dpkg
    kmod
  ];
  outputs = [
    "out"
    "modules"
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --extract "$src" source
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    if [[ -d source/usr/lib/modules/${modDirVersion} ]]; then
      sourceLib=source/usr/lib
    else
      sourceLib=source/lib
    fi

    mkdir -p "$out/dtbs/qcom" "$modules/lib/modules/${modDirVersion}"
    cp source/boot/System.map-${modDirVersion} "$out/System.map"
    cp source/boot/config-${modDirVersion} "$out/config"
    cp source/boot/vmlinuz-${modDirVersion} "$out/Image"
    cp "$sourceLib"/firmware/${modDirVersion}/device-tree/qcom/*asus-zenbook-a14*.dtb "$out/dtbs/qcom/"
    cp -a "$sourceLib"/modules/${modDirVersion}/. "$modules/lib/modules/${modDirVersion}/"

    depmod -b "$modules" -F "$out/System.map" ${modDirVersion}

    runHook postInstall
  '';

  passthru = {
    inherit baseVersion;
    commonMakeFlags = [ ];
    config = rec {
      isDisabled = option: !isEnabled option;
      isEnabled = option: isYes option || isModule option;
      isModule = _: false;
      isNo = option: !isSet option;
      isSet = option: option == "MODULES";
      isYes = option: option == "MODULES";
    };
    configfile = "${finalAttrs.finalPackage}/config";
    inherit modDirVersion;
    features = {
      efiBootStub = true;
    }
    // kernelFeatures;
    isLTS = false;
    isZen = false;
    kernelAtLeast = lib.versionAtLeast baseVersion;
    kernelOlder = lib.versionOlder baseVersion;
    inherit kernelPatches randstructSeed;
    stdenv = stdenvNoCC;
    target = "Image";
  };

  meta = {
    description = "Ubuntu Concept kernel for Snapdragon X Elite laptops";
    homepage = "https://launchpad.net/~ubuntu-concept/+archive/ubuntu/x1e";
    license = lib.licenses.gpl2Only;
    platforms = [ "aarch64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
