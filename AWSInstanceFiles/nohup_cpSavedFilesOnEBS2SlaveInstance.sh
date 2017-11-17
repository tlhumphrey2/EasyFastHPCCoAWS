#!/bin/bash
ThisDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
region=$1
instance_id=$2
volume_id=$3

nohup $ThisDir/cpSavedFilesOnEBS2SlaveInstance.sh $region $instance_id $volume_id  > $ThisDir/cpSavedFilesOnEBS2SlaveInstance.log&
