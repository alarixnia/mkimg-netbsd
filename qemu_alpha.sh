#!/bin/sh
qemu-system-alpha \
	-m 512 \
	-display sdl \
	-netdev user,id=wm0 \
	-device e1000,netdev=wm0 \
	-hda ./workdir/NetBSD-10.1-alpha.qcow2 \
	-kernel ./workdir/kernel/10.1/alpha/netbsd-GENERIC \
	-append 'root=wd0c' \
	$*
