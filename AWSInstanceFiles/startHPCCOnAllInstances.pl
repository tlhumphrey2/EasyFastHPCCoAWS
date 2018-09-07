#!/usr/bin/perl
$ThisDir=($0=~/^(.*)\//)? $1 : ".";
require "$ThisDir/getConfigurationFile.pl";
require "$ThisDir/common.pl";

$mountDisks=0;
# Any command line arguments is a sign that disks need to be mounted.
if ( scalar(@ARGV) > 0 ){
  $mountDisks=1;
}

# Get all private_ips
$master_ip='';
open(IN,$private_ips) || die "Can't open for input: \"$private_ips\"\n";
while(<IN>){
   next if /^\s*$/;
   chomp;
   $esp = $_ if $. == 1;
   $master_ip = $_ if $master_ip=~/^\s*$/;
   push @private_ips, $_;
}
close(IN);

print("chmod 400 $pem\n");
system("chmod 400 $pem");

for( my $i=$#private_ips; $i >= 0; $i--){ 
  my $ip=$private_ips[$i];
  if ( $mountDisks ){
    print("ssh -o StrictHostKeyChecking=no -t -t -i $pem $sshuser\@$ip \"sudo mount /dev/md127 /var/lib/HPCCSystems\"\n");
    system("ssh -o StrictHostKeyChecking=no -t -t -i $pem $sshuser\@$ip \"sudo mount /dev/md127 /var/lib/HPCCSystems\"");
  }
}

if (( $supportnodes <= 1 ) && ( $non_support_instances <= 1 )){
  print "Since there is only one instance, sleep 10 seconds before starting cluster.\n";
  sleep 10;
}

print("ssh -o StrictHostKeyChecking=no -t -t -i $pem $sshuser\@$master_ip \"sudo \/opt\/HPCCSystems\/sbin\/hpcc-run.sh -a hpcc-init start\"\n");
system("ssh -o StrictHostKeyChecking=no -t -t -i $pem $sshuser\@$master_ip \"sudo \/opt\/HPCCSystems\/sbin\/hpcc-run.sh -a hpcc-init start\"");
