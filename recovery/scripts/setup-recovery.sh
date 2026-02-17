#!/bin/bash

# the flasher image is mounted as $IMAGEMNTDIR; the container is mounted as $ROOTDIR
# the flasher has created a debian container; this script copies the useful
# parts into the flasher image and installs a bootloader.

set -eu

# TODO: this script is too amd64-specific

cd ${IMAGEMNTDIR}

# Install systemd-boot
mkdir -p EFI/BOOT
cp ${ROOTDIR}/usr/lib/systemd/boot/efi/systemd-bootx64.efi EFI/BOOT/BOOTX64.EFI

mkdir -p EFI/systemd
cp ${ROOTDIR}/usr/lib/systemd/boot/efi/systemd-bootx64.efi EFI/systemd/systemd-bootx64.efi

mkdir -p loader/entries

cat << EOF > loader/loader.conf
timeout 10
default flasher
EOF

cat << EOF > loader/entries/flasher.conf
title Device Provisioner
linux /linux
initrd /initramfs.cpio.gz
#options root=/dev/ram0 systemd.unit=installer.target systemd.show_status quiet
options root=/dev/ram0
EOF

# Copy kernel
cp ${ROOTDIR}/boot/vmlinuz* linux

# Remove machine-id to generate random seed on each boot
rm ${ROOTDIR}/etc/machine-id

# Create initramfs from container contents
# TODO: this is already done in recipe ?
cd ${ROOTDIR}
rm -rf boot
find -H | cpio -H newc -o | pigz -c - > ${IMAGEMNTDIR}/initramfs.cpio.gz
