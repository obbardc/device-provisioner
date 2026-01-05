#!/bin/bash

if [ ! -d arm-trusted-firmware ] ; then
  git clone --depth 1 -b mtksoc-20250711 https://github.com/mtk-openwrt/arm-trusted-firmware.git
fi

pushd arm-trusted-firmware

echo "==== Build TF-A for SNAND ===="
make -j $(nproc) PLAT=mt7981 USE_MKIMAGE=1 \
  BOOT_DEVICE=spim-nand  \
  UBI=1 OVERRIDE_UBI_START_ADDR=0x100000 \
  DRAM_USE_DDR4=1 HAVE_DRAM_OBJ_FILE=yes  \
  all

# To be packed into FIP image
xz -e -k -9 -C crc32 build/mt7981/release/bl31.bin -c > ../bl31.bin.xz
# Flashable to nand
cp -v build/mt7981/release/bl2.img ../openwrt-mediatek-filogic-openwrt_one-snand-preloader.bin
# Loadable over uart
cp -v build/mt7981/release/bl2.bin ../openwrt-mediatek-filogic-openwrt_one-snand-preloader.raw

echo "==== Build TF-A for UART DL ===="
make -j $(nproc) PLAT=mt7981  \
  BOOT_DEVICE=ram  \
  RAM_BOOT_UART_DL=1 \
  DRAM_USE_DDR4=1 HAVE_DRAM_OBJ_FILE=yes  \
  bl2
cp -v build/mt7981/release/bl2.bin ../mt7981-ram-ddr4-bl2.bin

popd
