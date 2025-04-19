#!/bin/sh
# Replace -display line with -display curses for headless use.
modload nvmm
qemu-system-x86_64 \
	-accel nvmm \
	-cpu max -smp cpus=2 \
	-m 1G \
	-display sdl,gl=on -vga vmware \
	-usb -device usb-mouse,bus=usb-bus.0 \
	-netdev user,id=vioif0 \
	-device virtio-net-pci,netdev=vioif0 \
	-audiodev oss,id=oss,out.dev=/dev/audio0,in.dev=/dev/audio0 \
	-device ac97,audiodev=oss \
	-object rng-random,filename=/dev/urandom,id=rng0 \
	-device virtio-rng-pci,rng=rng0 \
	-drive file=./workdir/NetBSD-10.1-amd64.qcow2,if=none,id=hd0 \
	-device virtio-blk-pci,drive=hd0 $*
