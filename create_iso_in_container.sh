#!/bin/bash

/workdir/bootstrap.sh clean
/workdir/bootstrap.sh step isomount
/workdir/bootstrap.sh step createtemplate
/workdir/bootstrap.sh step scandeps
/workdir/bootstrap.sh step createrepo
/workdir/bootstrap.sh step createiso
/workdir/bootstrap.sh step isounmount
cp /workdir/AlmaLinux-9.1-x86_64-minimal.iso /mnt/
