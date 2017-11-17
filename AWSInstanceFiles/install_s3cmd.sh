#!/bin/bash
ThisDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Entering install_s3cmd.sh"
repo_dir=/etc/yum.repo.d
s3tools_repo=$repo_dir/s3tools.repo

if [ ! -e $repo_dir ]
then
   echo "mkdir $repo_dir"
   mkdir $repo_dir
fi

if [ ! -e $s3tools_repo ]
then
   echo "cp $ThisDir/s3tools.repo $s3tools_repo"
   cp $ThisDir/s3tools.repo $s3tools_repo
fi

echo "yum -y install s3cmd"
yum -y install s3cmd

python --version &> python_version.txt

py26="Python 2.6"

echo "current_python=\$(cat python_version.txt|awk '{printf "%s\\n",substr($0,1,10)}')"
current_python=$(cat python_version.txt|awk '{printf "%s\n",substr($0,1,10)}')

if [ "$current_python" != "$py26" ]
then
  echo "update-alternatives --set python /usr/bin/python2.6"
  update-alternatives --set python /usr/bin/python2.6
fi
echo "Leaving install_s3cmd.sh"
