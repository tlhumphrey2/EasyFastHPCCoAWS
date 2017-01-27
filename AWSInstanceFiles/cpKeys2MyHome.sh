#!/bin/bash
echo "mkdir /home/ec2-user/ssh"
mkdir /home/ec2-user/ssh
echo "cp -f /home/hpcc/.ssh/id_rsa /home/ec2-user/ssh"
cp -f /home/hpcc/.ssh/id_rsa /home/ec2-user/ssh
echo "cp -f /home/hpcc/.ssh/id_rsa.pub /home/ec2-user/ssh"
cp -f /home/hpcc/.ssh/id_rsa.pub /home/ec2-user/ssh
echo "cp -f /home/hpcc/.ssh/authorized_keys /home/ec2-user/ssh"
cp -f /home/hpcc/.ssh/authorized_keys /home/ec2-user/ssh
echo "chown -R ec2-user:ec2-user /home/ec2-user/ssh"
chown -R ec2-user:ec2-user /home/ec2-user/ssh
