#!/bin/bash
ThisDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
sshuser=`basename $ThisDir`

# Instantiate configuration variables
echo "Instantiate configuration variables (need hpcc_platform)"
. $ThisDir/cfg_BestHPCC.sh

#install prereqs
echo "install prereqs"
yum install -y boost141
yum install -y compat-boost-regex

yum install -y R-devel
R CMD BATCH installR.r

#install blas
echo "install atlas"
yum -y install atlas
echo "install atlas-devel"
yum -y install atlas-devel
echo "install lapack-devel"
yum -y install lapack-devel
echo "install blas-devel"
yum -y install blas-devel

#install libsvm-devel
echo "yum -y install libsvm-devel"
yum -y install libsvm-devel

echo "symbolic links to blas libraries"
ln -s /usr/lib64/libblas.so /usr/lib/libblas.so
ln -s /usr/lib64/atlas/libcblas.so /usr/lib/libcblas.so

# Install s3cmd
$ThisDir/install_s3cmd.sh

#install hpcc
echo "install hpcc"
mkdir hpcc
cd hpcc
echo "wget $hpcc_platform"
wget $hpcc_platform

#if [ "$IsPlatformSixOrHigher" -eq 1 -a "$sshuser" != 'centos' ];then
if [ "$IsPlatformSixOrHigher" -eq 1 ];then
 if [ "$FirstDigitOfPlatformVersion" -gt 6 ];then
   echo "$ThisDir/install-devtools2-and-libstdc.sh"
   $ThisDir/install-devtools2-and-libstdc.sh
 fi
 echo "yum install $hpcc_platform -y"
 yum install $hpcc_platform -y
else
 echo "rpm -iv --nodeps $hpcc_platform"
 rpm -iv --nodeps $hpcc_platform
fi

if [ "$#" -eq 1 ];then
   if [ "$1" == "YES" ];then
     echo "FIRST. Install cassandra"
     echo "cp $ThisDir/datastax.repo /etc/yum.repos.d/"
     cp $ThisDir/datastax.repo /etc/yum.repos.d/

     echo "yum -y install cassandra21"
     yum -y install cassandra21

     echo "SECOND. Configure cassandra"
     echo "perl $ThisDir/configureCassandra.pl"
     perl $ThisDir/configureCassandra.pl

     echo "THIRD. Setup so cassandra can be run as a service"
     if [ -e /etc/init.d/cassandra ];then
       echo "mv /etc/init.d/cassandra /etc/init.d/cassandra.saved"
       mv /etc/init.d/cassandra /etc/init.d/cassandra.saved
     fi
     echo "cp $ThisDir/cassandra /etc/init.d/cassandra"
     cp $ThisDir/cassandra /etc/init.d/cassandra
     echo "chmod 755 /etc/init.d/cassandra"
     chmod 755 /etc/init.d/cassandra
   fi
fi
