#!/bin/bash -e

. /home/ec2-user/cfg_BestHPCC.sh

# Change name of $created_environment_file so it is prefixed with "intial_"
basename=$(basename "$created_environment_file")
path_and_basename="${created_environment_file%.*}"
path=`echo $path_and_basename|sed "s/^\(..*\/\).*$/\1/"`
created_environment_file="${path}initial_$basename"

slavesPerNode=1

set2falseRoxieMultiCaseEnabled=''
if [ $roxienodes -gt 0 ]
then
  set2falseRoxieMultiCaseEnabled=' -override roxie,@roxieMultiCastEnabled,false'
fi

envgen=/opt/HPCCSystems/sbin/envgen;

# Make new environment.xml file for newly configured HPCC System.
echo "$envgen -env $created_environment_file $set2falseRoxieMultiCaseEnabled -override esp,@method,htpasswd -override thor,@replicateAsync,true -override thor,@replicateOutputs,true -ipfile $private_ips -supportnodes $supportnodes -thornodes $non_support_instances -roxienodes $roxienodes -slavesPerNode $slavesPerNode -roxieondemand 1"

$envgen  -env $created_environment_file $set2falseRoxieMultiCaseEnabled -override esp,@method,htpasswd -override thor,@replicateAsync,true -override thor,@replicateOutputs,true -ipfile $private_ips -supportnodes $supportnodes -thornodes $non_support_instances -roxienodes $roxienodes  -slavesPerNode $slavesPerNode -roxieondemand 1
echo "Completed $envgen"

# Copy the newly created environment file  to /etc/HPCCSystems on all nodes of the THOR
out_environment_file=/etc/HPCCSystems/environment.xml
master_ip=`head -1 /home/ec2-user/private_ips.txt`
echo "ssh -o StrictHostKeyChecking=no -t -t -i $pem ec2-user@$master_ip \"sudo /opt/HPCCSystems/sbin/hpcc-push.sh -s $created_environment_file -t $out_environment_file\""
ssh -o StrictHostKeyChecking=no -t -t -i $pem ec2-user@$master_ip "sudo /opt/HPCCSystems/sbin/hpcc-push.sh -s $created_environment_file -t $out_environment_file"
echo "Completed hpcc-push.sh"
