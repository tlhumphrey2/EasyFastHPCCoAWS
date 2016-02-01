#!/bin/bash
# mountS3Bucket.sh
# Note. This is done after HPCC System has been fully configured and is stopped, i.e. sudo service hpcc-init stop.
# and is is only done on the master instance.

# From the following configuration file, this code gets $S3_ACCESS_KEY, $S3_SECRET_KEY, and $bucket_name.
. cfg_BestHPCC.sh
     
#----------------------------------------------------
# Download prerequisites
#----------------------------------------------------
echo "EXE: sudo yum -y install gcc libstdc++-devel gcc-c++ fuse fuse-devel curl-devel libxml2-devel mailcap openssl-devel"
sudo yum -y install gcc libstdc++-devel gcc-c++ fuse fuse-devel curl-devel libxml2-devel mailcap openssl-devel
     
#----------------------------------------------------
# Download and install latest F3FS
#----------------------------------------------------
cd /usr/src/
echo "EXE: sudo wget https://s3fs.googlecode.com/files/s3fs-1.74.tar.gz"
sudo wget https://s3fs.googlecode.com/files/s3fs-1.74.tar.gz
echo "EXE: sudo tar xzf s3fs-1.74.tar.gz"
sudo tar xzf s3fs-1.74.tar.gz
cd s3fs-1.74
echo "EXE: sudo ./configure --prefix=/usr/local"
sudo ./configure --prefix=/usr/local
echo "EXE: sudo make"
sudo make
echo "EXE: sudo make install"
sudo make install

# Setup Access Keys for s3fs
echo "EXE: sudo echo $S3_ACCESS_KEY:$S3_SECRET_KEY > ~/.passwd-s3fs"
sudo echo $S3_ACCESS_KEY:$S3_SECRET_KEY > ~/.passwd-s3fs
echo "EXE: sudo chmod 600 ~/.passwd-s3fs"
sudo chmod 600 ~/.passwd-s3fs

#----------------------------------------------------
# Mount S3 bucket as drive (/tmpdrive)
#----------------------------------------------------
# Put s3cache someplace where there is a lot of disk space (in case the s3 bucket is very large)
echo "EXE: sudo mkdir /var/lib/HPCCSystems/s3cache"
sudo mkdir /var/lib/HPCCSystems/s3cache
echo "EXE: sudo chmod 777 /var/lib/HPCCSystems/s3cache"
sudo chmod 777 /var/lib/HPCCSystems/s3cache
echo "EXE: sudo chmod 777 /var/lib/HPCCSystems/mydropzone"
sudo chmod 777 /var/lib/HPCCSystems/mydropzone

if [ -e "/etc/fuse.conf" ]
then
   # Uncommenting 'user_allow_other' in /etc/fuse.conf so 'allow_other' works in f3fs
   echo "EXE: sudo sed "s/# *user_allow_other/user_allow_other/" /etc/fuse.conf > t"
   sudo sed "s/# *user_allow_other/user_allow_other/" /etc/fuse.conf > t
   echo "EXE: sudo mv t /etc/fuse.conf"
   sudo mv t /etc/fuse.conf
else
   echo "EXE: sudo echo \"user_allow_other\" \> /etc/fuse.conf"
   sudo echo "user_allow_other" > /etc/fuse.conf
fi

# Mount s3 bucket onto /var/lib/HPCCSystems/mydropzone
echo "EXE: s3fs -o rw,allow_other,use_cache=/var/lib/HPCCSystems/s3cache,uid=33,gid=33 $bucket_name /var/lib/HPCCSystems/mydropzone"
s3fs -o rw,allow_other,use_cache=/var/lib/HPCCSystems/s3cache,uid=33,gid=33 $bucket_name /var/lib/HPCCSystems/mydropzone

echo "EXE: ls -1 /var/lib/HPCCSystems/mydropzone/*\|wc -l"
echo "`ls -1 /var/lib/HPCCSystems/mydropzone/*|wc -l` files on mydropzone"
