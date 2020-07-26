# create the sdcard mountpoint
mkdir /mnt/sdcard

# assuming sdcard is mounted at /dev/block/mmcblk1, check and change accordingly
mount -t ext4 -o rw,exec /dev/block/mmcblk1p2 /mnt/sdcard
export mnt=/mnt/sdcard/arch

# mount linux essentials to our chroot environment
# NOTE: only necessary one time after mounting sd card, can be moved to a
# different startup script
mount -o bind /dev $mnt/dev
mount -t devpts devpts $mnt/dev/pts
mount -t proc none $mnt/proc
mount -t sysfs sysfs $mnt/sys

# export environmental variables for our chroot
export PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:$PATH
export TERM=xterm
export HOME=/root
export USER=root

# execute a few commands in the chroot
chroot $mnt /bin/bash -x <<'EOF'
bash /root/startterm.sh
EOF

# start adbd
sh /data/local/runadb.sh
