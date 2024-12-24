set default="1"

function load_video {
  insmod efi_gop
  insmod efi_uga
  insmod video_bochs
  insmod video_cirrus
  insmod all_video
}

load_video
set gfxpayload=keep
insmod gzio
insmod part_gpt
insmod ext2

set timeout=60
### END /etc/grub.d/00_header ###

search --no-floppy --set=root -l '_PRODUCT_'

### BEGIN /etc/grub.d/10_linux ###
menuentry 'Install _VERSION_' --class fedora --class gnu-linux --class gnu --class os {
    linuxefi /images/pxeboot/vmlinuz inst.text inst.stage2=hd:LABEL=_PRODUCT_ inst.repo=hd:LABEL=_PRODUCT_ inst.ks=hd:LABEL=_PRODUCT_:/isolinux/ks.cfg inst.keymap=es inst.kdump_addon=off consoleblank=0 biosdevname=0 net.ifnames=0
	initrdefi /images/pxeboot/initrd.img
}
