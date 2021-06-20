#!/bin/sh
#
# Requirements: qemu, mozilla-rootcerts
#
# This generates a GPT-on-BIOS system.
#
RELEASE="9.2"
ARCH="amd64"
SET_SUFFIX=".tar.xz"
SETS="kern-GENERIC base comp etc games man misc modules text"
SETS="${SETS} rescue tests"
# X is often needed for binary packages...
SETS="${SETS} xbase xcomp xetc xfont xserver"
MIRROR="https://cdn.NetBSD.org/pub/NetBSD"
PKG_MIRROR="https://cdn.NetBSD.org/pub/pkgsrc"
PACKAGES="pkg_alternatives pkgin" 

mkdir -p "workdir/sets/${RELEASE}/${ARCH}"

vndconfig -u vnd0 2>/dev/null
umount -f /mnt 2>/dev/null

echo Creating image...

dd if=/dev/zero of=./workdir/NetBSD-${RELEASE}-${ARCH}.img bs=1m count=8000
vndconfig -c vnd0 ./workdir/NetBSD-${RELEASE}-${ARCH}.img

echo Intializing GPT table...

gpt destroy vnd0 2>/dev/null
gpt create vnd0
gpt add -b 64 -s 6000m -l root vnd0
dkctl vnd0 listwedges

root_wedge="$(dkctl vnd0 listwedges | tail -1 | cut -d: -f1)"
root_wedge_raw=$(printf '/dev/r%s' "$root_wedge")

echo Intializing FFSv2 filesystem...

newfs -B le -O2 "/dev/${root_wedge}"

printf 'Mounting /dev/%s...\n' "$root_wedge"

mount "/dev/${root_wedge}" /mnt
cp -p /usr/mdec/boot /mnt/boot
mkdir -p /mnt/kern /mnt/proc

echo Installing sets...

for set in $SETS; do
	if ! [ -f "workdir/sets/${RELEASE}/${ARCH}/${set}${SET_SUFFIX}" ]; then
		ftp -o "workdir/sets/${RELEASE}/${ARCH}/${set}${SET_SUFFIX}" \
		    "${MIRROR}/NetBSD-${RELEASE}/${ARCH}/binary/sets/${set}${SET_SUFFIX}"
	fi
	printf 'Extracting %s...\n' "$set"
	tar -C /mnt -xpf "./workdir/sets/${RELEASE}/${ARCH}/${set}${SET_SUFFIX}"
done

echo Generating RNG seed...

rndctl -S /mnt/var/db/entropy-file

echo Creating fstab...

cat << EOF > /mnt/etc/fstab
/dev/dk0	/		ffs	rw,log,noatime,nodevmtime	1 1
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

echo Installing packages...

for pkg in $PACKAGES;
do
	pkg_add -fI -P /mnt -K /usr/pkg/pkgdb \
		"${PKG_MIRROR}/packages/NetBSD/${ARCH}/${RELEASE}/All/${pkg}"
done

echo Installing Mozilla root certificates...

SSLDIR=/etc/openssl \
	mozilla-rootcerts -d /mnt install >/dev/null

echo Installing BIOS bootloader...

installboot -m amd64 -o timeout=0 \
	"$root_wedge_raw" /mnt/usr/mdec/bootxx_ffsv2
gpt biosboot "$root_wedge"

echo Unmounting...

umount /mnt

echo Converting image to qcow2...

qemu-img convert -f raw -O qcow2 \
	workdir/NetBSD-${RELEASE}-${ARCH}.img \
	workdir/NetBSD-${RELEASE}-${ARCH}.qcow2
