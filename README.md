# rpi4-64-ubuntu
Ubuntu Server 18.04 LTS (Bionic Beaver) ARM64 for the Raspberry Pi 4

## Prerequisites
- Linux Operating System (currently only working on Ubuntu)
- [gcc](http://gcc.gnu.org/)
- [GNU make](http://www.gnu.org/software/make)
- Raspberry Pi 4B
- Root privileges (ability to use `sudo` in order to mount and unmount devices)

## Obtaining the source code
```
git clone https://github.com/mikhail-j/rpi4-64-ubuntu
```

## Compiling the Linux kernel from [`raspberrypi/linux`](https://github.com/raspberrypi/linux/)
Run `build_ubuntu_arm64_kernel.sh` from within the folder `rpi4-64/18.04`.
```sh
sh ./build_ubuntu_arm64_kernel.sh
```

## Generating a bootable Ubuntu Server ARM64 image
This step should be done after the cross-compiled Linux kernel has finished compiling.

Run `build_ubuntu_arm64_image.sh` from within the folder `rpi-64/18.04`.
```sh
sh ./build_ubuntu_arm64_image.sh
```

The Ubuntu Server ARM64 image for the Raspberry Pi 4 will be named `ubuntu-18.04.*-preinstalled-server-arm64+rpi4.img`.

