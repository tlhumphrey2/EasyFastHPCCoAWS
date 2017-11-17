ThisDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#!/bin/bash
USER=hpcc
MAIN_FOLDER=/home/$USER/rnet-parspray-files
#PEM_FILE=rnet-hpcc-kp.pem


function print_usage
{
 echo "Usage: $0 go"
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
	cp $ThisDir/credentials /home/$USER/.aws/
	chown $USER:$USER /home/$USER/.aws/credentials
fi
sed -i 's/requiretty/!requiretty/g' /etc/sudoers
sudo -u ec2-user $ThisDir/getPublicAndPrivateIps.pl
sed -i '/^$/d' $ThisDir/private_ips.txt
tail -n+2 $ThisDir/private_ips.txt > $MAIN_FOLDER/machines.list
#reverse the order to start from lower IP to higher
sed -i '1!G;h;$!d' $MAIN_FOLDER/machines.list
chmod +x $MAIN_FOLDER/get_*_ip.sh

tar -xzvf $MAIN_FOLDER/openmpi-1.8.1_install.tgz -C /opt/ > /dev/null
echo "export PATH=\$PATH:/opt/openmpi-1.8.1/bin" >> /home/$USER/.bashrc
export PATH=$PATH:/opt/openmpi-1.8.1/bin
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/opt/openmpi-1.8.1/lib" >> /home/$USER/.bashrc
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/openmpi-1.8.1/lib
#chmod 600 $ThisDir/$PEM_FILE 
#cp $ThisDir/$PEM_FILE /home/$USER/.ssh/id_rsa
#chown $USER:$USER  /home/$USER/.ssh/id_rsa
cat $ThisDir/.ssh/authorized_keys >> /home/$USER/.ssh/authorized_keys
echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
cd $MAIN_FOLDER
