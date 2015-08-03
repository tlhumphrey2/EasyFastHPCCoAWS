#!/bin/bash -e

. /home/ec2-user/cfg_BestHPCC.sh

echo "slavesPerNode=\"$slavesPerNode\""

#----------------------------------------------------------------------------------
# If there are ROXIEs in the configuration then set roxieMulticastEnabled to false.
#----------------------------------------------------------------------------------
set2falseRoxieMulticastEnabled=''
if [ $roxienodes -gt 0 ]
then
  set2falseRoxieMulticastEnabled=' -override roxie,@roxieMulticastEnabled,false'

  echo "roxienodes is greater than 0. So:  execute perl /home/ec2-user/updateEnvGenConfigurationForHPCC.pl"
  perl /home/ec2-user/updateEnvGenConfigurationForHPCC.pl
fi

#--------------------------------------------------------------------------------------------------------------------------------
# Override globalMemorySize and masterMemorySize if master and slave memory sizes are different and their sizes are large enough.
#--------------------------------------------------------------------------------------------------------------------------------
masterMemTotal=`bash /home/ec2-user/getPhysicalMemory.sh`
echo " masterMemTotal=\"$masterMemTotal\""

SlavePublicIP=$(head -2 /home/ec2-user/public_ips.txt|tail -1)
slaveMemTotal0=$(ssh -o StrictHostKeyChecking=no -t -t -i $pem ec2-user@$SlavePublicIP bash /home/ec2-user/getPhysicalMemory.sh)
slaveMemTotal=`echo $slaveMemTotal0|sed "s/.$//"`
echo " slaveMemTotal=\"$slaveMemTotal\""

# So we change globalMemorySize and masterMemorySize when the master and slave's memory aren't the same and
#  when slave's memory is at least 10 gb and master's memory size is at least 2 gb.
OneMB=1048576
HalfGB=536870912
OneGB=1073741824
TwoGB=2147483648

# 10 GB = 10737418240
MinLargeSlaveMemory=10737418240

memory_override=''
if [ $masterMemTotal -ne $slaveMemTotal ] && [ $slaveMemTotal -gt $MinLargeSlaveMemory ] && [ $masterMemTotal -ge $TwoGB ]
then
   # masterMemorySize = ($masterMemTotal - $OneGB)/$OneMB
   masterMemorySize=$(echo $masterMemTotal $OneGB $OneMB| awk '{printf "%.0f\n",($1-$2)/$3}')

   # globalMemorySize = ((($slaveMemTotal - $OneGB)/$slavesPerNode)-$HalfGB)/$OneMB
   globalMemorySize=$(echo $slaveMemTotal $OneGB $slavesPerNode $HalfGB $OneMB| awk '{printf "%.0f\n",((($1 - $2)/$3)-$4)/$5}')
   echo "masterMemorySize=\"$masterMemorySize\", globalMemorySize=\"$globalMemorySize\""
   master_override="-override thor,@masterMemorySize,$masterMemorySize"
   slave_override="-override thor,@globalMemorySize,$globalMemorySize"
   heap_override="-override thor,@heapUseHugePages,true"
   memory_override=" $master_override $slave_override $heap_override"
fi

#----------------------------------------------------------------------------------
# Generate a new environment.xml file.
#----------------------------------------------------------------------------------
envgen=/opt/HPCCSystems/sbin/envgen;

# Make new environment.xml file for newly configured HPCC System.
echo "$envgen -env $created_environment_file $memory_override $set2falseRoxieMulticastEnabled -override esp,@method,htpasswd -override thor,@replicateAsync,true -override thor,@replicateOutputs,true -ipfile $private_ips -supportnodes $supportnodes -thornodes $non_support_instances -roxienodes $roxienodes -slavesPerNode $slavesPerNode -roxieondemand 1"
$envgen  -env $created_environment_file $memory_override $set2falseRoxieMulticastEnabled -override esp,@method,htpasswd -override thor,@replicateAsync,true -override thor,@replicateOutputs,true -ipfile $private_ips -supportnodes $supportnodes -thornodes $non_support_instances -roxienodes $roxienodes  -slavesPerNode $slavesPerNode -roxieondemand 1

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

