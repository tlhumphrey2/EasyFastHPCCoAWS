#!/bin/bash

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

echo "symbolic links to blas libraries"
ln -s /usr/lib64/libblas.so /usr/lib/libblas.so
ln -s /usr/lib64/atlas/libcblas.so /usr/lib/libcblas.so

# Instantiate configuration variables
echo "Instantiate configuration variables (need phcc_platform)"
. ~ec2-user/cfg_BestHPCC.sh

# Install s3cmd
~ec2-user/install_s3cmd.sh

#install hpcc
echo "install hpcc"
mkdir hpcc
cd hpcc
echo "wget $hpcc_platform"
wget $hpcc_platform

echo "rpm -iv --nodeps $hpcc_platform"
rpm -iv --nodeps $hpcc_platform

if [ "$#" -eq 1 ];then
   if [ "$1" == "YES" ];then
     echo "FIRST. Install cassandra"
     echo "cp /home/ec2-user/datastax.repo /etc/yum.repos.d/"
     cp /home/ec2-user/datastax.repo /etc/yum.repos.d/

     echo "yum -y install cassandra21"
     yum -y install cassandra21

     echo "SECOND. Configure cassandra"
     echo "perl ~ec2-user/configureCassandra.pl"
     perl ~ec2-user/configureCassandra.pl

     echo "THIRD. Setup so cassandra can be run as a service"
     if [ -e /etc/init.d/cassandra ];then
       echo "mv /etc/init.d/cassandra /etc/init.d/cassandra.saved"
       mv /etc/init.d/cassandra /etc/init.d/cassandra.saved
     fi
     echo "cp ~ec2-user/cassandra /etc/init.d/cassandra"
     cp ~ec2-user/cassandra /etc/init.d/cassandra
     echo "chmod 755 /etc/init.d/cassandra"
     chmod 755 /etc/init.d/cassandra
   fi
fi

