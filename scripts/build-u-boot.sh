#!/bin/bash
set -e

UBOOT=$1
if [ -z "${UBOOT}" ] ; then
  UBOOT=u-boot
fi

CURRENT_DIR="$(pwd)"

if [ ! -f bl31.bin.xz ] ; then
  echo "Build TF-A first!"
  exit 1
fi

if [ ! -d ${UBOOT} ] ; then
  git clone --depth 1 -b mtk/openwrt-one \
    https://github.com/sjoerdsimons/u-boot.git
fi

echo "==== Build u-boot ===="
pushd ${UBOOT}

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CC=aarch64-linux-gnu-gcc
export O=/tmp/openwrt-one

make mt7981_openwrt_one_defconfig O=${O}
make -j$(nproc) O=${O}
popd
xz -e -k -9 -C crc32 ${O}/u-boot.bin -c > ${O}/u-boot.bin.xz

echo "==== Create FIP ======="
# FIP is BL31 from snand build + u-boot
fiptool create --soc-fw ${CURRENT_DIR}/bl31.bin.xz --nt-fw ${O}/u-boot.bin.xz ${O}/u-boot.fip
cp -v ${O}/u-boot.fip ${CURRENT_DIR}/openwrt-mediatek-filogic-openwrt_one-snand-bl31-uboot.fip
