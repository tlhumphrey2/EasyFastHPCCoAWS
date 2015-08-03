#!/bin/bash -e

. /home/ec2-user/cfg_BestHPCC.sh

# Change name of $created_environment_file so it is prefixed with "intial_"
basename=$(basename "$created_environment_file")
path_and_basename="${created_environment_file%.*}"
path=`echo $path_and_basename|sed "s/^\(..*\/\).*$/\1/"`
created_environment_file="${path}initial_$basename"

slavesPerNode=1

set2falseRoxieMulticastEnabled=''
if [ $roxienodes -gt 0 ]
then
  set2falseRoxieMulticastEnabled=' -override roxie,@roxieMulticastEnabled,false'
fi

envgen=/opt/HPCCSystems/sbin/envgen;

# Make new environment.xml file for newly configured HPCC System.
echo "$envgen -env $created_environment_file $set2falseRoxieMulticastEnabled -override esp,@method,htpasswd -override thor,@replicateAsync,true -override thor,@replicateOutputs,true -ipfile $private_ips -supportnodes $supportnodes -thornodes $non_support_instances -roxienodes $roxienodes -slavesPerNode $slavesPerNode -roxieondemand 1"

$envgen  -env $created_environment_file $set2falseRoxieMulticastEnabled -override esp,@method,htpasswd -override thor,@replicateAsync,true -override thor,@replicateOutputs,true -ipfile $private_ips -supportnodes $supportnodes -thornodes $non_support_instances -roxienodes $roxienodes  -slavesPerNode $slavesPerNode -roxieondemand 1
echo "Completed $envgen"

# Before using hpcc-push.sh to copy new environment.xml file, $created_environment_file, to all instances, make
#  sure the hpcc platform is installed on all instances
perl /home/ec2-user/loopUntilHPCCPlatformInstalledOnAllInstances.pl

echo "chown hpcc:hpcc $created_environment_file"
chown hpcc:hpcc $created_environment_file

out_environment_file=/etc/HPCCSystems/environment.xml
echo "perl /home/ec2-user/tlh_hpcc-push.pl $created_environment_file $out_environment_file"
perl /home/ec2-user/tlh_hpcc-push.pl $created_environment_file $out_environment_file

echo "Completed hpcc-push.sh"
