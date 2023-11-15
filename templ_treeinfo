[checksums]
images/efiboot.img = sha256:adff3d7cf76139a7459a3b287e14f4dbb8d67bfe2432818875f3e92b0173f24e
images/install.img = sha256:af4bc8a26fdacda5dc1c2fba5c820ae22a1e63988294d31ab54eaa225a25d219
images/pxeboot/initrd.img = sha256:098a4cff399295a08e0d620f0292c31b45f19ae374615183c6f99fe6aa8bef91
images/pxeboot/vmlinuz = sha256:553e7134206817f3862fc06aaaab479158438a344bed3157894e2ed7cda536f1

[general]
; WARNING.0 = This section provides compatibility with pre-productmd treeinfos.
; WARNING.1 = Read productmd documentation for details about new format.
arch = x86_64
family = AlmaLinux
name = AlmaLinux 9
packagedir = AppStream/Packages
platforms = x86_64,xen
repository = AppStream
timestamp = 1668611635
variant = AppStream
variants = AppStream,BaseOS
version = 9

[header]
type = productmd.treeinfo
version = 1.2

[images-x86_64]
efiboot.img = images/efiboot.img
initrd = images/pxeboot/initrd.img
kernel = images/pxeboot/vmlinuz

[images-xen]
initrd = images/pxeboot/initrd.img
kernel = images/pxeboot/vmlinuz

[media]
discnum = 1
totaldiscs = 1

[release]
name = AlmaLinux
short = AlmaLinux
version = 9

[stage2]
mainimage = images/install.img

[tree]
arch = x86_64
build_timestamp = 1668611635
platforms = x86_64,xen
variants = AppStream,BaseOS

[variant-AppStream]
id = AppStream
name = AppStream
packages = AppStream/Packages
repository = AppStream
type = variant
uid = AppStream

[variant-BaseOS]
id = BaseOS
name = BaseOS
packages = BaseOS/Packages
repository = BaseOS
type = variant
uid = BaseOS
