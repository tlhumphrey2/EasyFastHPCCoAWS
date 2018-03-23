#!/bin/bash
#Step 1: Download the x86_64 rpm for the EPEL repository 
#echo "Step 1: Download the x86_64 rpm for the EPEL repository"
#echo "wget http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"
#wget http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

#Step 2: Install the EPEL rpm to add the repository to your system
#echo "yum install epel-release-6-8.noarch.rpm"
#yum install epel-release-6-8.noarch.rpm
#rpm -ivh epel-release-6-8.noarch.rpm

#Step 3: Verify the EPEL repository was added
#echo "yum repolist"
#yum repolist

#Step 4: Install Ansible
#echo "yum update && yum install ansible"
#yum update && yum install ansible
echo "INSTALL Ansible"
echo "pip install 'ansible==2.3.1.0'"
pip install 'ansible==2.3.1.0'

echo "INSTALL netaddr"
echo "pip install netaddr"
pip install netaddr
