# device-provisioner

`device-provisioner` is a simple, standalone Debian-based live image used to flash and provision devices.

The image is generated with [debos](https://github.com/go-debos/debos) and boots into a minimal live environment that allows you to:

- Install an arbitrary pre-created disk image to a target device.
- Perform post-install setup steps (like expand the target disk).

The installed image can be any operating system. This tool is intentionally OS-agnostic.

Based on [sjoerdsimons/openwrt-one-debian](https://github.com/sjoerdsimons/openwrt-one-debian).
