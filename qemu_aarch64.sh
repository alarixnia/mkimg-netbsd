#!/bin/sh
# For headless use, replace lines under -display with -nographic.
qemu-system-aarch64 \
	-machine virt \
	-cpu cortex-a53 -smp cpus=2 \
	-m 1G \
	-bios ./workdir/misc/10.1/evbarm-aarch64/QEMU_EFI.fd \
	-netdev user,id=vioif0 \
	-device virtio-net-pci,netdev=vioif0 \
	-object rng-random,filename=/dev/urandom,id=rng0 \
	-device virtio-rng-pci,rng=rng0 \
	-drive file=./workdir/NetBSD-10.1-evbarm-aarch64.qcow2,if=none,id=hd0 \
	-device virtio-blk-pci,drive=hd0 \
	-display sdl,gl=on \
	-device ramfb \
	-device usb-ehci,id=ehci \
	-device usb-mouse,bus=ehci.0 \
	-device usb-kbd,bus=ehci.0 \
	$*
