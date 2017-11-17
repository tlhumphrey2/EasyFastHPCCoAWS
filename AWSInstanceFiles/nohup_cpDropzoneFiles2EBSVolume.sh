#!/bin/bash
ThisDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
region=$1
instance_id=$2
volume_id=$3

nohup $ThisDir/cpDropzoneFiles2EBSVolume.sh $region $instance_id $volume_id  > $ThisDir/cpDropzoneFiles2EBSVolume.log&
