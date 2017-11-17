#!/bin/bash
ThisDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ip=$1
pem=$2
echo "scp -r -o StrictHostKeyChecking=no -i $pem $ThisDir/ssh ec2-user\@$ip:/home/hpcc/"
scp -r -o StrictHostKeyChecking=no -i $pem $ThisDir/ssh ec2-user@$ip:$ThisDir/
echo "ssh -o StrictHostKeyChecking=no -t -t -i $pem ec2-user\@$ip \"sudo cp -rf $ThisDir/ssh/* /home/hpcc/.ssh/\""
ssh -o StrictHostKeyChecking=no -t -t -i $pem ec2-user@$ip "sudo cp -rf $ThisDir/ssh/* /home/hpcc/.ssh/"
