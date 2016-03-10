#!/bin/bash

set -e
set -x

fail() {
  echo "$@"
  exit 1
}

export http_proxy=
export https_proxy="$http_proxy"
export ftp_proxy="$http_proxy"
export rsync_proxy="$http_proxy"
export all_proxy="$http_proxy"
export HTTP_PROXY="$http_proxy"
export HTTPS_PROXY="$http_proxy"
export FTP_PROXY="$http_proxy"
export RSYNC_PROXY="$http_proxy"
export ALL_PROXY="$http_proxy"
export no_proxy="localhost,$(echo $http_proxy | tr ":" "\n" | head -n 1),127.0.0.1,localaddress,.localdomain"
export NO_PROXY="$no_proxy"


DISK=/dev/sda
MNT=/mnt
RELEASE=jessie
REPOSITORY="http://http.debian.net/debian/"
HOSTNAME="localhost"
LOCALES="POSIX C en_US fr_FR de_DE"
LANG="en_US.UTF-8"
CURRENT_ARCH="$(uname -m)"
QEMU_ARCH="$CURRENT_ARCH"
DEBIAN_ARCH="$(dpkg --print-architecture)"
DEBIAN_KERNEL_ARCH="$DEBIAN_ARCH"
PACKAGES="less,locales,vim,openssh-server,linux-image-$DEBIAN_KERNEL_ARCH,extlinux"


# Format partition
echo "Partitioning disk..."
parted -s $DISK mklabel msdos
parted -s -a none $DISK mkpart primary 64s 100%
parted -s $DISK set 1 boot on

mkfs.ext4 ${DISK}1

# Mount root parition
mkdir -p $MNT
mount ${DISK}1 $MNT

if [ $CURRENT_ARCH == $QEMU_ARCH ]; then
  debootstrap --arch=$DEBIAN_ARCH --include="$PACKAGES" $RELEASE $MNT $REPOSITORY
  CHROOT_CMD="chroot $MNT"
else
  apt-get install -y qemu-user-static
  debootstrap --foreign --arch=$DEBIAN_ARCH --include="$PACKAGES" $RELEASE $MNT $REPOSITORY
  cp /usr/bin/qemu-$QEMU_ARCH-static $MNT/usr/bin/
  CHROOT_CMD="chroot $MNT /usr/bin/qemu-$QEMU_ARCH-static /bin/bash"
  $CHROOT_CMD /debootstrap/debootstrap --second-stage
fi

#Setting Hostname, network and lang
echo $HOSTNAME >> $MNT/etc/hostname

# Configure network interfaces
cat > $MNT/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

echo LANG=$LANG > $MNT/etc/locale.conf

# Mount chroot
mount -o bind /dev  $MNT/dev
mount -o bind /dev/pts $MNT/dev/pts
mount -t proc /proc  $MNT/proc
mount -t sysfs /sys  $MNT/sys
test -f $MNT/etc/mtab || cat /proc/mounts > $MNT/etc/mtab
cat /etc/resolv.conf > $MNT/etc/resolv.conf

# Configure locales
if ! [ -f $MNT/etc/locale.gen ]; then 
  for l in $LOCALES; do
    sed -i -e "s/^#$l/$l/" $MNT/etc/locale.gen
  done
fi
$CHROOT_CMD /usr/sbin/locale-gen

#Install Boot Loader
mkdir -p $MNT/boot/extlinux
extlinux --install $MNT/boot/extlinux

MBR_PATH=
PATHS=("/usr/share/syslinux/mbr.bin"
       "/usr/lib/bios/syslinux/mbr.bin"
       "/usr/lib/syslinux/bios/mbr.bin"
       "/usr/lib/extlinux/mbr.bin"
       "/usr/lib/syslinux/mbr.bin"
       "/usr/lib/syslinux/mbr/mbr.bin"
       "/usr/lib/EXTLINUX/mbr.bin")
for element in "${PATHS[@]}"
do
  if [ -f "$element" ]; then
    MBR_PATH="$element"
    break
  fi
done

if [ "$MBR_PATH" == "" ]; then
    fail "unable to locate the extlinux mbr"
else
    dd if="$MBR_PATH" of="$DISK" bs=440  2>&1
fi

cat > $MNT/boot/extlinux/extlinux.conf <<EOF
default debian
timeout 1

label debian
kernel ../`basename $MNT/boot/vmlinuz*`
initrd ../`basename $MNT/boot/init*`
append root=UUID=`blkid -s UUID -o value /dev/sda1` rw net.ifnames=0
EOF

sync
umount $MNT/sys
umount $MNT/proc
umount $MNT/dev/pts
umount $MNT/dev
umount $MNT
sync

# force reboot
reboot
