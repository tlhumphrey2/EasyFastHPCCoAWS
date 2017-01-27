#!/bin/bash -e

. /home/ec2-user/cfg_BestHPCC.sh

if [ "$1" != "" ];then
  created_environment_file=$1
fi

#----------------------------------------------------------------------------------
# Use hpcc-push to push new environment.xml file to all instances.
#----------------------------------------------------------------------------------

# Change new environment.xml file's ownership to hpcc:hpcc
echo "chown hpcc:hpcc $created_environment_file"
chown hpcc:hpcc $created_environment_file

# THIS CODE IS MY VERSION OF hpcc-push
out_environment_file=/etc/HPCCSystems/environment.xml
echo "perl /home/ec2-user/tlh_hpcc-push.pl $created_environment_file $out_environment_file"
perl /home/ec2-user/tlh_hpcc-push.pl $created_environment_file $out_environment_file
