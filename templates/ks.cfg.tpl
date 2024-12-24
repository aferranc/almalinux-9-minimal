#version=RHEL9

# Use graphical install
text

# Use CDROM installation media
# !!!! Removed option "cdrom" for install with USB device !!!!
#cdrom

# Keyboard layouts
keyboard --vckeymap=es --xlayouts='es'

# System language
lang en_US.UTF-8

# Disable SELinux
selinux --disabled

# Root password
rootpw --iscrypted $6$3HvG8ueO.4VGs72M$rtJJd34ekfkmHFRWTI39p4fGvKNyFWxZFO9DxgoCQWLbzVPWkzeef6d3Qx5.oPlGkWgv./6SAw9V8y91P3IZU1

# Run the Setup Agent on first boot
firstboot --enable

# Do not configure the X Window System
skipx

# System services
services --enabled="chronyd"

# System timezone
timezone Etc/UTC --utc

#########################################################################
# Pre Installation: [KEYBOARD] Disable                                  #
#########################################################################
#%pre
#  echo "ACTION==\"add\", SUBSYSTEM==\"input\", SUBSYSTEMS==\"usb\", ATTRS{authorized}==\"1\", ENV{PARID}=\"\$id\", RUN+=\"/bin/sh -c 'echo 0 >/sys/bus/usb/devices/\$env{PARID}/authorized'\"" > /etc/udev/rules.d/99-disable-usb-input.rules
#  udevadm control --reload-rules && udevadm trigger --action=add
# %end

#########################################################################
# Pre Installation: Install dialog util                                 #
#########################################################################
%pre
  pushd /
  tar -zxvf run/install/repo/utils_LiveOS/dialog-1.3-32.20210117.el9/dialog-1.3-32.20210117.el9.tgz
%end

#########################################################################
# Pre Installation: Install lssci util                                  #
#########################################################################
%pre
  pushd /
  tar -zxvf run/install/repo/utils_LiveOS/lsscsi-1.3-32.20210117.el9/lsscsi-1.3-32.20210117.el9.tgz
%end

