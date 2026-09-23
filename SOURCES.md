# Corresponding source

The installer image is an aggregate of many separately licensed works. Most
of them are built by Nix from sources pinned by hash in `flake.lock` and the
derivations in [`packages/`](packages), so their corresponding source is
already precisely identified and fetchable.

Two components are the exception. They are fetched as **prebuilt Ubuntu
binary packages**, so this repository never touches their source. This file
records where that source is, to satisfy GPL-2.0 section 3 for the kernel and
LGPL-2.1 for systemd/udev.

Every release that carries an ISO should also carry the kernel source tarball
listed below as a release asset. That is what makes the binary "accompanied
by" its source rather than relying on a promise.

## Ubuntu Concept kernel

Pinned by [`packages/ubuntu-x1e-kernel.nix`](packages/ubuntu-x1e-kernel.nix).
Licensed GPL-2.0-only.

Binary consumed by the build:

```text
https://ppa.launchpadcontent.net/ubuntu-concept/x1e/ubuntu/pool/main/l/linux-qcom-x1e/linux-modules-6.16.0-27-qcom-x1e_6.16.0-27.27_arm64.deb
sha256-oNIY9SjxcWGTn3dNr/nAiMGziH29R0EA+e4L0xkk4iE=
```

Corresponding source:

```text
https://ppa.launchpadcontent.net/ubuntu-concept/x1e/ubuntu/pool/main/l/linux-qcom-x1e/linux-qcom-x1e_6.16.0-27.27.tar.gz
sha256  e876625f1d365a7b3d94b7c8da519418c79afcbaa24e5ccc7ab07ac1b83bb12d
size    257018387 bytes (245 MiB)

https://ppa.launchpadcontent.net/ubuntu-concept/x1e/ubuntu/pool/main/l/linux-qcom-x1e/linux-qcom-x1e_6.16.0-27.27.dsc
```

The `.tar.gz` is the complete Ubuntu source package, upstream tree and
packaging together. The `.dsc` is the manifest and carries the checksum above.

## Ubuntu systemd / udev 257.4

Pinned by [`packages/ubuntu-udev.nix`](packages/ubuntu-udev.nix). Licensed
LGPL-2.1-or-later.

Binaries consumed by the build:

```text
https://ports.ubuntu.com/ubuntu-ports/pool/main/s/systemd/udev_257.4-1ubuntu3.1_arm64.deb
sha256-Eq6xcRSCAxxqTOCwjxhAkQuye7tLbgy27E6+ejbA5Rw=

https://ports.ubuntu.com/ubuntu-ports/pool/main/s/systemd/libsystemd-shared_257.4-1ubuntu3.1_arm64.deb
sha256-DPArt1AAHOCOrXvuSN6D2sFDiyzLrSecWi40EoBlcrc=
```

Corresponding source. Source packages are architecture independent and live
on `archive.ubuntu.com`, not on `ports.ubuntu.com`:

```text
https://archive.ubuntu.com/ubuntu/pool/main/s/systemd/systemd_257.4.orig.tar.gz
sha256  3e7955ecdb8ad317b2876a31ad749e4dd71d371f343de40d856d62c1eb2ffa2a
size    16228313 bytes

https://archive.ubuntu.com/ubuntu/pool/main/s/systemd/systemd_257.4-1ubuntu3.1.debian.tar.xz
sha256  7f0dcf33070fc18f75e7f7e7055d7318c928a767d8ede7a5235c069c0eae6c48
size    256656 bytes

https://archive.ubuntu.com/ubuntu/pool/main/s/systemd/systemd_257.4-1ubuntu3.1.dsc
```

## Fetching it all

```console
kernel=https://ppa.launchpadcontent.net/ubuntu-concept/x1e/ubuntu/pool/main/l/linux-qcom-x1e
systemd=https://archive.ubuntu.com/ubuntu/pool/main/s/systemd

curl -fLO --remote-name-all \
  "$kernel/linux-qcom-x1e_6.16.0-27.27.tar.gz" \
  "$kernel/linux-qcom-x1e_6.16.0-27.27.dsc" \
  "$systemd/systemd_257.4.orig.tar.gz" \
  "$systemd/systemd_257.4-1ubuntu3.1.debian.tar.xz" \
  "$systemd/systemd_257.4-1ubuntu3.1.dsc"

sha256sum -c <<'EOF'
e876625f1d365a7b3d94b7c8da519418c79afcbaa24e5ccc7ab07ac1b83bb12d  linux-qcom-x1e_6.16.0-27.27.tar.gz
3e7955ecdb8ad317b2876a31ad749e4dd71d371f343de40d856d62c1eb2ffa2a  systemd_257.4.orig.tar.gz
7f0dcf33070fc18f75e7f7e7055d7318c928a767d8ede7a5235c069c0eae6c48  systemd_257.4-1ubuntu3.1.debian.tar.xz
EOF
```

PPAs remove superseded versions over time. If the kernel source URL above has
gone, the copy attached to the corresponding release on this repository is the
archival one.

## Everything else

The rest of the image is standard nixpkgs, built from source by Nix. To obtain
the corresponding source for any store path in the image:

```console
nix-store --query --deriver /nix/store/...
nix log /nix/store/....drv
```

Or fetch the source derivation directly:

```console
nix build --no-link nixpkgs#<package>.src
```

The nixpkgs revision is pinned in `flake.lock`, so these resolve to exactly
the sources used to build any given release.
