#!/bin/bash
# bash cpSavedFilesOnEBS2SlaveInstance.sh $region $instance_id $volume_id
# First stop the HPCC System.Then, copy all thor files of EBS to /var/lib/HPCCSystems/hpcc-data
ThisDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

region=$1
instance_id=$2
volume_id=$3

echo "\"perl stopHPCCOnAllInstances.pl\""
perl stopHPCCOnAllInstances.pl
echo "\"aws ec2 attach-volume --volume-id $volume_id --instance-id $instance_id --device /dev/sdz --region $region\""
aws ec2 attach-volume --volume-id $volume_id --instance-id $instance_id --device /dev/sdz --region $region
echo "sleep 5"
sleep 5
if [ ! -e "$ThisDir/XPertHR-Files" ];then
  echo "\"mkdir $ThisDir/XPertHR-Files\""
  mkdir $ThisDir/XPertHR-Files
else
  echo "The directory, $ThisDir/XPertHR-Files, EXISTS."
fi
echo "\"mount /dev/xvdz $ThisDir/XPertHR-Files\""
mount /dev/xvdz $ThisDir/XPertHR-Files
echo "\"mkdir /var/lib/HPCCSystems/hpcc-data\""
mkdir /var/lib/HPCCSystems/hpcc-data
echo "\"chown -R hpcc:hpcc /var/lib/HPCCSystems/hpcc-data\""
chown -R hpcc:hpcc /var/lib/HPCCSystems/hpcc-data
echo "\"cd $ThisDir/XPertHR-Files\""
cd $ThisDir/XPertHR-Files
echo "\"cp -r thor /var/lib/HPCCSystems/hpcc-data\""
cp -r thor /var/lib/HPCCSystems/hpcc-data
echo "\"chown -R hpcc:hpcc /var/lib/HPCCSystems/hpcc-data/*\""
chown -R hpcc:hpcc /var/lib/HPCCSystems/hpcc-data/*
cd /home/ec2-user
echo "\"umount /dev/xvdz # Dismount /dev/xvdz\""
umount /dev/xvdz # Dismount /dev/xvdz
echo "\"aws ec2 detach-volume --volume-id $volume_id --region $region\""
aws ec2 detach-volume --volume-id $volume_id --region $region
echo "sleep 5"
sleep 5
echo "Completed copy from EBS volume to HPCC System"