#########################################################################
# Pre Installation: Detect USBs and HDDs                                #
#########################################################################
%pre
    hds=""
    usbs=""
    DIR="/sys/block"
    for DEV in $(ls $DIR | egrep -i "sd|hd|cciss")
    do
        if [ $(readlink -f $DIR/$DEV/device | grep -c usb) = 0 ]; then
            hds="$hds ${DEV}"
        else
            usbs="$usbs ${DEV}"
        fi
    done

    set $hds
    numhd=$(echo $#)
    drive1=$(echo $hds | cut -d' ' -f1 | sed 's/\!/\//g')
    drive2=$(echo $hds | cut -d' ' -f2 | sed 's/\!/\//g')

    set $usbs
    numusb=$(echo $#)
    usb_drive1=$(echo $usbs | cut -d' ' -f1 | sed 's/\!/\//g')
    usb_drive2=$(echo $usbs | cut -d' ' -f2 | sed 's/\!/\//g')

    echo "numhd=${numhd}"             > /tmp/params.ks
    echo "drive1=${drive1}"           >> /tmp/params.ks
    echo "drive2=${drive2}"           >> /tmp/params.ks
    echo "numusb=${numusb}"           >> /tmp/params.ks
    echo "usb_drive1=${usb_drive1}"   >> /tmp/params.ks
    echo "usb_drive2=${usb_drive2}"   >> /tmp/params.ks

    DIR="/sys/block"

    # minimum size of hard drive needed specified in GIGABYTES
    MINSIZE=8
    ROOTDRIVE=""
    for DEV in ${drive1}; do
        if [ -d $DIR/$DEV ]; then
            REMOVABLE=`cat $DIR/$DEV/removable`
            if (( $REMOVABLE == 0 )); then
                SIZE=$(cat $DIR/$DEV/size)
                GB=$(($SIZE/2**21))
                if [ $GB -ge $MINSIZE ]; then
                    echo "$(($SIZE/2**21))"
                    if [ -z $ROOTDRIVE ]; then
                        ROOTDRIVE=$DEV
                    fi
                fi
            fi
        fi
    done

    echo "ROOTDRIVE=${ROOTDRIVE}"       > /tmp/hd.ks
    echo "GB_HD_SIZE=${GB}"             >> /tmp/hd.ks
    echo "MB_HD_SIZE=$((${GB}*1024))"   >> /tmp/hd.ks
%end

#########################################################################
# Pre Installation: [DIALOG] Show information if detect more than 1 USB #
#########################################################################
%pre
    . /tmp/params.ks

    INFO_LOG_FILE=/tmp/info_usb_devices.log

    if [ ${numusb} -gt 1 ]; then
      echo " " > ${INFO_LOG_FILE}
      echo " " >> ${INFO_LOG_FILE}
      echo "The server has connected ${numusb} USB Pendrives" >> ${INFO_LOG_FILE}
      echo " " >> ${INFO_LOG_FILE}
      echo " " >> ${INFO_LOG_FILE}
      echo "      !!!!!!!!!!!! Only connect one USB Pendrive, for a correct installation !!!!!!!!!!!!" >> ${INFO_LOG_FILE}
      echo " " >> ${INFO_LOG_FILE}
      echo " " >> ${INFO_LOG_FILE}

      clear
      dialog --title "WARNING" --textbox /tmp/info_hw.log 40 100
%end

#########################################################################
# Pre Installation: [DIALOG] Show hardware/software information         #
#########################################################################
%pre
    # Automatically switch to 6th console and redirect all input/output
    exec < /dev/tty6 > /dev/tty6 2> /dev/tty6
    chvt 6

    . /tmp/params.ks
    . /tmp/hd.ks

    INFO_LOG_FILE=/tmp/info_hw.log

    clear
    dialog --title "Getting Information" --infobox "Waiting...." 8 40

    sleep 5

    # get hardware info
    MANUFACTURER=$(dmidecode -t 1 | grep "Manufacturer" | cut -d ':' -f2 | sed 's/^[ \t]*//g')
    PODUCT_NAME=$(dmidecode -t 1 | grep "Product Name" | cut -d ':' -f2 | sed 's/^[ \t]*//g')
    SERIAL_NUMBER=$(dmidecode -t 1 | grep "Serial Number" | cut -d ':' -f2 | sed 's/^[ \t]*//g')
    BASE_BOARD_NAME=$(dmidecode -t 2 | grep "Product Name" | cut -d ':' -f2 | sed 's/^[ \t]*//g')
    CPU_MODEL_NAME=$(dmidecode -t 4 | grep "Version" | cut -d ':' -f2 | sed 's/^[ \t]*//g' | sort -u)

    # detection if it is a virtual machine
    if systemd-detect-virt --chroot; then
        VIRTUAL_MACHINE=yes
    else
        VIRTUAL_MACHINE=no
    fi

    echo "VIRTUAL_MACHINE=${VIRTUAL_MACHINE}" >> /tmp/params.ks

    DISTRO=$(cat /run/install/repo/isolinux/isolinux.cfg | grep "menu title" | cut -d ' ' -f3-)
    RELEASE=$(cat /run/install/repo/isolinux/isolinux.cfg | grep "menu label" | cut -d ' ' -f6-)

    echo "Software Information" > ${INFO_LOG_FILE}
    echo "--------------------" >> ${INFO_LOG_FILE}
    if [ -z "${DISTRO}" ]; then
    	echo "Platform:        Not found" >> ${INFO_LOG_FILE}
    else
    	echo "Platform:        ${DISTRO}" >> ${INFO_LOG_FILE}
    fi

    if [ -z "${RELEASE}" ]; then
    	echo "Release:         Not found" >> ${INFO_LOG_FILE}
    else
    	echo "Release:         ${RELEASE}" >> ${INFO_LOG_FILE}
    fi

    echo " " >> ${INFO_LOG_FILE}
    echo "Hardware Information" >> ${INFO_LOG_FILE}
    echo "--------------------" >> ${INFO_LOG_FILE}
    echo "Manufacturer:    ${MANUFACTURER}" >> ${INFO_LOG_FILE}
    echo "Product Name:    ${PRODUCT_NAME}" >> ${INFO_LOG_FILE}

    if [ "x${VIRTUAL_MACHINE}" == "xno" ]; then
    	echo "Serial Number:   ${SERIAL_NUMBER}" >> ${INFO_LOG_FILE}
    	echo "Base Board Name: ${BASE_BOARD_NAME}" >> ${INFO_LOG_FILE}
    	echo "CPU Model Name:  ${CPU_MODEL_NAME}" >> ${INFO_LOG_FILE}
    fi
    echo " " >> ${INFO_LOG_FILE}

    echo "List SCSI devices" >> ${INFO_LOG_FILE}
    echo "-----------------" >> ${INFO_LOG_FILE}
    for device in $(lsscsi | awk '{print $1}'); do
        echo $(lsscsi ${device}) driver $(lsscsi -Ht ${device} | awk '{print $2}') >> ${INFO_LOG_FILE}
    done

    echo " " >> ${INFO_LOG_FILE}

    echo "Device to install" >> ${INFO_LOG_FILE}
    echo "-----------------" >> ${INFO_LOG_FILE}
    echo "Total HD found=${numhd}" >> ${INFO_LOG_FILE}
    if [ ${numhd} -eq 0 ]; then
        echo "Drive: N/A" >> ${INFO_LOG_FILE}
        echo "Can not be installed the software" >> ${INFO_LOG_FILE}
    elif [ ${numhd} -eq 1 ]; then
        echo "HD_1=${drive1}" >> ${INFO_LOG_FILE}
        fdisk -l | grep Disk | grep ${drive1} >> ${INFO_LOG_FILE}
        echo "The software will be installed on /dev/${drive1}" >> ${INFO_LOG_FILE}
    elif [ ${numhd} -eq 2 ]; then
        echo "HD_1=${drive1}" >> ${INFO_LOG_FILE}
        fdisk -l | grep Disk | grep ${drive1} >> ${INFO_LOG_FILE}
        echo "HD_2=${drive2}" >> ${INFO_LOG_FILE}
        fdisk -l | grep Disk | grep ${drive2} >> ${INFO_LOG_FILE}
        echo "The software will be installed on /dev/${drive1} and /dev/${drive2} [RAID SW]" >> ${INFO_LOG_FILE}
    fi

    echo " " >> ${INFO_LOG_FILE}

    echo "List ethernet devices" >> ${INFO_LOG_FILE}
    echo "---------------------" >> ${INFO_LOG_FILE}
    for net_device in $(ifconfig -a | grep ^eth | awk '{print $1}'); do
        echo $(ifconfig -a | grep ${net_device} | awk '{print $1,$5}') $(ethtool -i ${net_device} | grep driver) >> ${INFO_LOG_FILE}
    done

    sleep 5

    clear
    dialog --title "Information" --textbox /tmp/info_hw.log 40 100

    # Then switch back to Anaconda on the first console
    chvt 1
    exec < /dev/tty1 > /dev/tty1 2> /dev/tty1
%end

#########################################################################
# Pre Installation: [DIALOG] Help Information                           #
#########################################################################
%pre
    # Automatically switch to 6th console and redirect all input/output
    exec < /dev/tty6 > /dev/tty6 2> /dev/tty6
    chvt 6

    # File with "Help Information"
    INFO_HELP=/tmp/info_help.log
    echo "" >> ${INFO_HELP}
    echo "In case of installation error, follow next recommendations:"  >> ${INFO_HELP}
    echo "" >> ${INFO_HELP}
    echo "1. If you want to RAID software, remember to disable your RAID controller on BIOS." >> ${INFO_HELP}
    echo "2. If the HD isn't detected in -Device to Install-, disable your RAID controller on BIOS." >> ${INFO_HELP}
    echo "3. If the installer detect 2 HDDs, the software is installed with RAID software." >> ${INFO_HELP}
    echo "   (see -Device to Install-)" >> ${INFO_HELP}
    echo "4. If more than a pendrive connected and/or more than 2 HDDs installed on the server," >> ${INFO_HELP}
    echo "   the installer may be fail." >> ${INFO_HELP}
    echo "   * Only connect 2 HDDs and the pendrive installer." >> ${INFO_HELP}
    echo "5. If you configure the sshd service, check the correct ethernet port" >> ${INFO_HELP}
    echo "" >> ${INFO_HELP}


    ##### HARDWARE INFORMATION #####
    clear
    dialog --title "Help Information" --textbox ${INFO_HELP} 40 100

    # Then switch back to Anaconda on the first console
    chvt 1
    exec < /dev/tty1 > /dev/tty1 2> /dev/tty1
%end

#########################################################################
# Pre Installation: [DIALOG] Start sshd service                           #
#########################################################################
%pre
    # Automatically switch to 6th console and redirect all input/output
    exec < /dev/tty6 > /dev/tty6 2> /dev/tty6
    chvt 6

    clear
    dialog --title "WARNING" --defaultno --yesno "Would you like to configure SSHD service to enable installation process debug?" 8 50 3>&1 1>&2 2>&3
    if [ $? -eq 0 ]; then
      IP=$(dialog  --title "Configuring sshd service" --inputbox "IP Address" 10 60 3>&1 1>&2 2>&3)
      NETMASK=$(dialog --title "Configuring sshd service" --inputbox "Network Mask" 10 60 "255.255.254.0" 3>&1 1>&2 2>&3)
      GATEWAY=$(dialog --title "Configuring sshd service" --inputbox "Gateway" 10 60  3>&1 1>&2 2>&3)
      echo "IP=$IP" > /tmp/sshd_network_config.ks
      echo "NETMASK=$NETMASK" >> /tmp/sshd_network_config.ks
      echo "GATEWAY=$GATEWAY" >> /tmp/sshd_network_config.ks

      ifconfig eth0 $IP
      #Se añade ruta para forzar salida por eth0 en caso que estuviera configurada la red de juego en eth1. En tiempo de instalación esto no debería pasar
      route add -net 10.16.84.0/23 gw $GATEWAY eth0
      #Se añade ruta para forzar salida por eth0 en caso que estuviera configurada la red de juego en eth1. En tiempo de instalación esto no debería pasar
      route add -net 10.32.101.0/24 gw $GATEWAY eth0

      /usr/sbin/sshd -f /etc/ssh/sshd_config.anaconda

      # Set password
      echo root:SvgBT.2QySUQ2 | chpasswd -e
    fi

    # Then switch back to Anaconda on the first console
    chvt 1
    exec < /dev/tty1 > /dev/tty1 2> /dev/tty1
%end

#########################################################################
# Pre Installation: [DIALOG] Do you want install?                       #
#########################################################################
%pre
    # Automatically switch to 6th console and redirect all input/output
    exec < /dev/tty6 > /dev/tty6 2> /dev/tty6
    chvt 6

    clear
    dialog --title "WARNING" --defaultno --yesno "Do you want install the software?\n\n[Yes] will erase the hard drive\n[No] reboot " 10 50 3>&1 1>&2 2>&3
    if [ $? -ne 0 ]; then
        reboot
    fi

    # Then switch back to Anaconda on the first console
    chvt 1
    exec < /dev/tty1 > /dev/tty1 2> /dev/tty1
%end

#########################################################################
# Pre Installation: Erase old configuration HDDs                        #
#########################################################################
%pre

  . /tmp/params.ks

  ### Clearpart not working fine on EL9 (INI) ###

  # wipe el(Entreprise Linux) partitions if exists
  vgchange -a n el
  vgremove -f el
  dmsetup remove el

  for pv in $( pvs | awk {'print $1'} )
  do
    pvremove -f $pv
  done

  # Clear software raid devices if any
  raid_devices=$(mktemp /tmp/mdstat.XXXXXXXXX)
  cat /proc/mdstat | grep ^md | cut -d : -f 1 > $raid_devices

  if [ -s $raid_devices ];then
    for raid in $(cat $raid_devices);do
      wipefs -f -a /dev/$raid
      mdadm --stop -f /dev/$raid
      if [ $? != "0" ];then
        udevadm settle
        dmsetup remove_all
        mdadm --stop -f /dev/$raid
     fi
    done
  else
    echo "All raid devices are cleared"
  fi
  rm -vf $raid_devices

  # Wipe any partitions if found
  available_disks=$(mktemp /tmp/disks.XXXXXXXXX)
  ls -r /dev/${drive1}* /dev/${drive2}* > $available_disks

  for disk in `cat $available_disks`;do
    wipefs -f -a $disk
    done
    rm -vf $available_disks

    sync

  ### Clearpart not working fine on EL9 (END) ###

  # Erase old configuration
  # Delete info partition table
  dd if=/dev/zero of=/dev/${drive1} bs=512 count=1
  # Detete info raid software
  dd if=/dev/zero of=/dev/${drive1} bs=512 seek=$(( $(blockdev --getsz /dev/${drive1}) - 1024 )) count=1024

  if [ $numhd == "2" ] ; then
    # Erase old configuration
    # Delete info partition table
    dd if=/dev/zero of=/dev/${drive2} bs=512 count=1
    # Delete info raid software
    dd if=/dev/zero of=/dev/${drive2} bs=512 seek=$(( $(blockdev --getsz /dev/${drive2}) - 1024 )) count=1024
  fi
%end

#########################################################################
# Pre Installation: [MDADM RESYNC]                                      #
#########################################################################
%pre
    echo 100 > /proc/sys/dev/raid/speed_limit_min
    echo 200 > /proc/sys/dev/raid/speed_limit_max
%end

#########################################################################
# Pre Installation: [CONFIG HD]                                         #
#########################################################################
%pre
    . /tmp/params.ks
    . /tmp/hd.ks

    if [ -f /run/install/repo/disk-layout ]; then
      # Convert DOS to Unix
      tr -d '\r' < /run/install/repo/disk-layout > /tmp/disk-layout.ks
    else
      echo "**** ERROR!!!! No existe el fichero /tmp/disk-layout.ks ****"
      exit 1
    fi

    # Parse variables
    while IFS='= ' read var val; do
      if [[ $var == \[*] ]]; then
        section=$var
      elif [[ $val ]]; then
        section=$(echo $section | sed 's/\[/_/' | sed 's/\]//')
        eval  "$var$section=$val"
      fi
    done < /tmp/disk-layout.ks

    TOTAL_SIZE_PARTITIONS=0

    for NUM in $(eval echo {1..${TOTAL_PARTITIONS}}); do
      PARTITION=$(echo $(eval echo '$'PARTITION${NUM}_NAME_PARTITIONS))
      SIZE=$(echo $(eval echo '$'PARTITION${NUM}_SIZE_PARTITIONS))

      if [ -z ${PARTITION} ] || [ -z ${SIZE} ]; then
        # Automatically switch to 6th console and redirect all input/output
        exec < /dev/tty6 > /dev/tty6 2> /dev/tty6
        chvt 6

        clear
        dialog --msgbox "The config file is not correct.\nReview partitions" 10 50 3>&1 1>&2 2>&3
        reboot

        # Then switch back to Anaconda on the first console
        chvt 1
        exec < /dev/tty1 > /dev/tty1 2> /dev/tty1
      fi

      TOTAL_SIZE_PARTITIONS=$(expr ${TOTAL_SIZE_PARTITIONS} + ${SIZE})

      case $PARTITION in
        /boot)
          SIZE_BOOT_PARTITION=${SIZE}
          ;;
        /boot/efi)
          SIZE_BOOT_EFI_PARTITION=${SIZE}
          ;;
        /)
          SIZE_ROOT_PARTITION=${SIZE}
          ;;
        /home)
          SIZE_HOME_PARTITION=${SIZE}
          ;;
        /tmp)
          SIZE_TMP_PARTITION=${SIZE}
          ;;
        /var)
          SIZE_VAR_PARTITION=${SIZE}
          ;;
        /var/log)
          SIZE_VAR_LOG_PARTITION=${SIZE}
          ;;
        /var/tmp)
          SIZE_VAR_TMP_PARTITION=${SIZE}
          ;;
        /opt)
          SIZE_OPT_PARTITION=${SIZE}
          ;;
        swap)
          SIZE_SWAP_PARTITION=${SIZE}
          ;;
        *)
          # Preparar para definir particiones dinamicamente
          ;;
      esac
    done

    # Verificar que el HD tiene el tamaño suficiente
    if [ ${TOTAL_SIZE_PARTITIONS} -gt ${MB_HD_SIZE} ]; then
      # Automatically switch to 6th console and redirect all input/output
      exec < /dev/tty6 > /dev/tty6 2> /dev/tty6
      chvt 6

      clear
      dialog --msgbox "The hard disk size is not enough " 10 50 3>&1 1>&2 2>&3
      reboot

      # Then switch back to Anaconda on the first console
      chvt 1
      exec < /dev/tty1 > /dev/tty1 2> /dev/tty1
    fi

    if [ $numhd == "2" ] ; then
      echo "ignoredisk --only-use=${drive1},${drive2}" > /tmp/disk-partitions.ks
      echo "# System bootloader configuration" >> /tmp/disk-partitions.ks
      echo "bootloader --location=mbr --driveorder=${drive1},${drive2} --timeout=5" >> /tmp/disk-partitions.ks
      echo "clearpart --all --initlabel" >> /tmp/disk-partitions.ks
      echo "zerombr" >> /tmp/disk-partitions.ks
      # /boot
      echo "part raid.11 --fstype=\"mdmember\" --ondisk=${drive1} --size=${SIZE_BOOT_PARTITION}" --asprimary >> /tmp/disk-partitions.ks
      echo "part raid.21 --fstype=\"mdmember\" --ondisk=${drive2} --size=${SIZE_BOOT_PARTITION}" --asprimary >> /tmp/disk-partitions.ks
      # /boot/efi
      echo "part raid.12 --fstype=\"mdmember\" --ondisk=${drive1} --size=${SIZE_BOOT_EFI_PARTITION}" --asprimary >> /tmp/disk-partitions.ks
      echo "part raid.22 --fstype=\"mdmember\" --ondisk=${drive2} --size=${SIZE_BOOT_EFI_PARTITION}" --asprimary >> /tmp/disk-partitions.ks
      # /
      echo "part raid.13 --fstype=\"mdmember\" --ondisk=${drive1} --size=${SIZE_ROOT_PARTITION}" --asprimary >> /tmp/disk-partitions.ks
      echo "part raid.23 --fstype=\"mdmember\" --ondisk=${drive2} --size=${SIZE_ROOT_PARTITION}" --asprimary >> /tmp/disk-partitions.ks
      # /home
      echo "part raid.14 --fstype=\"mdmember\" --ondisk=${drive1} --size=${SIZE_HOME_PARTITION}" >> /tmp/disk-partitions.ks
      echo "part raid.24 --fstype=\"mdmember\" --ondisk=${drive2} --size=${SIZE_HOME_PARTITION}" >> /tmp/disk-partitions.ks
      # /tmp
      echo "part raid.15 --fstype=\"mdmember\" --ondisk=${drive1} --size=${SIZE_TMP_PARTITION}" >> /tmp/disk-partitions.ks
      echo "part raid.25 --fstype=\"mdmember\" --ondisk=${drive2} --size=${SIZE_TMP_PARTITION}" >> /tmp/disk-partitions.ks
      # /var
      echo "part raid.16 --fstype=\"mdmember\" --ondisk=${drive1} --size=${SIZE_VAR_PARTITION}" --grow >> /tmp/disk-partitions.ks
      echo "part raid.26 --fstype=\"mdmember\" --ondisk=${drive2} --size=${SIZE_VAR_PARTITION}" --grow >> /tmp/disk-partitions.ks
      # /var/log
      echo "part raid.17 --fstype=\"mdmember\" --ondisk=${drive1} --size=${SIZE_VAR_LOG_PARTITION}" >> /tmp/disk-partitions.ks
      echo "part raid.27 --fstype=\"mdmember\" --ondisk=${drive2} --size=${SIZE_VAR_LOG_PARTITION}" >> /tmp/disk-partitions.ks
      # /var/tmp
      echo "part raid.18 --fstype=\"mdmember\" --ondisk=${drive1} --size=${SIZE_VAR_TMP_PARTITION}" >> /tmp/disk-partitions.ks
      echo "part raid.28 --fstype=\"mdmember\" --ondisk=${drive2} --size=${SIZE_VAR_TMP_PARTITION}" >> /tmp/disk-partitions.ks
      # /opt
      echo "part raid.19 --fstype=\"mdmember\" --ondisk=${drive1} --size=${SIZE_OPT_PARTITION}" >> /tmp/disk-partitions.ks
      echo "part raid.29 --fstype=\"mdmember\" --ondisk=${drive2} --size=${SIZE_OPT_PARTITION}" >> /tmp/disk-partitions.ks
      # swap
      echo "part raid.110 --fstype=\"mdmember\" --ondisk=${drive1} --size=${SIZE_SWAP_PARTITION}" >> /tmp/disk-partitions.ks
      echo "part raid.210 --fstype=\"mdmember\" --ondisk=${drive2} --size=${SIZE_SWAP_PARTITION}" >> /tmp/disk-partitions.ks

      echo "raid /boot --device=boot --fstype=\"xfs\" --level=RAID1 --fsoptions=\"noatime,nodiratime\" --label=boot raid.11 raid.21" >> /tmp/disk-partitions.ks
      echo "raid /boot/efi --device=boot_efi --fstype=\"efi\" --level=RAID1 --fsoptions=\"umask=0077,shortname=winnt,noatime,nodiratime\" --label=gpt raid.12 raid.22" >> /tmp/disk-partitions.ks
      echo "raid / --device=root --fstype=\"xfs\" --level=RAID1 --fsoptions=\"noatime,nodiratime\" --label=root raid.13 raid.23" >> /tmp/disk-partitions.ks
      echo "raid /home --device=home --fstype=\"xfs\" --level=RAID1 --fsoptions=\"noatime,nodiratime,nodev,nosuid\" --label=home raid.14 raid.24" >> /tmp/disk-partitions.ks
      echo "raid /tmp --device=tmp --fstype=\"xfs\" --level=RAID1 --fsoptions=\"noatime,nodiratime,nodev,nosuid,noexec\" --label=tmp raid.15 raid.25" >> /tmp/disk-partitions.ks
      echo "raid /var --device=var --fstype=\"xfs\" --level=RAID1 --fsoptions=\"noatime,nodiratime,nodev,nosuid,noexec\" --label=var raid.16 raid.26" >> /tmp/disk-partitions.ks
      echo "raid /var/log --device=log --fstype=\"xfs\" --level=RAID1 --fsoptions=\"noatime,nodiratime,nodev,nosuid,noexec\" --label=log raid.17 raid.27" >> /tmp/disk-partitions.ks
      echo "raid /var/tmp --device=var_tmp --fstype=\"xfs\" --level=RAID1 --fsoptions=\"noatime,nodiratime,nodev,nosuid,noexec\" --label=vartmp raid.18 raid.28" >> /tmp/disk-partitions.ks
      echo "raid /opt --device=opt --fstype=\"xfs\" --level=RAID1 --fsoptions=\"noatime,nodiratime\" --label=opt raid.19 raid.29" >> /tmp/disk-partitions.ks
      echo "raid swap --device=swap --fstype=\"swap\" --level=RAID1 raid.110 raid.210" >> /tmp/disk-partitions.ks
    else
      echo "ignoredisk --only-use=${drive1}" > /tmp/disk-partitions.ks
      echo "# System bootloader configuration" >> /tmp/disk-partitions.ks
      echo "bootloader --location=mbr --driveorder=${drive1} --timeout=5" >> /tmp/disk-partitions.ks
      echo "clearpart --all --initlabel" >> /tmp/disk-partitions.ks
      echo "zerombr" >> /tmp/disk-partitions.ks
      # /boot
      echo "part /boot --fstype=\"xfs\" --ondisk=${drive1} --size=${SIZE_BOOT_PARTITION} --fsoptions=\"noatime,nodiratime\"" --asprimary >> /tmp/disk-partitions.ks
      # /boot/efi
      echo "part /boot/efi --fstype=\"efi\" --ondisk=${drive1} --size=${SIZE_BOOT_EFI_PARTITION} --fsoptions=\"umask=0077,shortname=winnt,noatime,nodiratime\"" --asprimary >> /tmp/disk-partitions.ks
      # /
      echo "part / --fstype=\"xfs\" --ondisk=${drive1} --size=${SIZE_ROOT_PARTITION} --fsoptions=\"noatime,nodiratime\"" --asprimary >> /tmp/disk-partitions.ks
      # /home
      echo "part /home --fstype=\"xfs\" --ondisk=${drive1} --size=${SIZE_HOME_PARTITION} --fsoptions=\"noatime,nodiratime,nodev,nosuid\"" >> /tmp/disk-partitions.ks
      # /tmp
      echo "part /tmp --fstype=\"xfs\" --ondisk=${drive1} --size=${SIZE_TMP_PARTITION} --fsoptions=\"noatime,nodiratime,nodev,nosuid,noexec\"" >> /tmp/disk-partitions.ks
      # /var
      echo "part /var --fstype=\"xfs\" --ondisk=${drive1} --size=${SIZE_VAR_PARTITION} --grow --fsoptions=\"noatime,nodiratime,nodev,nosuid,noexec\"" >> /tmp/disk-partitions.ks
      # /var/log
      echo "part /var/log --fstype=\"xfs\" --ondisk=${drive1} --size=${SIZE_VAR_LOG_PARTITION} --fsoptions=\"noatime,nodiratime,nodev,nosuid,noexec\"" >> /tmp/disk-partitions.ks
      # /var/tmp
      echo "part /var/tmp --fstype=\"xfs\" --ondisk=${drive1} --size=${SIZE_VAR_TMP_PARTITION} --fsoptions=\"noatime,nodiratime,nodev,nosuid,noexec\"" >> /tmp/disk-partitions.ks
      # /opt
      echo "part /opt --fstype=\"xfs\" --ondisk=${drive1} --size=${SIZE_OPT_PARTITION} --fsoptions=\"noatime,nodiratime\"" >> /tmp/disk-partitions.ks
      # swap
      echo "part swap --fstype=\"swap\" --ondisk=${drive1} --size=${SIZE_SWAP_PARTITION}" >> /tmp/disk-partitions.ks
    fi
