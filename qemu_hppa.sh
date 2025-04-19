#!/bin/sh
qemu-system-hppa \
	-m 512 \
	-display sdl \
	-netdev user,id=wm0 \
	-device e1000,netdev=wm0 \
	-hda ./workdir/NetBSD-10.1-hppa.qcow2 \
	-kernel ./workdir/kernel/10.1/hppa/netbsd-GENERIC \
	-append 'root=sd0c' \
	$*
