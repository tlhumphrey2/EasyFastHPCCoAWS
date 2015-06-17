#!/usr/bin/perl
# This code is executed after installing HPCCSystems on an box.
#
# Note: The following example assumes you are in the directory, ~/BestHoA
#  These 2 assume there are 4 instances
#  startHPCCOnAllInstances.pl ec2-user public_ips.txt tlh_keys_us_west_2.pem
#

require "/home/ec2-user/getConfigurationFile.pl";

# Get all public ips
open(IN,$public_ips) || die "Can't open for input: \"$public_ips\"\n";
while(<IN>){
   next if /^\s*$/;
   chomp;
   $esp = $_ if $. == 1;
   push @public_ips, $_;
}
close(IN);

print("chmod 400 $pem\n");
system("chmod 400 $pem");

#Stop HPCC on all instances.
for( my $i=$#public_ips; $i >= 0; $i--){ 
  my $ip=$public_ips[$i];
  print("ssh -o StrictHostKeyChecking=no -t -t -i $pem ec2-user\@$ip \"sudo service hpcc-init stop\"\n");
  system("ssh -o StrictHostKeyChecking=no -t -t -i $pem ec2-user\@$ip \"sudo service hpcc-init stop\"");
}


