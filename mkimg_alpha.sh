#!/bin/sh
#
# Requirements: qemu
#
RELEASE="10.1"
ARCH="alpha"
PKG_ARCH="alpha"
SET_SUFFIX=".tgz"
SETS="base comp etc games man misc modules text"
SETS="${SETS} rescue tests"
# X is often needed for binary packages...
SETS="${SETS} xbase xcomp xetc xfont xserver"
KERNEL="GENERIC"
MIRROR="https://cdn.NetBSD.org/pub/NetBSD"
PKG_MIRROR="https://cdn.NetBSD.org/pub/pkgsrc"
PACKAGES="pkg_alternatives pkgin" 

mkdir -p "workdir/sets/${RELEASE}/${ARCH}"
mkdir -p "workdir/kernel/${RELEASE}/${ARCH}"

vndconfig -u vnd0 2>/dev/null
umount -f /mnt 2>/dev/null

echo Creating image...

dd if=/dev/zero of=./workdir/NetBSD-${RELEASE}-${ARCH}.img bs=1m count=8000
vndconfig -c vnd0 ./workdir/NetBSD-${RELEASE}-${ARCH}.img

echo Intializing FFSv2 filesystem...

newfs -I -B le -O2 "/dev/rvnd0"

printf 'Mounting /dev/vnd0...\n'

mount "/dev/vnd0" /mnt
mkdir -p /mnt/boot /mnt/kern /mnt/proc

echo Installing sets...

for set in $SETS; do
	if ! [ -f "workdir/sets/${RELEASE}/${ARCH}/${set}${SET_SUFFIX}" ]; then
		ftp -o "workdir/sets/${RELEASE}/${ARCH}/${set}${SET_SUFFIX}" \
		    "${MIRROR}/NetBSD-${RELEASE}/${ARCH}/binary/sets/${set}${SET_SUFFIX}"
	fi
	printf 'Extracting %s...\n' "$set"
	tar -C /mnt -xpf "./workdir/sets/${RELEASE}/${ARCH}/${set}${SET_SUFFIX}"
done

if ! [ -f "workdir/kernel/${RELEASE}/${ARCH}/netbsd-${KERNEL}" ]; then
	if ! [ -f "workdir/kernel/${RELEASE}/${ARCH}/netbsd-${KERNEL}.gz" ]; then
		ftp -o "workdir/kernel/${RELEASE}/${ARCH}/netbsd-${KERNEL}.gz" \
		    "${MIRROR}/NetBSD-${RELEASE}/${ARCH}/binary/kernel/netbsd-${KERNEL}.gz"
	fi
	printf 'Extracting kernel...\n'
	gunzip "workdir/kernel/${RELEASE}/${ARCH}/netbsd-${KERNEL}.gz"
fi

echo Generating RNG seed...

rndctl -S /mnt/var/db/entropy-file

echo Creating fstab...

cat << EOF > /mnt/etc/fstab
/dev/wd0c	/		ffs	rw,log,noatime,nodevmtime	1 1
kernfs		/kern		kernfs	rw
ptyfs		/dev/pts	ptyfs	rw
procfs		/proc		procfs	rw
tmpfs		/var/shm	tmpfs	rw,-m1777,-sram%25
EOF

echo Configuring system...

printf 'rc_configured=YES\n' >> /mnt/etc/rc.conf
printf 'no_swap=YES\n' >> /mnt/etc/rc.conf
printf 'dhcpcd=YES\n' >> /mnt/etc/rc.conf
printf 'sshd=YES\n' >> /mnt/etc/rc.conf
printf 'powerd=NO\n' >> /mnt/etc/rc.conf

echo Unmounting root partition...

umount /mnt

echo Converting image to qcow2...

qemu-img convert -f raw -O qcow2 \
	workdir/NetBSD-${RELEASE}-${ARCH}.img \
	workdir/NetBSD-${RELEASE}-${ARCH}.qcow2
