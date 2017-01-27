#!/bin/bash 

ip=$1

u=ec2-user
pem=~/tlh-us-west-1-keypair-1.pem
if [ $# -eq 2 ]
then
  u=$2
fi

echo "ssh -o stricthostkeychecking=no -i $pem $u@$ip"
ssh -o stricthostkeychecking=no -i $pem $u@$ip
