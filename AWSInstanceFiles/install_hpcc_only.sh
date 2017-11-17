#!/bin/bash
ThisDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

hpcc_platform=$1
# E.G. hpcc_platform=http://wpc.423A.rhocdn.net/00423A/releases/CE-Candidate-6.2.6/bin/platform/hpccsystems-platform-community_6.2.6-1.el6.x86_64.rpm

#install hpcc
echo "install hpcc"
mkdir hpcc
cd hpcc
echo "wget $hpcc_platform"
wget $hpcc_platform

echo "yum install $hpcc_platform -y"
yum install $hpcc_platform -y
