# ISOLINUX Configuration File

# DISTRIBUTION_INFO : Will be replaced during ISO generation
# DISTRIBUTION_LABEL: Will be replaced during ISO generation

default vesamenu.c32
timeout 600

display boot.msg

# Clear the screen when exiting the menu, instead of leaving the menu displayed.
# For vesamenu, this means the graphical background is still displayed without
# the menu itself for as long as the screen remains in graphics mode.
menu clear
menu background splash.png
menu title _DISTRIBUTION_INFO_ _PRODUCT_
menu vshift 8
menu rows 18
menu margin 8
# Uncomment the following line to hide the menu unless a key is pressed
#menu hidden
menu helpmsgrow 15

# Border Area
menu color border * #00000000 #00000000 none

# Selected item
menu color sel 0 #ffffffff #00000000 none

# Title bar
menu color title 0 #ff7ba3d0 #00000000 none

# Press [Tab] message
# Uncomment to display a custom tab message
#menu color tabmsg 0 #ff3a6496 #00000000 none

# Unselected menu item
menu color unsel 0 #84b8ffff #00000000 none

# Selected hotkey
menu color hotsel 0 #84b8ffff #00000000 none

# Unselected hotkey
menu color hotkey 0 #ffffffff #00000000 none

# Help text
menu color help 0 #ffffffff #00000000 none

# Scrollbar
menu color scrollbar 0 #ffffffff #ff355594 none

# Timeout message
menu color timeout 0 #ffffffff #00000000 none
menu color timeout_msg 0 #ffffffff #00000000 none

# Command prompt text
menu color cmdmark 0 #84b8ffff #00000000 none
menu color cmdline 0 #ffffffff #00000000 none

# Add spacing in the menu
menu separator # insert an empty line
menu separator # insert an empty line

# Define a boot entry
label linux
  menu label ^Install _VERSION_
  kernel vmlinuz
  append initrd=initrd.img inst.text inst.stage2=hd:LABEL=_PRODUCT_ \
         inst.repo=hd:LABEL=_PRODUCT_ inst.ks=hd:LABEL=_PRODUCT_:/isolinux/ks.cfg \
         inst.keymap=es inst.kdump_addon=off consoleblank=0 biosdevname=0 net.ifnames=0

menu end
