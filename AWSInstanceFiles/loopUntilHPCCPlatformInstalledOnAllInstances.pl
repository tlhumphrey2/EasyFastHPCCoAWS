#!/usr/bin/perl
# loopUntilHPCCPlatformInstalledOnAllInstances.pl
$ThisDir=($0=~/^(.*)\//)? $1 : ".";
$cdir=`pwd`;chomp $cdir;
if ( ( $cdir eq '/home/ubuntu' ) || ( $cdir eq '/home/ec2-user' ) ){
}
$sshuser=`basename $ThisDir`;chomp $sshuser;

require "$ThisDir/getConfigurationFile.pl";

loopUntilHPCCPlatformInstalledOnAllInstances();
#----------------------------------------------------
#----------------------------------------------------
sub loopUntilHPCCPlatformInstalledOnAllInstances{

my @private_ips=split("\n",`cat $private_ips`);
my $NumberOfInstances=scalar(@private_ips);
#print "Entering loopUntilHPCCPlatformInstalledOnAllInstances. NumberOfInstances=$NumberOfInstances\n";
my @InstancesPlatformNotInstalled=@private_ips;
my $InstancesPlatformInstalled=0;

do{
#   print "TopOfDOLoop: \@InstancesPlatformNotInstalled=isPlatformInstalled(",join(",",@InstancesPlatformNotInstalled),");\n";
   @InstancesPlatformNotInstalled=isPlatformInstalled(@InstancesPlatformNotInstalled);
   $InstancesPlatformInstalled=scalar(@private_ips)-scalar(@InstancesPlatformNotInstalled);
#   print "After isPlatformInstalled. InstancesPlatformInstalled=$InstancesPlatformInstalled\n";
   sleep(1) if $InstancesPlatformInstalled < $NumberOfInstances;
} while ( $InstancesPlatformInstalled < $NumberOfInstances );

print "HPCC Platform is installed on all instances.\r\n";
}
#----------------------------------------------------
sub isPlatformInstalled{
my ( @InstancesPlatformNotInstalled )=@_;
  my @not_copied_instances=();

#  print "Entering isPlatformInstalled: \@InstancesPlatformNotInstalled=(",join(",",@InstancesPlatformNotInstalled),");\n";

  # Check every instance to see if files have been copied to S3
  foreach my $ip (@InstancesPlatformNotInstalled){
     print "\$_=\`ssh -o stricthostkeychecking=no -t -t -i $pem $sshuser\@$ip \"sudo bash isPlatformInstalled.sh\"\`\n";
     $_=`ssh -o stricthostkeychecking=no -t -t -i $pem $sshuser\@$ip "sudo bash isPlatformInstalled.sh"`;
     if ( /\bNOT installed/ ){
        print "Platform is NOT installed on $ip.\r\n";
        push @not_copied_instances, $ip;
     }
     else{
        print "Platform is installed on $ip.\r\n";
     }
  }
  print "\r\n";

return @not_copied_instances;
}
