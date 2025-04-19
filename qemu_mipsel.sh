#!/bin/sh
qemu-system-mipsel -nographic \
	-m 512 -machine mipssim-virtio \
	-netdev user,id=vioif0 \
	-device virtio-net-device,netdev=vioif0 \
	-object rng-random,filename=/dev/urandom,id=rng0 \
	-device virtio-rng-device,rng=rng0 \
	-drive file=./workdir/NetBSD-10.1-evbmips-mipsel.qcow2,if=none,id=hd0 \
	-device virtio-blk-device,drive=hd0 \
	-kernel ./workdir/kernel/10.1/evbmips-mipsel/netbsd-MIPSSIM \
	-append 'root=ld0' \
	$*
