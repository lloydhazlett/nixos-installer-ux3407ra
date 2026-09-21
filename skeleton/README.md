# Skeleton NixOS configuration for the UX3407RA

A minimal configuration that boots this machine. Use it as the starting point
for an install once the installer image has booted.

It is self-contained: it vendors its own copies of the kernel package and the
udev compatibility module, so once you have copied it somewhere it does not
depend on this repository. The flip side is that it does not pick up later
fixes; check back here if something stops working.

## Files

| File | Edit it? |
| --- | --- |
| `configuration.nix` | Yes — hostname, user, locale, timezone, desktop. |
| `filesystems.nix` | Yes — must match how you partitioned. |
| `flake.nix` | Yes — one hostname to rename. |
| `hardware.nix` | No. These are the settings that make the machine boot. |
| `ubuntu-concept-*.nix`, `packages/` | No. Vendored support files. |

## Use it

From the booted installer, with the target root mounted at `/mnt` and the ESP
at `/mnt/boot`:

```console
sudo mkdir -p /mnt/etc/nixos
sudo nix flake init -t github:lloydhazlett/nixos-installer-ux3407ra --refresh
```

Run that last command from inside `/mnt/etc/nixos`. Without network access,
clone this repository instead and copy the `skeleton/` directory there.

Then edit the three files, and install:

```console
sudo nixos-install --root /mnt --flake /mnt/etc/nixos#zenbook
```

Substitute your own hostname for `zenbook` if you renamed it.

Do not run `nixos-generate-config` over the top of this. It cannot detect the
device tree, kernel or module closure this machine needs, and its output will
replace the settings that make it boot.

## First boot

The default entry is a console login. Log in as the user you configured with
the `initialPassword` from `configuration.nix`, then change it:

```console
passwd
```

SSH is enabled and key-only, so it will not accept logins until you add a key
to `openssh.authorizedKeys.keys` and rebuild.

Worth checking that the machine came up as expected:

```console
uname -a
cat /proc/device-tree/model
lsblk
ip -brief link
systemctl --failed
```

## What works

Internal OLED console and GNOME (on the firmware framebuffer), internal NVMe,
Wi-Fi, USB-C Ethernet, Bluetooth hardware, LUKS-encrypted root, suspend
untested.

## What does not

No GPU acceleration and no USB-C DisplayPort, because the native Qualcomm
display stack is blacklisted — see the comments in `hardware.nix`. Audio and
the camera need a newer kernel than the one pinned here. Battery telemetry
needs machine-specific ASUS firmware that cannot be redistributed, and is not
covered by this skeleton.

The pinned Ubuntu Concept kernel is a bring-up kernel, not a maintained
security update path. Move to a supported mainline kernel once its display
path works on this machine.
