#!/usr/bin/perl
=pod
NOTE: This script assumes that memory on all instances is the same.
=cut
$ThisDir=($0=~/^(.*)\//)? $1 : ".";
$ThisDir=`pwd` if $ThisDir eq '.'; chomp $ThisDir;
print "DEBUG: Entering makeEnvironmentFileAndDistribute.pl. ThisDir=\"$ThisDir\"\n";

require "$ThisDir/getConfigurationFile.pl";
require "$ThisDir/cf_common.pl";
require "$ThisDir/common.pl";

#----------------------------------------------------------------------------------
# Generate a new environment.xml file using the inventory file, $ThisDir/my_inventory.yml and the ansible playbook, configHPCC.yml
#----------------------------------------------------------------------------------
$created_environment_file="$ThisDir/my_inventory-environment.xml";
print("cd $ThisDir/ansible-envgen2;/usr/local/bin/ansible-playbook -i $ThisDir/my_inventory.yml configHPCC.yml   --extra-vars \"envtemplate=roles/paas-hpcc-config/templates/tlh_environment.xml.j2 envout=$created_environment_file userhome=/home/$sshuser\";cd /home/$sshuser\n");
system("cd $ThisDir/ansible-envgen2;/usr/local/bin/ansible-playbook -i $ThisDir/my_inventory.yml configHPCC.yml   --extra-vars \"envtemplate=roles/paas-hpcc-config/templates/tlh_environment.xml.j2 envout=$created_environment_file userhome=/home/$sshuser\";cd /home/$sshuser");

#----------------------------------------------------------------------------------
# If username and password is needed for system then do the follow.
#----------------------------------------------------------------------------------
$master_ip=`head -1 $private_ips`; chomp $master_ip;

# IF username and password given THEN setup so system requires them
if (( $system_username ne '' ) && ( $system_password ne '' )){
  #Install HTTPD passwd tool
  print "yum install -y httpd-tools\n";
  system("yum install -y httpd-tools");

  print "htpasswd -cb /etc/HPCCSystems/.htpasswd $system_username $system_password\n";
  system("htpasswd -cb /etc/HPCCSystems/.htpasswd $system_username $system_password");

  # turn on authentication method htpasswed
  print "For $created_environment_file, sed to change method to htpasswd and passwordExpirationWarningDays to 100\n";
  my $rc=`sed "s/method=\"none\"/method=\"htpasswd\"/" $created_environment_file | sed "s/passwordExpirationWarningDays=\"[0-9]*\"/passwordExpirationWarningDays=\"100\"/" > ~/environment_with_htpasswd_enabled.xml`;
  print "$rc\n";

  # copy changed environment file back into $created_environment_file
  print "cp ~/environment_with_htpasswd_enabled.xml $created_environment_file\n";
  system("cp ~/environment_with_htpasswd_enabled.xml $created_environment_file");
}

#----------------------------------------------------------------------------------
# Make sure hpcc platform is installed on all instance BEFORE doing hpcc-push.
#----------------------------------------------------------------------------------
# Before using hpcc-push.sh to copy new environment.xml file, $created_environment_file, to all instances, make
#  sure the hpcc platform is installed on all instances
print("perl $ThisDir/loopUntilHPCCPlatformInstalledOnAllInstances.pl\n");
system("perl $ThisDir/loopUntilHPCCPlatformInstalledOnAllInstances.pl");

# Change new environment.xml file's ownership to hpcc:hpcc
print "chown hpcc:hpcc $created_environment_file\n";
system("chown hpcc:hpcc $created_environment_file");

#----------------------------------------------------------------------------------
# Use /opt/HPCCSystems/sbin/hpcc-push.sh to push new environment.xml file to all instances.
#----------------------------------------------------------------------------------

$out_environment_file="/etc/HPCCSystems/environment.xml";
print("cp -v $created_environment_file $out_environment_file\n");
system("cp -v $created_environment_file $out_environment_file");

HPCCPUSH:
print("/opt/HPCCSystems/sbin/hpcc-push.sh -s $created_environment_file -t $out_environment_file\n");
system("/opt/HPCCSystems/sbin/hpcc-push.sh -s $created_environment_file -t $out_environment_file");

if ( ! -e "/home/$sshuser/envfiles" ){
  mkdir "/home/$sshuser/envfiles";
print "DEBUG: The directory, /home/$sshuser/envfiles, now exists.\n";
}
else{
  system("rm -v /home/$sshuser/envfiles/*");
}

# Put all environment.xml files
$all_private_ips=`cat $private_ips`;chomp $all_private_ips; $all_private_ips=~s/\n+/ /sg;@all_private_ips=split(/\s+/,$all_private_ips);
print "DEBUG: Put all environment.xml files in the directory /home/$sshuser/envfiles. all_private_ips=\"$all_private_ips\".\n";
foreach my $x (@all_private_ips){
print "DEBUG: scp x=\"$x\"\n";
print("scp -i $pem $sshuser\@$x:/etc/HPCCSystems/environment.xml /home/$sshuser/envfiles/environment-$x.xml\n");
system("scp -i $pem $sshuser\@$x:/etc/HPCCSystems/environment.xml /home/$sshuser/envfiles/environment-$x.xml");
}
my $nIPs=scalar(grep(/^\d+(?:\.\d+){3}$/,split(/\n/,`cat $private_ips`)));
print "DEBUG: In makeEnvironmentFileAndDistribute. nIPs=\"$nIPs\"\n";
$nIPs--;
system("tail -$nIPs $private_ips > /home/$sshuser/tail-private_ips.txt");
my $a=`head -1 $private_ips`;chomp $a;
print "DEBUG: a=\"$a\": Compare all environment files to $a.\n";
$all_private_ips=`cat /home/$sshuser/tail-private_ips.txt`;chomp $all_private_ips; $all_private_ips=~s/\n+/ /sg;@all_private_ips=split(/\s+/,$all_private_ips);
foreach my $x (@all_private_ips){
print("diff  /home/$sshuser/envfiles/environment-$a.xml /home/$sshuser/envfiles/environment-$x.xml > /home/$sshuser/envfiles/diff-$a-$x.txt\n");
system("diff  /home/$sshuser/envfiles/environment-$a.xml /home/$sshuser/envfiles/environment-$x.xml > /home/$sshuser/envfiles/diff-$a-$x.txt");
}
$z=`ls -l envfiles/diff*|sed -e "s/^.* $sshuser//" -e "s/^ \([0-9][0-9]*\).*$/\1/"|egrep -v "^0$"`;chomp $z;
my $allmatch=0;
$allmatch=1 if $z =~ /^\s*$/;
goto "HPCCPUSH" if ! $allmatch;

print "DEBUG: environment.xml file was SUCCESSFULLY pushed to all servers.\n";

=pod
# THE FOLLOWING WAS NOT IMPLEMENTED, BUT POSSIBLY SHOULD BE
if [ $slavesPerNode -ne 1 ]
then
   echo "slavesPerNode is greater than 1. So:  execute perl $ThisDir/updateSystemFilesOnAllInstances.pl"
   perl $ThisDir/updateSystemFilesOnAllInstances.pl
else
   echo "slavesPerNode($slavesPerNode) is equal to 1. So did not execute updateSystemFilesOnAllInstances.pl."
fi
=cut
