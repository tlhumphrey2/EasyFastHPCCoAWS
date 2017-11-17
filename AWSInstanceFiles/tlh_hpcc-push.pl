#!/usr/bin/perl
# $ThisDir/tlh_hpcc_push.pl
$ThisDir=($0=~/^(.*)\//)? $1 : ".";
$user=`basename $ThisDir`;chomp $user;
print "In tlh_hpcc-push.pl user=\"$user\"\n";

require "$ThisDir/getConfigurationFile.pl";

$in_environment_file = shift @ARGV;
$out_environment_file = shift @ARGV;

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


system("cp $in_environment_file /home/$user/environment.xml;chown $user:$user /home/$user/environment.xml");
for( my $i=$#private_ips; $i >= 0; $i--){ 
  my $ip=$private_ips[$i];
  print("scp -o stricthostkeychecking=no -i $pem /home/$user/environment.xml $user\@$ip:/home/$user/environment.xml\n");
  system("scp -o stricthostkeychecking=no -i $pem /home/$user/environment.xml $user\@$ip:/home/$user/environment.xml");
  print("ssh -o StrictHostKeyChecking=no -t -t -i $pem $user\@$ip \"sudo chown hpcc:hpcc /home/$user/environment.xml;sudo  mv /home/$user/environment.xml $out_environment_file\"\n");
  system("ssh -o StrictHostKeyChecking=no -t -t -i $pem $user\@$ip \"sudo chown hpcc:hpcc /home/$user/environment.xml;sudo mv /home/$user/environment.xml $out_environment_file\"");
}
