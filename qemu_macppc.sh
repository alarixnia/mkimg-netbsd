#!/bin/sh
qemu-system-ppc -nographic \
	-m 256 -machine mac99,via=pmu \
	-cdrom ./workdir/ofwboot.qcow2 \
	-hda workdir/NetBSD-10.1-macppc.qcow2 \
	-prom-env boot-device=cd:\ofwboot.xcf \
	-prom-env boot-file=hd:/netbsd \
	-netdev user,id=wm0 \
	-device e1000,netdev=wm0 \
	$*
