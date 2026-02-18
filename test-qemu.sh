#!/usr/bin/env bash

FLASHER_IMG="out/recovery.img"
ROOT_IMG="root.img"

# create a disk to install to
qemu-img create -f qcow2 ${ROOT_IMG} 50G

qemu-system-x86_64 \
  -machine type=q35,accel=kvm \
  -bios /usr/share/ovmf/OVMF.fd \
  -cpu host \
  -smp cpus=2 \
  -m 2048M \
  -device qemu-xhci,id=xhci \
  -drive file=${FLASHER_IMG},if=none,format=raw,id=flasher \
  -device usb-storage,drive=flasher,bus=xhci.0 \
  -device virtio-scsi-pci,id=scsi0 \
  -drive file=${ROOT_IMG},if=none,format=qcow2,discard=unmap,aio=native,cache=none,id=root -device scsi-hd,drive=root,bus=scsi0.0 \
  -boot menu=on \
  -vga qxl \
  -serial stdio \
  -device e1000,netdev=n1 \
  -netdev user,id=n1,hostfwd=tcp::2222-:22
