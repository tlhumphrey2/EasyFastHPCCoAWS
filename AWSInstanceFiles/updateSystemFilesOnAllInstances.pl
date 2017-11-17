#!/usr/bin/perl
$ThisDir=($0=~/^(.*)\//)? $1 : ".";
$user=`basename $ThisDir`;chomp $user;
print "In tlh_hpcc-push.pl user=\"$user\"\n";
require "$ThisDir/getConfigurationFile.pl";
 
open(IN, $private_ips) || die "Can't open for input: \"$private_ips\"\n";
 
while(<IN>){
   next if /^#/;
   chomp;
   my $ip=$_;
    
   print("ssh -t -t -o stricthostkeychecking=no -i $pem $user\@$ip \"sudo perl $ThisDir/updateSystemFilesForHPCC.pl\"\n");
   system("ssh -t -t -o stricthostkeychecking=no -i $pem $user\@$ip \"sudo perl $ThisDir/updateSystemFilesForHPCC.pl\"");
}
