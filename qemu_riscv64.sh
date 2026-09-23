#!/bin/sh
qemu-system-riscv64 -nographic \
	-m 1g -M virt \
	-netdev user,id=vioif0 \
	-device virtio-net-device,netdev=vioif0 \
	-object rng-random,filename=/dev/urandom,id=rng0 \
	-device virtio-rng-device,rng=rng0 \
	-drive file=./workdir/NetBSD-11.0-riscv-riscv64.qcow2,if=none,id=hd0 \
	-device virtio-blk-device,drive=hd0 \
	-kernel ./workdir/kernel/11.0/riscv-riscv64/netbsd-GENERIC64 \
	-append 'root=ld4' \
	$*
