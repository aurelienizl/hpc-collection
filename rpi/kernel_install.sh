#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Run as sudo"
  exit 1
fi

echo "--- Extracting ---"
tar -xzf rpi5-rt-kernel-bare.tar.gz

echo "--- Installing Files ---"
# 1. Move Kernel & Device Trees
cp kernel8_rt.img /boot/firmware/
cp *.dtb /boot/firmware/
# 2. Move Overlays
cp overlays/*.dtb* /boot/firmware/overlays/
# 3. Move Modules
cp -r lib/modules/* /lib/modules/

echo "--- Updating Configuration ---"
# 4. Update cmdline.txt
ARGS=$(cat cmdline_append.txt | tr -d '\n')
sed -i "1s/$/ $ARGS/" /boot/firmware/cmdline.txt

# 5. Update config.txt
echo "kernel=kernel8_rt.img" >> /boot/firmware/config.txt

echo "--- Done ---"
read -p "Reboot now? (y/n): " choice
if [[ "$choice" == "y" ]]; then
    reboot
fi