#!/bin/bash
# v1.0 all

. /etc/vectra130/configs/sysconfig/.sysconfig

cd $SCRIPTDIR

git add *
git add .[a-zA-Z]*
git commit -m "$HOSTNAME"
git push -u origin master
