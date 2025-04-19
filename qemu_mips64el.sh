#!/bin/sh
qemu-system-mips64el -nographic \
	-m 512 -machine mipssim-virtio \
	-netdev user,id=vioif0 \
	-device virtio-net-device,netdev=vioif0 \
	-object rng-random,filename=/dev/urandom,id=rng0 \
	-device virtio-rng-device,rng=rng0 \
	-drive file=./workdir/NetBSD-10.1-evbmips-mips64el.qcow2,if=none,id=hd0 \
	-device virtio-blk-device,drive=hd0 \
	-kernel ./workdir/kernel/10.1/evbmips-mips64el/netbsd-MIPSSIM64 \
	-append 'root=ld0' \
	$*
