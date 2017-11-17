#!/usr/bin/perl
$ThisDir=($0=~/^(.*)\//)? $1 : ".";
require "$ThisDir/cp2s3_common.pl";

$ThisNodesPrivateIP=get_this_nodes_private_ip();

require "$ThisDir/getConfigurationFile.pl";

# Get all private_ips
open(IN,$private_ips) || die "Can't open for input: \"$private_ips\"\n";
while(<IN>){
   next if /^\s*$/ || /^\s*#/;
   chomp;
   $esp = $_ if $. == 1;
   push @private_ips, $_;
}
close(IN);

print("chmod 400 $pem\n");
system("chmod 400 $pem");

#Stop HPCC on all instances.
for( my $i=$#private_ips; $i >= 0; $i--){
  my $ip=$private_ips[$i];
  if ( $ThisNodesPrivateIP eq $ip ){
    print("service hpcc-init stop\n");
    system("service hpcc-init stop");
  }
  else{
    print("ssh -o StrictHostKeyChecking=no -t -t -i $pem ec2-user\@$ip \"sudo service hpcc-init stop\"\n");
    system("ssh -o StrictHostKeyChecking=no -t -t -i $pem ec2-user\@$ip \"sudo service hpcc-init stop\"");
  }
}
