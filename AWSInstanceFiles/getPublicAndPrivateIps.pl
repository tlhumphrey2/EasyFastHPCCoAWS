#!/usr/bin/perl
 
require "/home/ec2-user/getConfigurationFile.pl";

 print "Entering getPublicAndPrivateIps.pl\n";
 
 open(IN, $instance_ids) || die "Can't open for input: \"$instance_ids\"\n";
 
 my $private_ips_file="/home/ec2-user/private_ips.txt";
 my $public_ips_file="/home/ec2-user/public_ips.txt";
 open(OUT1,">$private_ips_file") || die "Can't open for output: \"$private_ips_file\"\n";
 open(OUT2,">$public_ips_file") || die "Can't open for output: \"$public_ips_file\"\n";
 
 while(<IN>){
    next if /^#/ || /^\s*$/;
    chomp;
    print "DEBUG: Input from <IN> is \"$_\"\n";
    my $instance_id=$_;
    print "DEBUG: instance_id=\"$instance_id\"\n";
    
    print "local \$_=getInstanceDescription($instance_id, $region);\n";
    local $_=getInstanceDescription($instance_id, $region);
    print "DEBUG: Length of AWS's output is: ",length($_),"\n";
    my $public_ip = $1 if /\"PublicIpAddress\": \"(\d+\.\d+\.\d+\.\d+)\"/;
    my $private_ip = $1 if /\"PrivateIpAddress\": \"(\d+\.\d+\.\d+\.\d+)\"/;
    print "DEBUG: public_ip=\"$public_ip\"\n";
    print "DEBUG: private_ip=\"$private_ip\"\n";
    print OUT1 "$private_ip\n";
    print OUT2 "$public_ip\n";
 }
 
 close(OUT1);
 close(OUT2);
 print "Outputting $public_ips_file\n";
 print "Outputting $private_ips_file\n";
 #=====================================================================
 sub getInstanceDescription{
 my ( $instance_id, $region )=@_;
    my $error=0;
    do{
       $error=0;
       print "AWS COMMAND IS: aws ec2 describe-instances --instance-ids $instance_id --region $region\n\n";
       system("aws ec2 describe-instances --instance-ids $instance_id --region $region &> /home/ec2-user/t");
       $_=`cat /home/ec2-user/t`;
       $error=1 if /Unable to locate credentials/;
       sleep(2) if $error;
    } while ( $error );
 return $_;
 }
 
