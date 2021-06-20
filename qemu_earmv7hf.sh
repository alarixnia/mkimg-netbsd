#!/bin/sh
# For headless use, replace lines under -display with -nographic.
qemu-system-arm \
	-machine virt \
	-cpu cortex-a7 -smp cpus=2 \
	-m 1G \
	-bios ./workdir/misc/9.2/evbarm-earmv7hf/QEMU_EFI.fd \
	-netdev user,id=vioif0 \
	-device virtio-net-pci,netdev=vioif0 \
	-object rng-random,filename=/dev/urandom,id=rng0 \
	-device virtio-rng-pci,rng=rng0 \
	-drive file=./workdir/NetBSD-9.2-evbarm-earmv7hf.qcow2,if=none,id=hd0 \
	-device virtio-blk-pci,drive=hd0 \
	-display sdl,gl=on \
	-device ramfb \
	-device usb-ehci,id=ehci \
	-device usb-mouse,bus=ehci.0 \
	-device usb-kbd,bus=ehci.0 \
	$*
