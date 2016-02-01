#!/usr/bin/perl

print "ENTERING startCassandraOnAllInstances.pl\n";

require "/home/ec2-user/getConfigurationFile.pl";

# Get all private_ips
open(IN,$private_ips) || die "Can't open for input: \"$private_ips\"\n";
while(<IN>){
   next if /^\s*$/;
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
  print("ssh -o StrictHostKeyChecking=no -t -t -i $pem ec2-user\@$ip \"sudo service cassandra start;sleep 100h\"\&\n");
  system("ssh -o StrictHostKeyChecking=no -t -t -i $pem ec2-user\@$ip \"sudo service cassandra start;sleep 100h\"&");
}

print "LEAVING startCassandraOnAllInstances.pl\n";
