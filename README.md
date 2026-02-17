# device-provisioner

`device-provisioner` is a simple, standalone Debian-based live image used to flash and provision devices.

The image is generated with [debos](https://github.com/go-debos/debos) and boots into a minimal live environment that allows you to:

- Install an arbitrary pre-created disk image to a target device.
- Perform post-install setup steps (like expand the target disk).

The installed image can be any operating system. This tool is intentionally OS-agnostic.

Based on [sjoerdsimons/openwrt-one-debian](https://github.com/sjoerdsimons/openwrt-one-debian).


## Build instructions

First build the flasher (for `amd64`, other arches will need additional cross-compilation):

```
$ podman run -it --rm \
    -v ./flasher:/mnt \
    -w /mnt \
    rust:slim-trixie \
    cargo build --release

$ cp ./flasher/target/release/flasher recovery/overlays/flasher/usr/local/bin/flasher
```


Prepare the disk image:

```
$ cp disk.img out/
$ zstd -k disk.img
$ bmaptool create disk.img > disk.img.bmap
```


Then build the image:

```
$ mkdir -p out
$ debos --artifactdir=out recovery/recovery.yaml
```
