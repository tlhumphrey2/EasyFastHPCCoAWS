#!/bin/bash
ThisDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "mkdir $ThisDir/ssh"
mkdir $ThisDir/ssh
echo "cp -f /home/hpcc/.ssh/id_rsa $ThisDir/ssh"
cp -f /home/hpcc/.ssh/id_rsa $ThisDir/ssh
echo "cp -f /home/hpcc/.ssh/id_rsa.pub $ThisDir/ssh"
cp -f /home/hpcc/.ssh/id_rsa.pub $ThisDir/ssh
echo "cp -f /home/hpcc/.ssh/authorized_keys $ThisDir/ssh"
cp -f /home/hpcc/.ssh/authorized_keys $ThisDir/ssh
echo "chown -R ec2-user:ec2-user $ThisDir/ssh"
chown -R ec2-user:ec2-user $ThisDir/ssh
