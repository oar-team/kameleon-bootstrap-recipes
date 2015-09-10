#!/bin/bash

set -e

die() {
  echo "$@"
  exit 1
}

DISK=/dev/sda

MIRROR="http://mir.archlinux.fr/\$repo/os/\$arch"

HOSTNAME="localhost"
TIMEZONE="UTC"
LOCALE="en_US.UTF-8 UTF-8"
PACKAGES="base mkinitcpio dhcpcd linux systemd-sysvcompat iputils net-tools syslinux openssh vim"

parted -s -- $DISK mklabel msdos mkpart primary 1 -0

mkfs.ext4 ${DISK}1
mount ${DISK}1 /mnt
cat <<EOF >/etc/pacman.d/mirrorlist
Server = $MIRROR
EOF

pacstrap /mnt $PACKAGES
genfstab -p /mnt >> /mnt/etc/fstab

#Setting Hostname
echo $HOSTNAME >> /mnt/etc/hostname

ln -s /usr/share/zoneinfo/$TIMEZONE /mnt/etc/localtime
echo $LOCALE > /mnt/etc/locale.gen
arch-chroot /mnt locale-gen

arch-chroot /mnt mkinitcpio -p linux

#Install Boot Loader
arch-chroot /mnt syslinux-install_update -a -m
arch-chroot /mnt mkdir -p /boot/syslinux
arch-chroot /mnt cp -r /usr/lib/syslinux/bios/*.c32 /boot/syslinux/
arch-chroot /mnt extlinux --install /boot/syslinux
arch-chroot /mnt syslinux-install_update -a -m

cat > /mnt/boot/syslinux/syslinux.cfg <<EOF
default archlinux
timeout 1

label archlinux
kernel ../vmlinuz-linux
initrd ../initramfs-linux.img
append root=UUID=`blkid -s UUID -o value /dev/sda1` rw net.ifnames=0
EOF


#Install enable sshd and default systemd target
arch-chroot /mnt systemctl enable multi-user.target dhcpcd systemd-resolved systemd-networkd sshd
ln -sf /run/systemd/resolve/resolv.conf /mnt/etc/resolv.conf

sync
umount /mnt
sync
systemctl reboot
