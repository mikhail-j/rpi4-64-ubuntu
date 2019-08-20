#!/bin/sh
# Generate a 64-bit Ubuntu Server 18.04 (Bionic Beaver) image for the Raspberry Pi 4.
#
# Note: This script was written to modify the Ubuntu Server preinstalled cloud
# image for the Raspberry Pi 3 on Ubuntu.
#
# Copyright (C) 2019 Qijia (Michael) Jin
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# check if arm64 toolchain directory exists
ARM64_TOOLCHAIN=$(pwd)/rpi64/arm64_toolchain/aarch64
if !(test -d $ARM64_TOOLCHAIN); then
	echo "error: could not find arm64 toolchain!"
	exit 1
fi

if !(test -d $(pwd)/rpi64/linux/build); then
	echo "error: could not find expected arm64 linux kernel!"
	exit 1
fi

# check if Raspberry Pi 4 `config.txt` exists in current directory
if !(test -e "config.txt"); then
	echo "error: expected 'config.txt' in current directory!"
	exit 1
fi

# check if raspberrypi/firmware repository has been cloned
if !(test -d $(pwd)/rpi64/firmware/); then
	cd rpi64
	git clone https://github.com/raspberrypi/firmware/
	if test $? -ne 0; then
		# remove git repository 'raspberrypi/firmware' and exit
		rm -rf firmware
		exit 1
	fi

	cd ../
fi

# make sure we have kpartx on Ubuntu
sudo apt-get install kpartx
if test $? -ne 0; then
	exit $?
fi

LATEST_BIONIC=$(curl http://cdimage.ubuntu.com/ubuntu/releases/bionic/release/ | grep "arm64+raspi3.img.xz\"" | head -n 1 | cut -d '"' -f 2)

if !(test -e $LATEST_BIONIC); then
	wget http://cdimage.ubuntu.com/ubuntu/releases/bionic/release/$LATEST_BIONIC
	if test $? -ne 0; then
		exit $?
	fi
	curl http://cdimage.ubuntu.com/ubuntu/releases/bionic/release/SHA256SUMS | grep arm64+raspi3 > $LATEST_BIONIC.sha256
	if test $? -ne 0; then
		exit $?
	fi
fi

sha256sum -c "$LATEST_BIONIC".sha256
if test $? -ne 0; then
	exit $?
fi

MODIFIED_IMAGE=$(echo "$LATEST_BIONIC" | cut -d '+' -f 1)+rpi4.img

xzcat $LATEST_BIONIC > $MODIFIED_IMAGE
if test $? -ne 0; then
	exit $?
fi

if !(test -d root); then
	mkdir root
	if test $? -ne 0; then
		exit $?
	fi
fi

if !(test -d boot); then
	mkdir boot
	if test $? -ne 0; then
		exit $?
	fi
fi

LOOP_DEVICE=$(sudo kpartx -av $MODIFIED_IMAGE | head -n 1 | awk ' { print $3 } ' | cut -d 'p' -f 1,2)

echo "$LOOP_DEVICE" | grep "loop" && echo "loop device mapped!"
if test $? -ne 0; then
	exit $?
fi
echo "loop device: $LOOP_DEVICE"

KERNEL_VERSION=$(cat rpi64/linux/build/include/generated/utsrelease.h | awk ' { gsub(/"/,""); print $3 } ')

sudo mount /dev/mapper/"$LOOP_DEVICE"p2 root
sudo mount /dev/mapper/"$LOOP_DEVICE"p1 boot

sudo cp -avf $(pwd)/rpi64/linux/build/install/lib/modules/$KERNEL_VERSION root/lib/modules/

sudo cp $(pwd)/rpi64/linux/build/arch/arm64/boot/Image $(pwd)/boot/kernel8.img
sudo cp $(pwd)/rpi64/firmware/boot/*.dat $(pwd)/boot/
sudo cp $(pwd)/rpi64/firmware/boot/*.elf $(pwd)/boot/
sudo cp $(pwd)/rpi64/firmware/boot/bootcode.bin $(pwd)/boot/
sudo cp $(pwd)/rpi64/linux/build/arch/arm64/boot/dts/broadcom/*.dtb $(pwd)/boot/

sudo rm -rf $(pwd)/boot/overlays/
sudo cp -R $(pwd)/rpi64/linux/build/arch/arm64/boot/dts/overlays/ $(pwd)/boot/

sudo cp -R $(pwd)/config.txt $(pwd)/boot/


# sleep for 10 seconds to allow for unmounting, otherwise loop device is busy
sleep 10

sudo umount root
sudo umount boot

sudo kpartx -dv $MODIFIED_IMAGE




