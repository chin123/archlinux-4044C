# archlinux-4044C
A guide with accompanying scripts to get a working arch linux chroot on the
alcatel 4044C. This should work on any android/kaiOS device in general, although
you might have to modify the scripts to tailor them to your device.

## Prerequisites
* An alcatel 4044C or similar device.  A micro SD card to store arch linux. I
recommend atleast an 8 GB one to be comfortable, although the rootfs is only
about 500MB, so you could probably make it work with any size larger than
that.
* A computer and usb cable
* Prerequisite reading: (we will be using
information learned from all of these in the guide)
1. [Bananahackers page on EDL mode on kaiOS
devices](https://sites.google.com/view/bananahackers/development/edl)
2. [Bananahackers page on the alcatel
OT-4044](https://sites.google.com/view/bananahackers/devices/alcatel-ot-4044)
3. [Bananahackers page on recovery mode image
modification](https://sites.google.com/view/bananahackers/root/recovery-mode)
* Prerequisite downloads: (clone/download these to keep them handy)
- https://github.com/andybalholm/edl _(required to read and write device partitions)_
- `adb` _(required to have a root shell on the device)_
- http://fl.us.mirror.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz
_(required, the arch linux armv7 rootfs)_
- Android NDK _(required if you want to compile the code yourself. Trust me for
  some reason? If you do, you can download the pre-compiled binaries below)_.
- [https://github.com/ubiquiti/dropbear-android](Dropbear modified for android),
  required to obtain initial shell access outside recovery mode.
- https://github.com/sjitech/android-gcc-toolchain _(optional, makes it easier
  to compile dropbear-android)_
- [Apache Guacamole](https://guacamole.apache.org/) _(required to have a
web-based terminal emulator on the device)_
- https://github.com/chin123/guacamole-client _(optional, my fork of the
guacamole client with support for full screen and a more minimal on screen
keyboard suitable for flip phones)_

## precompiled binaries
Trust me for some reason? Don't want to setup the NDK?
I've uploaded the pre-compiled binaries for `dropbear`, `adbd`, `busybox`, and
`zip`
[here](https://drive.google.com/file/d/1pI6-l8gDL28ZQwmpMaoP_Iv16rKpjAD_/view?usp=sharing).

## Figure out a way to read and write to partitions
If you have root access and adb already working you're done here. However, the
alcatel 4044C comes with adb over USB blocked, and I could never figure out how
to get it to work. However, it is easy to enter download mode on the 4044C: turn
off the phone, and hold both volume buttons. With the usb cable connected to the
computer, insert it to the phone while you are pressing both volume buttons. It
should vibrate and display a warning about entering download mode. At this
point, release the down volume button and wait until the screen turns black. You
have now entered qualcomm EDL (emergency download) mode. [(Credit to luxferre
for discovering this)](https://groups.google.com/forum/#!topic/bananahackers/2bMtsPpdo5I).
You can now use EDL tools to read and write to the device partitions on
the 4044C. [This](https://github.com/andybalholm/edl) specific fork of
edl tools worked on the 4044C, along with the firehose file in
`misc/0x009600e100420024.mbn` however it might not for you. Read the
[bananahackers
page](https://sites.google.com/view/bananahackers/development/edl) about
EDL to learn more about edl and firehose files and how to use it on your
device.  
  
## Backup!
Once you have successfully been able to read partition data from your device,
**backup all of your partitions**. It is invaluable to have a working backup of
all your partitions, especially the recovery, boot, system, userdata, and
custpack partitions. If you ever screw up, you can just flash back to a working
state. Backup regularly and you can have a bit more confidence while hacking.

## Modify recovery image
First, we will want adb shell access in the recovery. This will let us have
direct shell access into the device, so that we don't have to keep flashing
whole system partitions again and again. Follow the guide in [prerequisite
reading (3)](https://sites.google.com/view/bananahackers/root/recovery-mode) and
install adb in your recovery partition. Reboot into recovery and you should have
full root shell access, however only in recovery mode. I was able to use `adb
shell` after selecting the `mount system` option in recovery mode.

## Install dropbear, adbd in the system partition
Once you have adb access in recovery, you will be able to remount the system
partition as read/write to modify it, using a command like:
```
mount -t ext4 -o rw,remount /system
```
Either compile or download the dropbear-android binary. Create the required keys
as described in the dropbear-android README, and place the dropbear binary in
`/system/bin/dropbear`. Also, place the rooted `adbd` binary in
`/system/bin/adbd`. You can obtain `adbd` from the [gerdaOS repo
here](https://gitlab.com/project-pris/system/-/blob/master/src/boot/8110/root/sbin/adbd)
(yeah, you need to download a random binary from a stranger, but what can you
do? I didn't bother trying to compile adbd). It would also be nice to place
busybox at `/system/bin/busybox` if you dont have busybox there already.
Now all that's left to do is to start the dropbear binary at boot. A simple way
to do this is to just add the following command to the end of
`/system/bin/b2g.sh`, just before the last line `exec $COMMAND_PREFIX
"$B2G_DIR/b2g"`, because at this point network access is already established:
```
/system/bin/dropbear -A -N root -C supersecurepassword -r /system/dropbear_rsa_host_key -r /system/dropbear_dss_host_key -p 10022 2> /data/dropbear_err.txt
```
This will let you ssh into your device from your computer as so:
```
ssh root@<ip addr> -p 10022 "sh"
```
with password `supersecurepassword`.
NOTE: you cannot just ssh in and expect a shell, because you will
end up facing this error:
```
PTY allocation request failed on channel 0
shell request failed on channel 0
```
I didn't really do a lot of investigation as to why this happens, because I
literally only use this to start adb. Running `sh` as the command in ssh will
open a simple stdin/stdout interface with the shell. You can now start adb over
tcp as so:
```
setprop service.adb.tcp.port 5555
adbd
```
Wait for a couple of seconds, and you will be able to connect to your phone like
this:
```
adb connect <device ip addr>:5555
adb shell
```
You now have a functional shell! You can use all the regular shell tools, pass
files to and from your device with `adb push`/`adb pull`, and edit files with
`busybox vi`! Now would be a good time to take another system backup.

## Setting up arch linux
Get an SD card and format it with ext4 (or any other file system which supports
symlinks I guess). Extract the arch linux arm rootfs you downloaded earlier into
the sd card, and pop it into your phone. I have a bunch of helper scripts in
`scripts/` which you can use to mount arch linux (specifically `arch_chroot.sh`
to get an arch linux shell, and `arch_start.sh` to just execute a script in the
arch linux chroot). The TLDR is: mount the sd card with rw and exec permissions,
mount the necessary device files, and chroot in. Credit to [this blog
post](https://thomaspolasek.blogspot.com/2012/04/arch-linux-lxde-w-xorg-mouse-keyboard_16.html)
which helped me with this process. Chroot in, and you should have a basic bash
shell in arch. Congratulations, the hard part is now over!

## Getting pacman to work, downloading packages, all that fun stuff
systemd manages `/etc/resolv.conf` by default, but we don't have systemd here,
so just delete `/etc/resolv.conf` which is just a symlink and place this in
instead:
```
nameserver 8.8.8.8
nameserver 4.2.2.2
```
Or any other DNS server you like.  
Start off by doing a quick `pacman -Syy`, and try updating all the packages with
`pacman -Syu` to see if it works.
By default, I was unable to install anything with pacman because it kept
complaining about the GPG keys not being trustable. I fixed this by following
[the pacman package signing troubleshooting tips in the arch
wiki](https://wiki.archlinux.org/index.php/Pacman/Package_signing#Troubleshooting).
You should now be able to install arbitrary packages from the arch repos. If
not, the arch wiki is your friend, and should help you resolve any problem
related to pacman.

## Setting up sshd, vncserver, guacamole
Now that you've got the arch basics setup, this part should be easy. I have a
simple `sshd` config in `misc/sshd_config`, but you can modify it any way you
like. You can also setup a vnc server, i used tigerVNC. Read the guacamole
documentation and setup guacamole on arch, preferably with apache tomcat. I have
an example `user-mapping.xml` file in `misc/user-mapping.xml` which you can base
yours off of. The default apache guacamole client works well, but could be a bit
better for flip phones. I modified the default layout and merged a full-screen
option patch, you can find my fork
[here](https://github.com/chin123/guacamole-client). But you're free to use the
default one too, it works well, but you'll miss out on scrolling because there's
no way to drag or use `Shift+PgUp/Dn` in the kaiOS browser. I haven't gotten
full screen to work yet, because I dont know how to open the guacamole menu in
the KaiOS browser, but it does work on desktops for what its worth.  
You can see the script `scripts/startterm.sh` for an example on how to start
tomcat with guacamole too. I am assuming you have some familiarity with the
command line and starting and stopping services so I'm not going to go into much
detail here, just read the documentation and my scripts and adjust as you
please. (Disclaimer: the quality of my scripts are debatable, created over a few
sleepless nights).

## You're done!
Open up the kaiOS browser, and go to `localhost:8080/guacamole` and you should
be able to login and open a terminal emulator. Have fun!

## Questions?
If anything is unclear, or you find a mistake, feel free to open up a github
issue or PR!

## License
The code and this guide is licensed under CC0.
