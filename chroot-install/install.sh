#!/bin/sh

BOLD="\033[1;33m"
NORM="\033[0m"
INFO="$BOLD Info:$NORM"
ERROR="$BOLD Error:$NORM"
WARNING="$BOLD Warning:$NORM"
INPUT="$BOLD => $NORM"
if [ -z $1 ]
then
	chrootBaseDir=/DataVolume/debian
else
	chrootBaseDir=$1
fi
debootstrapPkgName=debootstrap_1.0.10lenny1_all.deb
echo -e $INFO This script will guide you through the chroot-based services
echo -e $INFO installation on WD My Book Live \(Duo\) NAS.
echo -e $INFO The goal is to install transmission bittorrent client and
echo -e $INFO MiniDLNA UPnP/DLNA server with no interference to firmware.
echo -e $INFO You will be asked later about services you like to install.
echo -en $INPUT Do you wish to continue [y/n]?
read userAnswer
if [ "$userAnswer" != "y" ]
then
	echo -e $INFO Exiting.
	exit 0
fi

if [ -e /etc/init.d/wedro_chroot.sh ]
then
	/etc/init.d/wedro_chroot.sh stop > /dev/null 2>&1
fi
if [ -d $chrootBaseDir ]
then
	echo -e $WARNING Previous installation detected, will be moved to $chrootBaseDir.old
	if [ -e /etc/init.d/wedro_chroot.sh ]
	then
		/etc/init.d/wedro_chroot.sh stop > /dev/null 2>&1
	fi
	if [ -d $chrootBaseDir.old ]
	then
		if [ -e /etc/init.d/wedro_chroot.sh ]
		then
			/etc/init.d/wedro_chroot.sh stop > /dev/null 2>&1
		fi
		rm -fr $chrootBaseDir.old
	fi
	mkdir $chrootBaseDir.old
	mv -f $chrootBaseDir/* $chrootBaseDir.old
else
	mkdir $chrootBaseDir
fi
echo -e $INFO Deploying a debootstrap package...
wget -q -O /tmp/$debootstrapPkgName http://mbl-common.googlecode.com/svn/chroot-install/$debootstrapPkgName
dpkg -i /tmp/$debootstrapPkgName > /dev/null 2>&1
rm -f /tmp/$debootstrapPkgName
ln -sf /usr/share/debootstrap/scripts/sid /usr/share/debootstrap/scripts/testing
echo -e $INFO Preparing a new Debian Testing chroot file base. Please, be patient,
echo -e $INFO may takes a long time on low speed connection \(about 10 minutes on 30Mbps\)...
debootstrap --variant=minbase --exclude=yaboot,udev,dbus --include=mc,aptitude testing $chrootBaseDir ftp://ftp.debian.org/debian
chroot $chrootBaseDir apt-get update > /dev/null 2>&1
echo -e $INFO A Debian Testing chroot file base installed. Let\'s choose desired services.

echo -en $INPUT Do you wish to install minidlna UPnP/DLNA server [y/n]?
read userAnswer
if [ "$userAnswer" == "y" ]
then
	echo -e $INFO UPnP/DLNA content will be taken from \"MediaServer\" share. Installing...
	chroot $chrootBaseDir apt-get -qqy install minidlna
	chroot $chrootBaseDir /etc/init.d/minidlna stop > /dev/null 2>&1
	chroot $chrootBaseDir /etc/init.d/minissdpd stop > /dev/null 2>&1
	sed -i 's|^media_dir=/var/lib/minidlna|media_dir=/mnt/MediaServer|g' $chrootBaseDir/etc/minidlna.conf
	echo minidlna >> $chrootBaseDir/chroot-services.list
	rm -f $chrootBaseDir/var/lib/minidlna/files.db
	echo -e $INFO Minidlna is installed.
fi

echo -en $INPUT Do you wish to install transmission BitTorrent client [y/n]?
read userAnswer
if [ "$userAnswer" == "y" ]
then
	echo -e $INFO Torrents content will be downloaded to \"Public\" share. Installing...
	chroot $chrootBaseDir apt-get -qqy install transmission-daemon
	chroot $chrootBaseDir /etc/init.d/transmission-daemon stop > /dev/null 2>&1
	sed -i 's|\\/var\\/lib\\/transmission-daemon\\/downloads|/mnt/Public|g' $chrootBaseDir/etc/transmission-daemon/settings.json
	sed -i 's|\"rpc-authentication-required\": 1,|\"rpc-authentication-required\": 0,|g' $chrootBaseDir/etc/transmission-daemon/settings.json
	sed -i 's|\"rpc-whitelist\": "127.0.0.1\"|\"rpc-whitelist-enabled\": false|g' $chrootBaseDir/etc/transmission-daemon/settings.json
	echo transmission-daemon >> $chrootBaseDir/chroot-services.list
	echo -e $INFO Transmission is installed.
fi

echo -e $INFO Now deploying services start script...
wget -q -O $chrootBaseDir/wedro_chroot.sh http://mbl-common.googlecode.com/svn/chroot-install/wedro_chroot.sh
eval sed -i 's,__CHROOT_DIR_PLACEHOLDER__,$chrootBaseDir,g' $chrootBaseDir/wedro_chroot.sh
chmod +x $chrootBaseDir/wedro_chroot.sh
$chrootBaseDir/wedro_chroot.sh install
echo -e $INFO ...finished.
echo -en $INPUT Do you wish to start chroot\'ed services right now [y/n]?
read userAnswer
if [ "$userAnswer" == "y" ]
then
	/etc/init.d/wedro_chroot.sh start
fi

echo -e $INFO Congratulation! Installation finished.
echo -e $INFO Found bug? Please, report to http://code.google.com/p/mbl-common/issues/list
