#!/bin/sh

chrootBaseDir=/DataVolume/debian
deboostrapPkgName=debootstrap_1.0.10lenny1_all.deb
echo Info: This script will guide you through the chroot-based services
echo Info: installation on WD My Book Live \(Duo\) NAS.
echo Info: The goal is to install transmission bittorrent client and
echo Info: MiniDLNA UPnP/DLNA server with no interference with firmware.
echo
echo -n Info: Do you wish to continue [y/n]?
read userAnswer
if [ "$userAnswer" != "y" ]
then
	echo Info: Exiting.
	exit 0
fi

if [ -d $chrootBaseDir ]
then
	echo Warn: Previous installation detected will be moved to $chrootBaseDir.old
	if [ -d $chrootBaseDir.old ]
	then
		if [ -e /etc/init.d/wedro_chroot.sh ]
		then
			/etc/init.d/wedro_chroot.sh stop
		fi
		rm -fr $chrootBaseDir.old
	fi
	mkdir $chrootBaseDir.old
	mv -f $chrootBaseDir/* $chrootBaseDir.old
else
	mkdir $chrootBaseDir
fi
echo Info: Deploying a debootstrap package...
wget -q -O /tmp/$debootstrapPkgName http://mbl-common.googlecode.com/svn/chroot-install/$debootstraPkgName
dpkg -i /tmp/$deboostrapPkgName
rm -f /tmp/$debootstrapPkgName
ln -sf /usr/share/debootstrap/scripts/sid /usr/share/debootstrap/scripts/testing
echo Info: Preparing a new Debian Testing chroot filebase. Please, be patient.
echo Info: May takes a long time on low speed internet connection...
debootstrap --variant=minbase --exclude=yaboot,udev,dbus --include=mc,aptitude,locales,minidlna,transmission-daemon testing $chrootBaseDir ftp://ftp.debian.org/debian
echo Info: ...finished. Now fixing minidlna and transmission config files:
echo Info: \* torrent content will be downloaded to \"Public\" share,
echo Info: \* UPnP/DLNA content will be taken from \"MediaServer\" share.
sed -i 's|\\/var\\/lib\\/transmission-daemon\\/down3loads|/mnt/Public|g' $chrootBaseDir/etc/transmission-daemon/settings.json
sed -i 's|\"rpc-authentication-required\": 1,|\"rpc-authentication-required\": 0,|g' $chrootBaseDir/etc/transmission-daemon/settings.json
sed -i 's|^media_dir=/var/lib/minidlna|media_dir=/mnt/MediaServer|g' $chrootBaseDir/etc/minidlna.conf
echo Info: ...finished. Now deploying services start script...
wget -q  -O $chrootBaseDir/wedro_chroot.sh http://mbl-common.googlecode.com/svn/chroot-install/wedro_chroot.sh
chmod a+x $chrootBaseDir/wedro_chroot.sh
$chrootBaseDir/wedro_chroot.sh install
echo minidlna > $chrootBaseDir/chroot-services.list
echo transmission-daemon >> $chrootBaseDir/chroot-services.list
echo Info: ...finished.
echo -n Info: Do you wish to start chroot\'ed services right now [y/n]?
read userAnswer
if [ "$userAnswer" == "y" ]
then
	/etc/init.d/wedro_chroot.sh start
fi


echo Info: Found bug? Please, report to http://code.google.com/p/mbl-common/issues/list