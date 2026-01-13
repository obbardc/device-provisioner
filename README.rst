Debian on OpenWrt One
======================

The `OpenWrt One`_ is a nice open hardware access point, running
OpenWrt by default. As the hardware is reasonably powerful and expandable,
running a more general purpose OS like Debian on it can be rather convenient.

The onboard storage (NAND) flash is 256MiB, which Debian can be made to fit.
However it's somewhat inconvenient and limiting. Luckily there is an M.2 slot
on the board to expand the storage via e.g. an NVMe, which this repo helps
installing Debian on.  **Note** The goal here is to just make it easy to
install an initial Debian image on the OpenWrt One. Not to provide a polished
end-user access-point experience, like e.g.  OpenWrt provides.

Requirements:

* OpenWrt One
* NVMe fitted in the device
* Serial console access (front type-c port, baudrate 115200)
* USB stick for installation

All artifacts for installation steps can be downloaded from the `latest build`_
(``openwrt*``) and should be placed on a USB stick (single FAT or FAT32 partition).

.. _OpenWrt One: https://openwrt.org/toh/openwrt/one
.. _latest build: https://github.com/sjoerdsimons/openwrt-one-debian/releases/tag/latest

Installation:
=============

The installation comes in two parts; First the NAND flash content is replaced
with an ``u-boot`` capable of directly booting from NVMe as well as ``recovery``
image to help with flashing the NVMe and potentially debugging system issues.
As a second step a Debian ``system`` image will be installed to the NVMe.

Flashing NAND:
--------------

To (re)flash NAND, the system is booted from NOR flash and NAND rewritten
from USB; To do this:

* Format a USB stick with a single FAT or FAT32 partition
* Download and put on the stick:

  * ``openwrt-mediatek-filogic-openwrt_one-snand-preloader.bin``
  * ``openwrt-mediatek-filogic-openwrt_one-factory.ubi``

Then to flash:

* Plug in the USB stick with the above mentioned files
* Switch boot selector on the back from NAND to NOR
* Press and hold the button on the front
* Power on the device
* Wait until the front leds turn on (all three)
* When only the white LED is on, you can release the button on the front
* Wait for the flashing to finish, green LED will turn on
* Remove power, switch boot selector back to NAND

If this sounds similar to `Boot into NOR/full recovery mode`_ on the OpenWrt One
'toh' page, that is not a coincidence.

.. _Boot into NOR/full recovery mode: https://openwrt.org/toh/openwrt/one#boot_into_norfull_recovery_modeflash_nand_from_usb

Flashing NVMe:
--------------

Now the NVMe can be flashed, also from USB.

* Format a USB stick with a single FAT or FAT32 partition
* Download:

  * the system image (e.g. ``openwrt-one-debian-<date>.img.zst``)
  * the associated bmap file (e.g. ``openwrt-one-debian-<date>.img.bmap``)

For flashing the recovery image should be booted from NAND:

* Plug in the USB stick with the above mentioned files
* Power on the device
* On first boot ``Bad EC magic`` messages can be shown, this can be ignored
* If there was no OS on the NVMe, the system will automatically boot the
  recovery image. Otherwise stop U-Boot and execute ``run boot_recovery``
* On boot a small flasher UI will show up on serial console.
* Simply select an image to flash (detected on USB drive)
* Once flashing is done, hit enter to reboot into the Debian system!
* On first boot ``systemd-firstboot`` will prompt for hostname, root shell,
  root password. Be aware the boot messages can somewhat hide it prompting to
  start.
* Have fun!

Alternatively hitting Ctrl-c in the flasher will boot through to a normal login
getty.

Recovery image:
===============

The recovery image as part of the NAND image is simply a minimal Debian system
running in memory. To access this system hit Ctrl-C when the flasher pops and
it will boot through to a getty. Login with user ``root``, password ``root``.
This can be used for analysing issues with the main installation. As it's a normal
Debian system, apt etc will work as expected. However as it's running from
memory it's all ephemeral.

Network wise *all* interfaces are configured to DHCP including wireless. For
connect to wireless ``iwd`` is pre-installed. ``wlan0`` is the 2.4 Ghz interface,
``wlan1`` is 5Ghz. To connect to a wireless network::

  # Get the available wireless networks
  iwctl station wlan1  get-networks
  # Connect to a network
  iwctl station wlan1 connect <network>


System image:
=============

The system image is a just minimal Debian system. With some basic initial tools and
configuration.

* Openssh server is installed. [#ssh]_
* Hostapd with example setups for both wireless interfaces

  * By default exposed as ssid ``openwrt-debian`` with PSK: ``debian on openwrt one``

* ``systemd-networkd`` for network configuration, by default:

  * ``WAN`` interface as DHCP
  * ``LAN`` interfaced bridge with the wireless in ``lanbr``. Also configured to DHCP

* default leds configured via an udev rule (leds.role)

  * Green led for each ethernet interface indicates link presence
  * Amber led for each ethernet interface indicates traffic
  * White front led shows a heartbeat pattern
  * Red front led triggers on kernel panic

* Root filesystem automatically expands to fill the disk on first boot

.. [#ssh] As per debians default config root can only login via keys over ssh by default.

Reverting to OpenWrt:
=====================

As the ``NOR`` flash isn't touched, to revert to OpenWrt simply use their `full
recovery instructions`_.

.. _full recovery instructions: https://openwrt.org/toh/openwrt/one#boot_into_norfull_recovery_modeflash_nand_from_usb
