#!/bin/bash
# mountS3Bucket.sh
# Note. This is done after HPCC System has been fully configured and is stopped, i.e. sudo service hpcc-init stop.
# and is is only done on the master instance.

. cfg_BestHPCC.sh
#----------------------------------------------------
# Setup S3FS and Fuse for mounting s3 bucket as drive
#----------------------------------------------------
     
# Download and compile latest Fuse
cd /usr/src/
sudo wget http://sourceforge.net/projects/fuse/files/fuse-2.X/2.9.3/fuse-2.9.3.tar.gz
sudo tar xzf fuse-2.9.3.tar.gz
cd fuse-2.9.3
sudo ./configure --prefix=/usr/local
sudo make
sudo make install
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
sudo ldconfig
sudo modprobe fuse     
     
# Download and install latest F3FS
cd /usr/src/
sudo wget https://s3fs.googlecode.com/files/s3fs-1.74.tar.gz
sudo tar xzf s3fs-1.74.tar.gz
cd s3fs-1.74
sudo ./configure --prefix=/usr/local
sudo make
sudo make install

# Setup Access Keys
sudo echo $S3_ACCESS_KEY:$S3_SECRET_KEY > ~/.passwd-s3fs
sudo chmod 600 ~/.passwd-s3fs

#----------------------------------------------------
# Mount S3 bucket as drive (/tmpdrive)
#----------------------------------------------------
sudo mkdir /tmp/cache
#sudo mkdir /tmpdrive
#sudo chmod 777 /tmpdrive
sudo chmod 777 /tmp/cache
sudo chmod 777 /var/lib/HPCCSystems/mydropzone

# Uncommenting 'user_allow_other' in /etc/fuse.conf so 'allow_other' works in f3fs
sudo sed "s/# user_allow_other/user_allow_other/" /etc/fuse.conf > t
sudo mv t /etc/fuse.conf

# Do mount onto /var/lib/HPCCSystems/mydropzone
s3fs -o rw,allow_other,use_cache=/tmp/cache,uid=33,gid=33 $bucket_name /var/lib/HPCCSystems/mydropzone

sudo chmod 777 /var/lib/HPCCSystems/mydropzone/* 

