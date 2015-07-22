#!/usr/bin/perl
require "/home/ec2-user/getConfigurationFile.pl";
 
open(IN, $private_ips) || die "Can't open for input: \"$private_ips\"\n";
 
while(<IN>){
   next if /^#/;
   chomp;
   my $ip=$_;
    
   print("ssh -t -t -o stricthostkeychecking=no -i $pem ec2-user\@$ip \"sudo perl /home/ec2-user/updateSystemFilesForHPCC.pl\"\n");
   system("ssh -t -t -o stricthostkeychecking=no -i $pem ec2-user\@$ip \"sudo perl /home/ec2-user/updateSystemFilesForHPCC.pl\"");
}
