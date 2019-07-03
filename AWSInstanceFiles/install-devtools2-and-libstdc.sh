echo "Entering install-devtools2-and-libstdc.sh"

echo sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

echo sudo wget http://people.centos.org/tru/devtools-2/devtools-2.repo -O /etc/yum.repos.d/devtools-2.repo
sudo wget http://people.centos.org/tru/devtools-2/devtools-2.repo -O /etc/yum.repos.d/devtools-2.repo

echo "Change /etc/yum.repos.d/devtools-2.repo so all commands are hard coded"
sudo ex /etc/yum.repos.d/devtools-2.repo <<EOFHERE
:1
:.,\$d
:i
[testing-devtools-2-centos-$releasever]
name=testing 2 devtools for CentOS $releasever
baseurl=https://people.centos.org/tru/devtools-2/6/x86_64/RPMS
gpgcheck=0
.
:w
:x
EOFHERE

echo wget http://mirror.centos.org/centos/6/os/x86_64/Packages/libstdc++-4.4.7-23.el6.x86_64.rpm
wget http://mirror.centos.org/centos/6/os/x86_64/Packages/libstdc++-4.4.7-23.el6.x86_64.rpm

echo sudo yum install -y libstdc++-4.4.7-23.el6.x86_64.rpm 
sudo yum install -y libstdc++-4.4.7-23.el6.x86_64.rpm 
