#!/bin/bash

#install prereqs
echo "install prereqs"
yum install -y boost141
yum install -y compat-boost-regex

yum install -y R-devel
R CMD BATCH installR.r

#install blas
echo "install blas"
yum install atlas atlas-devel lapack-devel blas-devel
ln -s /usr/lib64/libblas.so /usr/lib/libblas.so
ln -s /usr/lib64/atlas/libcblas.so /usr/lib/libcblas.so

#install hpcc
echo "install hpcc"

. ~ec2-user/cfg_BestHPCC.sh

mkdir hpcc
cd hpcc
echo "wget $hpcc_platform"
wget $hpcc_platform

echo "rpm -iv --nodeps $hpcc_platform"
rpm -iv --nodeps $hpcc_platform

cd ..
