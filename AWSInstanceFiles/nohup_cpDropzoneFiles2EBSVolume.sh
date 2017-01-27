#!/bin/bash
region=$1
instance_id=$2
volume_id=$3

nohup /home/ec2-user/cpDropzoneFiles2EBSVolume.sh $region $instance_id $volume_id  > /home/ec2-user/cpDropzoneFiles2EBSVolume.log&