%end

#########################################################################
# Post Installation: Execute after installation                         #
#########################################################################
%post
  # Se mueve este fichero, para luego ser recuperado en la configuración de la instalación en el script /opt/sysadm/bin/configure_host.sh
  # Ahora mismo en el %post Copy extra files, se copia el fichero system.conf con la opcion ShowStatus=no,
  # para que no muestre trazas el systemd durante la introduccion de datos en el dialog de configuracion
  mv /etc/systemd/system.conf /etc/systemd/system.conf.orig
%end

#########################################################################
# Post Installation: Configure kernel default parameters                #
#########################################################################
%post
  source /etc/os-release
  grubby --update-kernel=ALL --args="selinux=0 crashkernel=auto biosdevname=0 net.ifnames=0 panic=10 fsck.mode=auto ipv6.disable=1 consoleblank=0 8250.nr_uarts=5"
  grubby --update-kernel=ALL --args="audit=0 acpi=0 zswap.enabled=1 zswap.max_pool_percent=40 rd.retry=30 rd.shutdown.timeout.umount=15"
  grubby --update-kernel=ALL --remove-args="rhgb quiet"
  sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/g' /etc/default/grub
  grub2-editenv create
  grub2-mkconfig -o /boot/grub2/grub.cfg
  grub2-mkconfig -o /boot/efi/EFI/${ID}/grub.cfg
