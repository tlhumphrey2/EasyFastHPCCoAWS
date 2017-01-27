#!/bin/bash
ip=$1
pem=$2
echo "scp -r -o StrictHostKeyChecking=no -i $pem /home/ec2-user/ssh ec2-user\@$ip:/home/hpcc/"
scp -r -o StrictHostKeyChecking=no -i $pem /home/ec2-user/ssh ec2-user@$ip:/home/ec2-user/
echo "ssh -o StrictHostKeyChecking=no -t -t -i $pem ec2-user\@$ip \"sudo cp -rf /home/ec2-user/ssh/* /home/hpcc/.ssh/\""
ssh -o StrictHostKeyChecking=no -t -t -i $pem ec2-user@$ip "sudo cp -rf /home/ec2-user/ssh/* /home/hpcc/.ssh/"


