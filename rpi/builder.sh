#!/bin/bash
set -e

# --- Configuration ---
REPO_URL="https://github.com/raspberrypi/linux.git"
BRANCH="rpi-6.12.y"
WORK_DIR="/work/linux"
OUTPUT_DIR="/output"
CONFIG_FRAGMENT="/configs/rt-params.config"

echo "===================================================="
echo "   RPi 5 RT Kernel Builder (Bare Metal / No Docker)"
echo "===================================================="

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

# ... [Cloning and Cleaning steps remain the same] ...
if [ ! -d "$WORK_DIR/.git" ]; then
    git clone --depth=1 --branch $BRANCH $REPO_URL $WORK_DIR
else
    cd $WORK_DIR
    git fetch origin $BRANCH
    git reset --hard origin/$BRANCH
fi
cd $WORK_DIR
make mrproper
make bcm2712_defconfig

# ... [Merge Config] ...
if [ -f "$CONFIG_FRAGMENT" ]; then
    ./scripts/kconfig/merge_config.sh .config $CONFIG_FRAGMENT
else
    echo "ERROR: Fragment not found!"
    exit 1
fi

# ... [Compilation] ...
make -j$(nproc) Image modules dtbs

# ... [Export] ...
echo "--- Exporting Artifacts ---"
cp arch/arm64/boot/Image ${OUTPUT_DIR}/kernel8_rt.img
make modules_install INSTALL_MOD_PATH=${OUTPUT_DIR}
cp arch/arm64/boot/dts/broadcom/*.dtb ${OUTPUT_DIR}/
mkdir -p ${OUTPUT_DIR}/overlays
cp arch/arm64/boot/dts/overlays/*.dtb* ${OUTPUT_DIR}/overlays/
cp arch/arm64/boot/dts/overlays/README ${OUTPUT_DIR}/overlays/

# ... [Packaging] ...
cd ${OUTPUT_DIR}
tar -czf rpi5-rt-kernel-bare.tar.gz kernel8_rt.img lib/ overlays/ *.dtb cmdline_helper.txt

echo "SUCCESS: Build complete. Archive is at: ${OUTPUT_DIR}/rpi5-rt-kernel-bare.tar.gz"