%end

#########################################################################
# Post Installation: [EXTRA FILES] Copy extra files                     #
#########################################################################
%post --nochroot
  cp -r /run/install/repo/extra_files/* /mnt/sysimage
  sync
%end

#########################################################################
# Post Installation: Copying Forward Systems RPMs                       #
#########################################################################
%post --nochroot
  [ ! -d /mnt/sysimage/var/vlt/rpm/install ] && mkdir -p /mnt/sysimage/var/vlt/rpm/install
  cp -r /run/install/repo/svlo_rpm/* /mnt/sysimage/var/vlt/rpm/install
  sync
%end

#########################################################################
# Post Installation: Creating Forward Systems Base Directories          #
#########################################################################
%post
  # db
  mkdir -p /var/db_backups

  # cfg dirs
  mkdir -p /etc/sysconfig/vlt

  # system dirs
  mkdir -p /opt/vlt/{bin,cfg,lib,inc,sbin}

  # log dirs
  mkdir -p /var/vlt/{krn,knc,cly,hwl,cfm,gpt,usm,scm,acm,gdm,jpm,cfc,tmp}
  mkdir -p /var/log/vlt/old

  # subdirs
  mkdir -p /var/vlt/kns/{kld,knc-xml}
  mkdir -p /var/vlt/{knc,cfm,cfc}/kld
  mkdir -p /var/vlt/scm/{rdm/tosend,rdm/toexec,rdm/log,incidences/mail}
  mkdir -p /var/vlt/{sysconfig,rpm/install,rpm/installed,run,status,tmp}
  mkdir -p /var/vlt/gdm/firm
  mkdir -p /var/vlt/bkp
  mkdir -p /var/vlt/log
  mkdir -p /var/vlt/wui
  mkdir -p /var/vlt/rsync

  # dir permissions
  chown -R system: /opt/vlt /var/vlt /var/vlt/wui /var/log/vlt
  chown -R system:postgres /var/vlt/bkp
  chown -R system: /var/db_backups
  chown -R root: /opt/sysadm
  chown root:system /etc/sysconfig/vlt
  chmod -R 770 /var/vlt
  chmod -R 750 /opt/vlt
  chmod 775 /etc/sysconfig/vlt
  chmod 770 /var/vlt/wui
%end

#########################################################################
# Post Installation: Forward Systems RPMs installation                  #
#########################################################################
%post
  COMMON=/var/vlt/rpm/install
  RPMLOGTMP=/var/vlt/rpm/svlo_rpm_installed.log
  INFO_LOG=/tmp/info_rpms_installed.log

  # Purgar repositorios por defecto (no deben estar en una imagen de proyecto)
  rm -rf /etc/yum.repos.d/*.repo

  if [ -d ${COMMON}/ ] && [ $(ls ${COMMON}/* | wc -l) -ne 0 ]; then
    for i in $(ls ${COMMON})
    do
      if [ -d ${COMMON}/${i} ]; then
        NUM=$(echo ${i} | sed s/_.*//g )
        if [ -z ${PATHS[${NUM}]} ]; then
          PATHS[${NUM}]="${COMMON}/${i}"
        fi
      fi
    done

    for DIR in ${PATHS[*]}; do
      DIR_NAME=$(echo $DIR | xargs -n1 basename)
      #si el directorio empieza por x o X no hacemos nada
      if [[ ! "$DIR_NAME" =~ ^x.*|^X.* ]]; then
         echo "*********************************************************" >> ${INFO_LOG}.${DIR_NAME}
         echo "Installing ${DIR}                                        " >> ${INFO_LOG}.${DIR_NAME}
         echo "*********************************************************" >> ${INFO_LOG}.${DIR_NAME}
         yum --disablerepo=* -y localinstall ${DIR}/*.rpm 2>>${INFO_LOG}.${DIR_NAME} >> ${INFO_LOG}.${DIR_NAME}
         RETVAL=$?

         #mover solo si se ha instalado correctamente
         if [ ${RETVAL} -eq 0 ]; then
            mv ${DIR} /var/vlt/rpm/installed/
            echo "Installed all RPMs of ${DIR_NAME}" >> /tmp/svlo_installed.log
         else
            echo "Error installing RPMs of ${DIR_NAME}" >> /tmp/svlo_error_install.log
            echo "${INFO_LOG}.${DIR_NAME}" >> /tmp/list_error_dirname.log
         fi
         echo "" >> ${INFO_LOG}.${DIR_NAME}
         cat ${INFO_LOG}.${DIR_NAME} >>  ${RPMLOGTMP}
      fi
    done
  fi

  # Disable BaseOS module repository
  yum -y --disablerepo=secupdates module disable BaseOS
%end

#########################################################################
# Post Installation: [LABEL] Label installation                         #
#########################################################################
%post --nochroot

  VERSION=$(cat /run/install/repo/isolinux/isolinux.cfg | grep "menu label" | rev | cut -d ' ' -f1 | rev)

  echo "DATE: $(date +%F)" > /mnt/sysimage/var/vlt/sysconfig/installation_source
  echo "HOUR: $(date +%H:%M:%S)" >> /mnt/sysimage/var/vlt/sysconfig/installation_source
  echo "VERSION: ${VERSION}" >> /mnt/sysimage/var/vlt/sysconfig/installation_source
  echo "" >> /mnt/sysimage/var/vlt/sysconfig/installation_source
  echo "SVLO RPMs Installed (SHA1)" >> /mnt/sysimage/var/vlt/sysconfig/installation_source
  echo "--------------------------" >> /mnt/sysimage/var/vlt/sysconfig/installation_source
  sha1sum $(find /mnt/sysimage/var/vlt/rpm/installed | awk '{print $2,$1}' | sort) >> /mnt/sysimage/var/vlt/sysconfig/installation_source
  sed -i 's|/mnt/sysimage||g' /mnt/sysimage/var/vlt/sysconfig/installation_source

  chattr +i /mnt/sysimage/var/vlt/sysconfig/installation_source
%end

#########################################################################
# Post Installation: [DIALOG] Summary status about the installation     #
#########################################################################
%post
  # Automatically switch to 6th console and redirect all input/output
  exec < /dev/tty6 > /dev/tty6 2> /dev/tty6
  chvt 6

  clear
  dialog --title "Summary Installation RPMs SVLO" --textbox /tmp/svlo_installed.log 40 100

  clear
  dialog --title "Summary Installation RPMs SVLO" --textbox /tmp/svlo_error_install.log 40 100

  clear
  while read FILE
  do
    tail -n 30 ${FILE} > ${FILE}.part
    dialog --title "Log ${FILE}" --textbox ${FILE}.part 40 100
  done < /tmp/list_error_dirname.log

  # Then switch back to Anaconda on the first console
  chvt 1
  exec < /dev/tty1 > /dev/tty1 2> /dev/tty1
%end

#########################################################################
# Disk partitions                                                       #
#########################################################################

%include /tmp/disk-partitions.ks


%packages
@^minimal-environment
#kexec-tools
#_RPMS_LIST_

%end

%addon com_redhat_kdump --disable --reserve-mb='auto'

%end
