#!/usr/bin/env sh
#
# Variables
MAIN_DRIVE="/dev/nvme0n1"
MOUNTPOINT="/mnt/gentoo"
TARBALL_MIRROR="https://mirror.isoc.org.il/pub/gentoo//releases/amd64/autobuilds/current-stage3-amd64-openrc"
STAGE_3="hardened-openrc"

(
	# Boot Partition
	echo g
	echo n
	echo 1
	echo
	echo +256M
	echo t
	echo 1
	# Swap Partition
	echo n
	echo
	echo
	echo +8G
	echo t
	echo 2
	echo 19
	# Root partition
	echo n
	echo
	echo
	echo
) | fdisk $MAIN_DRIVE

mkfs.vfat -F 32 ${MAIN_DRIVE}p1
mkswap ${MAIN_DRIVE}p2
swapon ${MAIN_DRIVE}p2
mkfs.ext4 ${MAIN_DRIVE}p3

mkdir -p $MOUNTPOINT
mount ${MAIN_DRIVE}p3 ${MOUNTPOINT}

wget -P ${MOUNTPOINT} ${TARBALL_MIRROR}/stage3-amd64-${STAGE_3}-*.tar.xz
tar xpvf ${MOUNTPOINT}/stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner

cp make.conf ${MOUNTPOINT}/etc/portage
mkdir -p ${MOUNTPOINT}/etc/portage/repos.conf
cp ${MOUNTPOINT}/usr/share/portage/config/repos.conf ${MOUNTPOINT}/etc/portage/repos.conf/gentoo.conf
cp --dereference /etc/resolv.conf ${MOUNTPOINT}/etc/

mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run
test -L /dev/shm && rm /dev/shm && mkdir /dev/shm
mount --types tmpfs --options nosuid,nodev,noexec shm /dev/shm
chmod 1777 /dev/shm /run/shm

chroot /mnt/gentoo /bin/bash <<"EOT"
source /etc/profile
emerge-webrsync
emerge --sync --quiet

EOT
