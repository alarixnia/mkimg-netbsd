#!/bin/sh
#
# Requirements: qemu, hfsutils, mozilla-rootcerts
#
# This generates a slightly unusual configuration with the NetBSD
# bootloader on a separate image to the root file system and kernel,
# the bootloader image being attached as a "CD-ROM" in QEMU.  This
# strange ance is required because OpenFirmware can only load the
# bootloader from an Apple HFS partition.
#
# With the GENERIC kernel, the root device (wd0c) needs to be specified
# by hand at the root device prompt once it's booted.
#
RELEASE="10.1"
ARCH="macppc"
SET_SUFFIX=".tgz"
SETS="base comp etc games man misc modules text"
SETS="${SETS} rescue tests"
SETS="${SETS} xbase xcomp xetc"
PACKAGES="pkg_alternatives pkgin distcc" 
MIRROR="https://cdn.NetBSD.org/pub/NetBSD"
PKG_MIRROR="https://cdn.NetBSD.org/pub/pkgsrc"

mkdir -p "workdir/sets/${RELEASE}/${ARCH}"

vndconfig -u vnd0 2>/dev/null
vndconfig -u vnd1 2>/dev/null
umount -f /mnt 2>/dev/null

echo Creating raw images...

dd if=/dev/zero bs=1m count=100 | progress dd of=./workdir/ofwboot.img bs=1m
vndconfig -c vnd0 ./workdir/ofwboot.img

dd if=/dev/zero bs=1m count=6000 | progress dd of=./workdir/NetBSD-${RELEASE}-${ARCH}.img bs=1m
vndconfig -c vnd1 ./workdir/NetBSD-${RELEASE}-${ARCH}.img

echo Intializing FFSv2 filesystem...

# XXX: Apple partition table does not seem bootable in QEMU
#printf "i\nc\n2p\n5900m\nroot\na\nw\ny\nq" | pdisk /dev/rvnd1
#newfs -B be -O 2 /dev/vnd1a

newfs -I -B be -O 2 /dev/vnd1

echo Mounting /dev/vnd1...

mount /dev/vnd1 /mnt
mkdir -p /mnt/kern /mnt/proc

echo Installing sets...

for set in $SETS; do
	if ! [ -f "workdir/sets/${RELEASE}/${ARCH}/${set}${SET_SUFFIX}" ];
	then
		ftp -o "workdir/sets/${RELEASE}/${ARCH}/${set}${SET_SUFFIX}" \
		    "${MIRROR}/NetBSD-${RELEASE}/${ARCH}/binary/sets/${set}${SET_SUFFIX}"
	fi
	printf 'Extracting %s...\n' "$set"
	progress -zf  "./workdir/sets/${RELEASE}/${ARCH}/${set}${SET_SUFFIX}" \
		tar -C /mnt -xpf -
done

if ! [ -f workdir/sets/${RELEASE}/${ARCH}/netbsd-GENERIC.gz ];
then
	ftp -o workdir/sets/${RELEASE}/${ARCH}/netbsd-GENERIC.gz \
		"${MIRROR}/NetBSD-${RELEASE}/macppc/binary/kernel/netbsd-GENERIC.gz"
fi

echo Installing kernel...

zcat workdir/sets/${RELEASE}/${ARCH}/netbsd-GENERIC.gz > /mnt/netbsd

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
printf 'hostname=vm\n' >> /mnt/etc/rc.conf
printf 'dhcpcd=YES\n' >> /mnt/etc/rc.conf
printf 'sshd=YES\n' >> /mnt/etc/rc.conf
printf 'powerd=NO\n' >> /mnt/etc/rc.conf
printf 'postfix=NO\n' >> /mnt/etc/rc.conf
printf 'fccache=NO\n' >> /mnt/etc/rc.conf
printf 'makemandb=NO\n' >> /mnt/etc/rc.conf

echo Installing packages...

for pkg in $PACKAGES;
do
	pkg_add -fI -P /mnt -K /usr/pkg/pkgdb \
		"${PKG_MIRROR}/packages/NetBSD/${ARCH}/${RELEASE}/All/${pkg}"
done

echo Installing Mozilla root certificates...

SSLDIR=/etc/openssl \
	mozilla-rootcerts -d /mnt install >/dev/null

echo Formatting HFS boot filesystem...

hformat /dev/vnd0d
hcopy /mnt/usr/mdec/ofwboot.xcf :

echo Unmonting FFSv2 filesystem...

umount /mnt

echo Converting HFS image to qcow2...

qemu-img convert -f raw -O qcow2 \
	workdir/ofwboot.img \
	workdir/ofwboot.qcow2

echo Converting FFSv2 image to qcow2...

qemu-img convert -f raw -O qcow2 \
	workdir/NetBSD-${RELEASE}-${ARCH}.img \
	workdir/NetBSD-${RELEASE}-${ARCH}.qcow2
