#!/usr/bin/perl

require "/home/ec2-user/getConfigurationFile.pl";

$mountDisks=0;
# Any command line arguments is a sign that disks need to be mounted.
if ( scalar(@ARGV) > 0 ){
  $mountDisks=1;
}

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
  if ( $mountDisks ){
    print("ssh -o StrictHostKeyChecking=no -t -t -i $pem ec2-user\@$ip \"sudo mount /dev/md127 /var/lib/HPCCSystems\"\n");
    system("ssh -o StrictHostKeyChecking=no -t -t -i $pem ec2-user\@$ip \"sudo mount /dev/md127 /var/lib/HPCCSystems\"");
  }
  print("ssh -o StrictHostKeyChecking=no -t -t -i $pem ec2-user\@$ip \"sudo service hpcc-init start\"\n");
  system("ssh -o StrictHostKeyChecking=no -t -t -i $pem ec2-user\@$ip \"sudo service hpcc-init start\"");
}


