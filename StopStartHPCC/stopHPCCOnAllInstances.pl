#!/usr/bin/perl

$ThisDir=($0 =~ /^(.+)[\\\/]/)? $1 : "." ;
require "$ThisDir/ClusterInitVariables.pl";

$action="stop";
# Get all private_ips
open(IN,"$ThisDir/$private_ips_file") || die "Can't open for input: \"$ThisDir/$private_ips_file\"\n";
while(<IN>){
   next if /^\s*$/;
   chomp;
   $esp = $_ if $. == 1;
   push @private_ips, $_;
}
close(IN);

print("chmod 400 $pem\n");
system("chmod 400 $pem");

#Start HPCC on all instances.
my $ip=$private_ips[0];
print("ssh -o StrictHostKeyChecking=no -t -t -i $pem $sshuser\@$ip \"sudo /opt/HPCCSystems/sbin/hpcc-run.sh -a hpcc-init $action\"\n");
my $rc=`ssh -o StrictHostKeyChecking=no -t -t -i $pem $sshuser\@$ip "sudo /opt/HPCCSystems/sbin/hpcc-run.sh -a hpcc-init $action"`;
print $rc;
#------------------------------------------
sub waitUntilAlive{
my ( $ip, $tries )=@_;
 my $saved_tries=$tries;
 my $rc=0;
  print "ping -c 1 $ip\n";
  local $_=`ping -c 1 $ip`;
  while ( ! /[1-9] received/s && ($tries>0) ){
    print "ping FAILED for ip=\"$ip\". Waiting until it works.\n";
    print "ping -c 1 $ip\n";
    $_=`ping -c 1 $ip`;
    $tries--;
  }

  if ( $tries <= 0 ){
     die "$saved_tries tries at pinging $ip. Still NOT alive.\n";
  }
}
