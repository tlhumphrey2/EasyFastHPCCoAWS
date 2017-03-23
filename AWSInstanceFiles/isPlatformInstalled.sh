#!/bin/bash
if [ -e /etc/init.d/hpcc-init ] && [ -e /home/hpcc ]
then
   echo "hpcc is installed"
else
   echo "hpcc is NOT installed"
fi
