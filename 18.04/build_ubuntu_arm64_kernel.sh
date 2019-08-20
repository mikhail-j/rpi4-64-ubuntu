#!/bin/sh
# Build ARM64 toolchain and compile 'github.com/raspberrypi/linux'
# git repository's branch (rpi-4.19.y) of the Linux Kernel.
#
# Note: This script was written to build the Linux kernel on Ubuntu.
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

# calculate the number of CPU threads
THREAD_COUNT=$(cat /proc/cpuinfo | grep processor | wc -l)

# make sure we have the required header files on Ubuntu
sudo apt-get install libgmp-dev libmpfr-dev libmpc-dev

# make sure we have the required packages to compile the linux kernel
sudo apt-get install bison flex

# check if arm64 toolchain directory exists
ARM64_TOOLCHAIN=$(pwd)/rpi64/arm64_toolchain/aarch64
if !(test -d $ARM64_TOOLCHAIN); then
	mkdir -p rpi4/arm64_toolchain/aarch64
fi

# change directory to 'rpi64/arm64_toolchain/'
cd rpi64/arm64_toolchain/
wget https://ftp.gnu.org/gnu/binutils/binutils-2.32.tar.bz2

# change directory to 'rpi64/arm64_toolchain/aarch64/'
cd $ARM64_TOOLCHAIN
tar -xjf ../binutils-2.32.tar.bz2

cd binutils-2.32
./configure --prefix=$ARM64_TOOLCHAIN --target=aarch64-linux-gnu
make -j $THREAD_COUNT
make check
make install

# change directory to 'rpi64/arm64_toolchain/'
cd ../../
wget https://ftp.gnu.org/gnu/gcc/gcc-9.2.0/gcc-9.2.0.tar.xz
cd aarch64
tar -xJf ../gcc-9.2.0.tar.xz

cd gcc-9.2.0
./configure --prefix=$ARM64_TOOLCHAIN --target=aarch64-linux-gnu --with-newlib --without-headers \
--disable-shared --disable-threads --disable-libssp --disable-decimal-float --disable-libquadmath \
--disable-libvtv --disable-libgomp --disable-libatomic --enable-languages=c,c++,fortran
make all-gcc -j $THREAD_COUNT
make -j $THREAD_COUNT check
make install-gcc

# change directory to 'rpi64'
cd ../../../

# clone 'raspberrypi/linux' git repository and compile the 'rpi-4.19.y' branch of the Linux kernel
git clone https://github.com/raspberrypi/linux.git
cd linux
git checkout rpi-4.19.y

mkdir build
env PATH=$ARM64_TOOLCHAIN/bin:$PATH make O=build ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2711_defconfig
env PATH=$ARM64_TOOLCHAIN/bin:$PATH make -j $THREAD_COUNT O=build ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-

KERNEL_VERSION=$(cat build/include/generated/utsrelease.h | awk ' { gsub(/"/,""); print $3 } ')
sudo make -j $THREAD_COUNT O=build DEPMOD=echo MODLIB=install/lib/modules/${KERNEL_VERSION} INSTALL_FW_PATH=install/lib/firmware modules_install
