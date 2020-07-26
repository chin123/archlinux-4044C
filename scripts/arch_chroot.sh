# create the sdcard mountpoint
mkdir /mnt/sdcard

# assuming sdcard is mounted at /dev/block/mmcblk1, check and change accordingly
mount -t ext4 -o rw,exec /dev/block/mmcblk1p2 /mnt/sdcard
export mnt=/mnt/sdcard/arch

# mount linux essentials to our chroot environment
# NOTE: only necessary one time after mounting sd card
mount -o bind /dev $mnt/dev
mount -t devpts devpts $mnt/dev/pts
mount -t proc none $mnt/proc
mount -t sysfs sysfs $mnt/sys

# export environmental variables for our chroot
export PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:$PATH
export TERM=xterm
export HOME=/root
export USER=root

# chroot into arch
chroot $mnt /bin/bash
