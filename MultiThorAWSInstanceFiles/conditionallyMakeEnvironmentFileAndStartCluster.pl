#!/usr/bin/perl
$ThisDir=($0=~/^(.*)\//)? $1 : ".";
$ThisDir=`pwd` if $ThisDir eq '.'; chomp $ThisDir;
print "DEBUG: Entering conditionallyMakeEnvironmentFileAndStartCluster.pl. ThisDir=\"$ThisDir\"\n";
=pod
conditionallyMakeEnvironmentFileAndStartCluster.pl Master
=cut

require "$ThisDir/getConfigurationFile.pl";
require "$ThisDir/cf_common.pl";
require "$ThisDir/common.pl";

die "Usage ERROR: $0 <Master or Slave Or Roxie or Support> (REQUIRED)\n" if scalar(@ARGV)==0;
$ASGType=shift @ARGV;
 print "DEBUG: Entering conditionallyMakeEnvironmentFileAndStartCluster.pl. ASGType=\"$ASGType\"..\n";

$all_ips=`paste $ip_labels $private_ips`;chomp $all_ips;
@all_ips=split(/\n/,$all_ips);
$my_ip=getMyPrivateIP();
@my_label=grep(/\b$my_ip\b/,@all_ips);
die "There are more than 1 (".scalar(@my_label).") label with my ip, $my_ip. THERE SHOULD ONLY BE ONE.\n" if scalar(@my_label) > 1;

my $MakeEnvironmentFileAndStartCluster=0;
if ( $ASGType =~ /Support/ ){
  my @s=grep(/Support/,@all_ips);
  if ($s[0] =~ /\b$my_ip\b/ ){
     $MakeEnvironmentFileAndStartCluster=1;
     print "DEBUG: In conditionallyMakeEnvironmentFileAndStartCluster.pl. This instance, $my_ip, is 1st Support instance. So make environment file and start cluster.\n";
  }
}
elsif ( $ASGType =~ /Master/ ){
  my @m=grep(/Master/,@all_ips);
  my @s=grep(/Support/,@all_ips);
  if (($m[0] =~ /\b$my_ip\b/ ) && (scalar(@s)==0)){
     $MakeEnvironmentFileAndStartCluster=1;
     print "DEBUG: In conditionallyMakeEnvironmentFileAndStartCluster.pl. This instance, $my_ip, is 1st Master instance and there are NO support instances. So make environment file and start cluster.\n";
  }
}

if ( $MakeEnvironmentFileAndStartCluster ){
     # Do makeEnvironmentFileAndDistribute.pl
     print("/home/$sshuser/makeEnvironmentFileAndDistribute.pl\n");
     system("/home/$sshuser/makeEnvironmentFileAndDistribute.pl");

     # Do /opt/HPCCSystems/sbin/hpcc-run.sh -a hpcc-init start
     print("/opt/HPCCSystems/sbin/hpcc-run.sh -a hpcc-init start\n");
     system("/opt/HPCCSystems/sbin/hpcc-run.sh -a hpcc-init start");
     
     # Let Cloud Formation know that stack is complete
     print("/opt/aws/bin/cfn-signal -e 0 --stack $stackname --resource ${ASGType}ASG --region $region\n");
     system("/opt/aws/bin/cfn-signal -e 0 --stack $stackname --resource ${ASGType}ASG --region $region");
}

#=============================================================
sub getMyPrivateIP{
  local $_=`ifconfig`;
  # Find line like: "inet addr:10.60.4.245".
  my $ip_re='\b\d+(?:\.\d+){3}\b';
  my $ip= (/inet(?: addr:)?\s*($ip_re)/s)? $1 : '';
  die "In getPrivateIP. CAN'T FIND PRIVATE IP IN OUTPUT OF 'ifconfig': \"$_\"\n" if $ip eq '';
  return $ip;
}
