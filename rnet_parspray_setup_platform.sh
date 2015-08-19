
#!/bin/bash
USER=hpcc
MAIN_FOLDER=/home/$USER/rnet-parspray-files
#PEM_FILE=rnet-hpcc-kp.pem


function print_usage
{
 echo "STEOP: Make sure to take the following steps before running this program:"
 echo "1. Setup a password for user hpcc."
 echo "2. Setup ssh keys on all nodes for user hpcc using ssh-keygen, then copy public keys of all in ~/.ssh/authorized_keys of all"
 echo "3. Add hpcc to sudoers"
 echo "4. Set user to hpcc and run this program as a super user (sudo)."
 echo "Usage: $0 <nfs (for instance with attached snapshot) | <nsf server IP>(for others)> go"
}

usermod -s /bin/bash $USER
if [ $# -eq 1 ]
then
  if [ $1 != "go" ]
  then 
	$print_usage
	exit
  fi
  #ARG=$1
else
 $print_usage
 exit
fi

yum update  -y
yum install zip unzip -y
yum install nfs-utils.x86_64 -y
yum install python-pip.noarch -y

if [ ! -d $MAIN_FOLDER ]
then
	aws s3 cp --recursive s3://rnet-parspray-files $MAIN_FOLDER > /dev/null
fi

chown $USER:$USER -R $MAIN_FOLDER
mkdir /home/$USER/temp
chown $USER:$USER /home/$USER/temp
if [ ! -d /home/$USER/.aws ]
then
	mkdir /home/$USER/.aws
	chown $USER:$USER /home/$USER/.aws
fi
chown $USER:$USER /home/$USER/.bashrc


rm $MAIN_FOLDER/machines.list
touch $MAIN_FOLDER/machines.list
chown $USER:$USER $MAIN_FOLDER/machines.list
if [ ! -f /home/$USER/.aws/credentials ]
then
	cp /home/ec2-user/credentials /home/$USER/.aws/
	chown $USER:$USER /home/$USER/.aws/credentials
fi
sed -i 's/requiretty/!requiretty/g' /etc/sudoers
sudo -u ec2-user /home/ec2-user/getPublicAndPrivateIps.pl
sed -i '/^$/d' /home/ec2-user/private_ips.txt
tail -n+2 /home/ec2-user/private_ips.txt > $MAIN_FOLDER/machines.list
#reverse the order to start from lower IP to higher
sed -i '1!G;h;$!d' $MAIN_FOLDER/machines.list
chmod +x $MAIN_FOLDER/get_*_ip.sh

tar -xzvf $MAIN_FOLDER/openmpi-1.8.1_install.tgz -C /opt/ > /dev/null
echo "export PATH=\$PATH:/opt/openmpi-1.8.1/bin" >> /home/$USER/.bashrc
export PATH=$PATH:/opt/openmpi-1.8.1/bin
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/opt/openmpi-1.8.1/lib" >> /home/$USER/.bashrc
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/openmpi-1.8.1/lib
#chmod 600 /home/ec2-user/$PEM_FILE 
#cp /home/ec2-user/$PEM_FILE /home/$USER/.ssh/id_rsa
#chown $USER:$USER  /home/$USER/.ssh/id_rsa
cat /home/ec2-user/.ssh/authorized_keys >> /home/$USER/.ssh/authorized_keys
echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
cd $MAIN_FOLDER
