#!/bin/sh
qemu-system-ppc -nographic \
	-m 512 -machine mac99,via=pmu \
	-cdrom ./workdir/ofwboot.qcow2 \
	-hda workdir/NetBSD-9.2-macppc.qcow2 \
	-prom-env boot-device=cd:\ofwboot.xcf \
	-prom-env boot-file=hd:/netbsd \
	-netdev user,id=wm0 \
	-device e1000,netdev=wm0 \
	$*

	# virtio at pci... testing
	#-netdev user,id=vioif0 \
	#-device virtio-net-pci,netdev=vioif0 \
	#-object rng-random,filename=/dev/urandom,id=rng0 \
	#-device virtio-rng-pci,rng=rng0 \
