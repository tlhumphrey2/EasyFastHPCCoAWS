#!/usr/bin/perl
=pod
 Note: The following 2 examples assume you are in the directory, $share/naveens_data
 Use the following if instances are Amazon linux AMIs

 perl updateSystemFilesOnAllInstances.pl public_ips.txt ec2-user tlh_keys_us_west_2.pem
=cut

require "/home/ec2-user/getConfigurationFile.pl";
 
open(IN, $public_ips) || die "Can't open for input: \"$public_ips\"\n";
 
while(<IN>){
   next if /^#/;
   chomp;
   my $ip=$_;
    
   print("ssh -t -t -o stricthostkeychecking=no -i $pem ec2-user\@$ip \"sudo perl /home/ec2-user/updateSystemFilesForHPCC.pl\"\n");
   system("ssh -t -t -o stricthostkeychecking=no -i $pem ec2-user\@$ip \"sudo perl /home/ec2-user/updateSystemFilesForHPCC.pl\"");
}
