#!/usr/bin/perl
#=====================================================================
sub getPublicIPs{
my ($region, @instance_id)=@_;
my @public_ip=();

 foreach my $instance_id (@instance_id){

    print "local \$_=getInstanceDescription($instance_id, $region);\n";
    local $_=getInstanceDescription($instance_id, $region);
#    print "DEBUG: Length of AWS's output is: ",length($_),"\n";
    my $public_ip = $1 if /\"PublicIpAddress\": \"(\d+\.\d+\.\d+\.\d+)\"/;
#    print "DEBUG: public_ip=\"$public_ip\"\n";

    push @public_ip, $public_ip;
 }
#print "Just before leaving getPulicIPs. \@public_ip=(",join(", ",@public_ip),")\n";
return \@public_ip;
}
#=====================================================================
sub getInstanceDescription{
 my ( $instance_id, $region )=@_;
    my $ntrys=4;
    do{
       print "aws ec2 describe-instances --instance-ids $instance_id --region $region\n\n";
       $_=`aws ec2 describe-instances --instance-ids $instance_id --region $region`;
       if ( /Unable to locate credentials|^\s*$/ ){ # This means we couldn't get description.
         sleep(2); # wait 2 seconds then try again.
         $ntrys--;
       }
    } while ( ($ntrys > 0) && (/Unable to locate credentials|^\s*$/) );
    die "FATAL ERROR in getInstanceDescription. Could not get instance descriptions after 4 trys($instance_id, $region)\n" if /Unable to locate credentials|^\s*$/;
 return $_;
}
#=====================================================================
1;
