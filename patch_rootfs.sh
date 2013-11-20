#!/bin/bash

#Test, ob Zielverzeichnis angegeben wurde
if [ ! -d $1 ] ;
  then 
   echo $1 ist kein Verzeichnis
   exit
fi

ROOTDIR=$1
PATCHFILESDIR=./patchfiles
KERNELNAME=3.8.13-bone28
echo Patche $ROOTDIR

#Neues RTL8192CU Kernelmodul kopieren
TARGETDIR=$ROOTDIR/lib/modules/$KERNELNAME/kernel/drivers/net/wireless/rtlwifi
SOURCEDIR=./rtl8188C_8192C_usb_linux_v4.0.2_9000.20130911
echo Kopiere neues RTL8192CU Kernelmodul nach $TARGETDIR
cp $SOURCEDIR/8192cu.ko $TARGETDIR/
#depmod ausführen um Abhaengigkeiten zu aktualisieren
echo Aktualisiere Abhängigkeiten
depmod --basedir=$ROOTDIR -a $KERNELNAME

#Automatisches Laden des Kernelmoduls einrichten und laden der alten Kernelmodule unterbinden
TARGETDIR=$ROOTDIR/etc/modprobe.d
echo Kopiere rtl8192cu-vendor.com nach $TARGETDIR
cp $PATCHFILESDIR/rtl8192cu-vendor.conf $TARGETDIR/

#WLAN Interface in /etc/network/interfaces hinzufügen
TARGETDIR=$ROOTDIR/etc/network
echo network/interfaces ersetzen
mv -f $TARGETDIR/interfaces $TARGETDIR/interfaces.original
cp -f $PATCHFILESDIR/interfaces $TARGETDIR/interfaces
#cat $PATCHFILESDIR/interfaces.append >> $TARGETDIR/interfaces

#hostapd einrichten
echo hostapd kopieren und einrichten
#hostapd binary nach /opt/hostapd/ kopieren
TARGETDIR=$ROOTDIR/opt/hostapd
mkdir -p $TARGETDIR
cp -f ./wpa_supplicant_hostapd-0.8_rtw_r7475.20130812/hostapd/hostapd $TARGETDIR/hostapd
#link in /usr/sbin einrichten
ln -s /opt/hostapd/hostapd $ROOTDIR/usr/sbin/hostapd
#hostapd conffile nach /etc/hostapd/ kopieren
TARGETDIR=$ROOTDIR/etc/hostapd
mkdir -p $TARGETDIR
cp -f $PATCHFILESDIR/hostapd.conf $TARGETDIR
#init Script nach /etc/init.d kopieren
cp -f $PATCHFILESDIR/hostapd.init $ROOTDIR/etc/init.d/hostapd
#init skripte initialisieren
insserv --path $ROOTDIR/etc/init.d hostapd

#udhcp umkonfigurieren
