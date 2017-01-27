#!/bin/bash
# bash cpSavedFilesOnEBS2MasterInstance.sh $region $instance_id $volume_id
# Copy files saved on EBS volume, volume id is below, to mydropzone.
# Then, start HPCC System

region=$1
instance_id=$2
volume_id=$3

echo "\"aws ec2 attach-volume --volume-id $volume_id --instance-id $instance_id --device /dev/sdz --region $region\""
aws ec2 attach-volume --volume-id $volume_id --instance-id $instance_id --device /dev/sdz --region $region
echo "sleep 5"
sleep 5
if [ ! -e "/home/ec2-user/XPertHR-Files" ];then
  echo "\"mkdir /home/ec2-user/XPertHR-Files\""
  mkdir /home/ec2-user/XPertHR-Files
else
  echo "The directory, /home/ec2-user/XPertHR-Files, EXISTS."
fi
echo "\"mount /dev/xvdz /home/ec2-user/XPertHR-Files\""
mount /dev/xvdz /home/ec2-user/XPertHR-Files
echo "\"cp -r /home/ec2-user/XPertHR-Files/mydropzone/* /var/lib/HPCCSystems/mydropzone\""
cp -r /home/ec2-user/XPertHR-Files/mydropzone/* /var/lib/HPCCSystems/mydropzone
echo "\"chown hpcc:hpcc /var/lib/HPCCSystems/mydropzone/*\""
chown hpcc:hpcc /var/lib/HPCCSystems/mydropzone/*
echo "\"umount /dev/xvdz # Dismount /dev/xvdx\""
umount /dev/xvdz # Dismount /dev/xvdx
echo "\"aws ec2 detach-volume --volume-id $volume_id --region $region\""
aws ec2 detach-volume --volume-id $volume_id --region $region
echo "sleep 2"
sleep 2
echo "Completed copy from EBS volume to HPCC System"
