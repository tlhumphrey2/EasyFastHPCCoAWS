#!/usr/bin/perl
# cp2S3FromMasterAndAllSlaves.pl

$thisDir = ( $0 =~ /^(.+)\// )? $1 : '.';

require "$thisDir/getConfigurationFile.pl";
require "$thisDir/common.pl";

if ( scalar(@ARGV) > 0 ){
  $ToS3Bucket=shift @ARGV;
  $ToS3Bucket = "s3://$ToS3Bucket" if $ToS3Bucket !~ /^s3:\/\//i;
  print "Input, as an argument, was ToS3Bucket=\"$ToS3Bucket\"\n";
  # To cfg_BestHPCC.sh, add environment variable, ToS3Bucket.
  system("echo \"\nToS3Bucket=$ToS3Bucket\" >> /home/ec2-user/cfg_BestHPCC.sh");
}

#------------------------------
# Get all private ips
#------------------------------
open(IN,$private_ips) || die "Can't open for input: \"$private_ips\"\n";
while(<IN>){
   next if /^\s*$/;
   chomp;
   $esp = $_ if $. == 1;
   push @private_ips, $_;
}
close(IN);

die "FATAL ERROR: $0. The environment variable, ToS3Bucket, does not have a value and it must. ToS3Bucket should have the name of the S3 bucket that files will be copied to, e.g. s3://hpcc-example-backup\n" if $ToS3Bucket =~ /^\s*$/;

my $bucket_basename=$ToS3Bucket;
$bucket_basename = "s3://$bucket_basename" if $bucket_basename !~ /^s3:\/\//;
print("In cp2S3FromMasterAndAllSlaves.pl. bucket_basename=\"$bucket_basename\", non_support_instances=$non_support_instances\n");

#-----------------------------------------------------------------------------------------------------------------------------
# Setup S3 buckets (one named after stackname which contains cfg_BestHPCC.sh; then one for each THOR instance)
#-----------------------------------------------------------------------------------------------------------------------------
$user="ec2-user";
# Setup S3 buckets for all THOR instances.
my @bucketname=();
for( my $i=0; $i <= $non_support_instances; $i++){ # we don't do this to any roxie instances
  my $ip=$private_ips[$i];
  my $bucketname = ( $i==0 )? "${bucket_basename}-master" : sprintf "${bucket_basename}-snode-%02d",$i;
  push @bucketname, $bucketname;
  print("sudo perl /home/ec2-user/setupS3BucketForInstance.pl $bucketname\n");
  system("sudo perl /home/ec2-user/setupS3BucketForInstance.pl $bucketname");
  sleep(1);
}

#-------------------------------------------------
# Copy files from all THOR instances to S3 buckets.
#-------------------------------------------------
$ThisSlaveNodesPip = get_this_nodes_private_ip();

# copy files from HPCC master and slaves to S3 bucket (these are done in parallel)
my $ThisInstanceFound=0;
for( my $i=0; $i <= $non_support_instances; $i++){ # we don't do this to any roxie instances
  my $ip=$private_ips[$i];
  if ( $ip eq $ThisSlaveNodesPip ){
     $ThisInstanceFound=1;
  }
  else{
     print("ssh -f -o stricthostkeychecking=no -t -t -i $pem $user\@$ip \"stty -onlcr;sudo rm -f $cp2s3_DoneAlertFile;sudo perl /home/ec2-user/cpToS3.pl \&> /home/ec2-user/cpToS3.log\"\r\n");
     system("ssh -f -o stricthostkeychecking=no -t -t -i $pem $user\@$ip \"stty -onlcr;sudo rm -f $cp2s3_DoneAlertFile;sudo perl /home/ec2-user/cpToS3.pl &> /home/ec2-user/cpToS3.log\"");print "\r";
     sleep(1);
  }
}

if ( $ThisInstanceFound ){
     print("sudo perl /home/ec2-user/cpToS3.pl \&> /home/ec2-user/cpToS3.log\n\r\n");
     system("sudo perl /home/ec2-user/cpToS3.pl &> /home/ec2-user/cpToS3.log");
     sleep(1);
}

#---------------------------------------------------------------------
# To cfg_BestHPCC.sh, add FromS3Bucket and thor_s3_buckets
#---------------------------------------------------------------------
# To cfg_BestHPCC.sh, add environment variable, FromS3Bucket.
system("echo \"FromS3Bucket=$bucket_basename\" >> /home/ec2-user/cfg_BestHPCC.sh");

# To cfg_BestHPCC.sh, add environment variable, thor_s3_buckets, which is a comma separated list of buckets.
$thor_s3_buckets=join(",",@bucketname);
system("echo \"thor_s3_buckets=$thor_s3_buckets\" >> /home/ec2-user/cfg_BestHPCC.sh");

#---------------------------------------------------------------------
# Make the S3 bucket, $bucket_basename and put in it, cfg_BestHPCCC.sh.
#---------------------------------------------------------------------
# Setup/make bucket, $bucket_basename
print("sudo perl /home/ec2-user/setupS3BucketForInstance.pl $bucket_basename\n");
system("sudo perl /home/ec2-user/setupS3BucketForInstance.pl $bucket_basename");

# Put cfg_BestHPCC.sh in the bucket, $bucket_basename
print("sudo s3cmd put /home/ec2-user/cfg_BestHPCC.sh $bucket_basename\n");
system("sudo s3cmd put /home/ec2-user/cfg_BestHPCC.sh $bucket_basename");

loopUntilAllFilesCopiedToS3();
#----------------------------------------------------
#----------------------------------------------------
sub loopUntilAllFilesCopiedToS3{

my @private_ips=split("\n",`cat /home/ec2-user/private_ips.txt`);
my $NumberOfInstances=scalar(@private_ips);
#print "Entering loopUntilAllFilesCopiedToS3. NumberOfInstances=$NumberOfInstances\n";
my @InstanceFilesNotCopied=@private_ips;
my $InstancesCopiedFiles2S3=0;

do{
   @InstanceFilesNotCopied=isFilesCopiedToS3(@InstanceFilesNotCopied);
   $InstancesCopiedFiles2S3=scalar(@private_ips)-scalar(@InstanceFilesNotCopied);
   sleep(1) if $InstancesCopiedFiles2S3 < $NumberOfInstances;
} while ( $InstancesCopiedFiles2S3 < $NumberOfInstances );

print "All Files Have Been Copied to S3.\r\n";
}
#----------------------------------------------------
sub isFilesCopiedToS3{
my ( @InstanceFilesNotCopied )=@_;
  my @not_copied_instances=();


  # Check every instance to see if files have been copied to S3
  foreach my $ip (@InstanceFilesNotCopied){
     $_=`ssh -o stricthostkeychecking=no -i $pem ec2-user\@$ip "bash /home/ec2-user/done.sh $cp2s3_DoneAlertFile"`;
     if ( /not done/ ){
        print "$ip has NOT copied its files to S3.\r\n";
        push @not_copied_instances, $ip;
     }
     else{
        print "$ip has copied its files to S3.\r\n";
     }
  }
  print "\r\n";

return @not_copied_instances;
}
