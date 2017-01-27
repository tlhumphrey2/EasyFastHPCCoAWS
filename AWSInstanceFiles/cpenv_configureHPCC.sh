#!/bin/bash -e

. /home/ec2-user/cfg_BestHPCC.sh

echo "slavesPerNode=\"$slavesPerNode\""
#----------------------------------------------------------------------------------
# Copy version of envionment.xml setup to use https
#----------------------------------------------------------------------------------
echo "cp /home/ec2-user/newly_created_environment.xml $created_environment_file"
cp /home/ec2-user/newly_created_environment.xml $created_environment_file

#----------------------------------------------------------------------------------
# If username and password is needed for system then do the follow.
#----------------------------------------------------------------------------------
master_ip=`head -1 /home/ec2-user/private_ips.txt`

# IF username and password given THEN setup so system requires them
if  [ -n "$system_username" ] && [ -n "$system_password" ]
then
  #Install HTTPD passwd tool
  echo "yum install -y httpd-tools"
  yum install -y httpd-tools

  echo "htpasswd -cb /etc/HPCCSystems/.htpasswd $system_username $system_password"
  htpasswd -cb /etc/HPCCSystems/.htpasswd $system_username $system_password

  # turn on authentication method htpasswed
  echo "For $created_environment_file, sed to change method to htpasswd and passwordExpirationWarningDays to 100"
  sed "s/method=\"none\"/method=\"htpasswd\"/" $created_environment_file | sed "s/passwordExpirationWarningDays=\"[0-9]*\"/passwordExpirationWarningDays=\"100\"/" > ~/environment_with_htpasswd_enabled.xml 

  # copy changed environment file back into $created_environment_file
  echo "cp ~/environment_with_htpasswd_enabled.xml $created_environment_file"
  cp ~/environment_with_htpasswd_enabled.xml $created_environment_file
fi

#----------------------------------------------------------------------------------
# Make sure hpcc platform is installed on all instance BEFORE doing hpcc-push.
#----------------------------------------------------------------------------------
# Before using hpcc-push.sh to copy new environment.xml file, $created_environment_file, to all instances, make
#  sure the hpcc platform is installed on all instances
perl /home/ec2-user/loopUntilHPCCPlatformInstalledOnAllInstances.pl

# Change new environment.xml file's ownership to hpcc:hpcc
echo "chown hpcc:hpcc $created_environment_file"
chown hpcc:hpcc $created_environment_file

#----------------------------------------------------------------------------------
# Use hpcc-push to push new environment.xml file to all instances.
#----------------------------------------------------------------------------------
# THIS CODE IS MY VERSION OF hpcc-push
out_environment_file=/etc/HPCCSystems/environment.xml
echo "perl /home/ec2-user/tlh_hpcc-push.pl $created_environment_file $out_environment_file"
perl /home/ec2-user/tlh_hpcc-push.pl $created_environment_file $out_environment_file

if [ $slavesPerNode -ne 1 ]
then
   echo "slavesPerNode is greater than 1. So:  execute perl /home/ec2-user/updateSystemFilesOnAllInstances.pl"
   perl /home/ec2-user/updateSystemFilesOnAllInstances.pl
else
   echo "slavesPerNode($slavesPerNode) is equal to 1. So did not execute updateSystemFilesOnAllInstances.pl."
fi

