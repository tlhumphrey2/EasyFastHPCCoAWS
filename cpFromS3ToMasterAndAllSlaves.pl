#!/usr/bin/perl
# cpFromS3ToMasterAndAllSlaves.pl

$thisDir = ( $0 =~ /^(.+)\// )? $1 : '.';

die "USAGE ERROR: $0 <NAME OF S3 BUCKET TO COPY FROM> (REQUIRED)\n" if scalar(@ARGV) == 0;

# Get the name of the S3 bucket to copy FROM
my $bucket_basename=shift @ARGV;
$bucket_basename = "s3://$bucket_basename" if $bucket_basename !~ /^s3:\/\//i;
print "Bucket that files will come from is: \"$bucket_basename\"\n";

# Make sure the bucket exists. If NOT then EXIT
system("sudo s3cmd ls $bucket_basename 2> /tmp/bucket_basename_exists.txt");
if ( `cat /tmp/bucket_basename_exists.txt` =~ /not exist/i ){
   print("In cpFromS3ToMasterAndAllSlaves.pl. THE S3 BUCKET, $bucket_basename, DOES NOT EXISTS.\nEXITing.\n");
   exit 0;
}
# THE bucket exists. So, put it in the file /home/ec2-user/new_cfg_BestHPCC.sh
else{
   system("s3cmd get $bucket_basename/cfg_BestHPCC.sh /home/ec2-user/new_cfg_BestHPCC.sh");
   print "FROM HPCC's configuration file has been copied from S3 bucket, $bucket_basename, (/home/ec2-user/new_cfg_BestHPCC.sh)\n";
}

#-----------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------
# Make sure the copy FROM HPCC is compatible with the copy TO HPCC.
# This includes: they must have the same number of thor slave instances ($non_support_instances),
#  they must have the same number of thor slaves per instance ($slavesPerNode), and
#  each instance must have enough disk space to hold the files being copied.
#-------------------------------------------------------------------------------
# Instantiate the cfg files environment variables of FROM HPCC
require "$thisDir/getNewConfigurationFile.pl";

$from_slavesPerNode=$slavesPerNode;
$from_non_support_instances=$non_support_instances;
$from_thor_s3_buckets=$thor_s3_buckets;
@from_thor_s3_buckets=split(/,/,$from_thor_s3_buckets);
print "from_slavesPerNode=$from_slavesPerNode, from_non_support_instances=$from_non_support_instances, \@from_thor_s3_buckets=(",join(", ",@from_thor_s3_buckets),")\n";

# Instantiate the cfg files environment variables of TO HPCC
require "$thisDir/getConfigurationFile.pl";
require "$thisDir/common.pl";

#-----------------------------------------------------------------------------------------
# slavesPerNode and non_support_instances of FROM and TO systems must be the same.
#-----------------------------------------------------------------------------------------
die "CANNOT copy files in the s3 bucket, $bucket_basename, because configuration of the FROM HPCC cluster DOES NOT match that of the TO HPCC cluser (from_slavesPerNode=$from_slavesPerNode, slavesPerNode=$slavesPerNode, from_non_support_instances=$from_non_support_instances, non_support_instances=$non_support_instances).\n" 
  if ($from_slavesPerNode != $slavesPerNode) || ($from_non_support_instances != $non_support_instances);

#----------------------------------------------------------------------------------------------
# Make sure there is enough disk space on TO THOR to hold the files of the FROM cluster
#----------------------------------------------------------------------------------------------
#---------------------------
# Get size of each s3 bucket
#---------------------------
my @NeededDiskSpaceOnEachInstance=();
foreach (@from_thor_s3_buckets){
   my $bucket_size=`s3cmd du $_`;
   $bucket_size = $1 if $bucket_size =~ /^(\d+)/;
   push @NeededDiskSpaceOnEachInstance, $bucket_size;
}

#--------------------------------------------------
# Get size of disk on each instance of TO instances
#--------------------------------------------------
@private_ips=split(/\n/,`cat $private_ips`);
print "Private ips=(",join(", ",@private_ips),")\n";
@DiskSpaceOnCurrentInstances=();
foreach my $ip (@private_ips){
   print "my \$d=\`ssh -i $pem ec2-user\@$ip \"lsblk -b|tail -1\"\`\n";
   my $d=`ssh -i $pem ec2-user\@$ip "lsblk -b|tail -1"`;
   $d = (split(/\s+/,$d))[3];
   print "ip=\"$ip\"'s disk space is d=\"$d\"\n";
   push @DiskSpaceOnCurrentInstances, $d;
}

#---------------------------------------
# Check need against what actually exist.
#---------------------------------------
my $isTooSmall=0;
for( my $i=0; $i < scalar(@NeededDiskSpaceOnEachInstance); $i++){
   my $need=$NeededDiskSpaceOnEachInstance[$i];
   my $have=$DiskSpaceOnCurrentInstances[$i];
   print "need=\"$need\", have=\"$have\"\n";
   if ( $have < $need ){
      $isTooSmall=1;
      last;
   }
}

die "CANNOT copy files in the s3 bucket, $bucket_basename, because one or more instances do NOT have enough disk space.\n" 
  if $isTooSmall;
#-----------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------

print "TO SYSTEM IS COMPATIBLE WITH FROM SYSTEM.\n";
print "TO SYSTEM IS COMPATIBLE WITH FROM SYSTEM.\n";
print "TO SYSTEM IS COMPATIBLE WITH FROM SYSTEM.\n";

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

#-------------------------------------------------
# Copy files from S3 bucket to all THOR instances.
#-------------------------------------------------
$ThisSlaveNodesPip = get_this_nodes_private_ip();
print "ThisSlaveNodesPip=\"$ThisSlaveNodesPip\"\n";

# copy files from S3 bucket to HPCC master and slaves (done in parallel)
my $ThisInstanceFound=0;
for( my $i=0; $i <= $non_support_instances; $i++){ # we don't do this to any roxie instances
  my $ip=$private_ips[$i];
  if ( $ip eq $ThisSlaveNodesPip ){
     $ThisInstanceFound=1;
  }
  else{
     print("ssh -f -o stricthostkeychecking=no -t -t -i $pem ec2-user\@$ip \"stty -onlcr;sudo rm -f $cpfs3_DoneAlertFile;sudo perl /home/ec2-user/cpFromS3.pl $from_thor_s3_buckets \&> /home/ec2-user/cpFromS3.log\"\r\n");
     system("ssh -f -o stricthostkeychecking=no -t -t -i $pem ec2-user\@$ip \"stty -onlcr;sudo rm -f $cpfs3_DoneAlertFile;sudo perl /home/ec2-user/cpFromS3.pl $from_thor_s3_buckets &> /home/ec2-user/cpFromS3.log\"");print "\r";
     sleep(1);
  }
}

if ( $ThisInstanceFound ){
     print("sudo perl /home/ec2-user/cpFromS3.pl $from_thor_s3_buckets \&> /home/ec2-user/cpFromS3.log\n\r\n");
     system("sudo perl /home/ec2-user/cpFromS3.pl $from_thor_s3_buckets &> /home/ec2-user/cpFromS3.log");
     sleep(1);
}

loopUntilAllFilesCopiedFromS3();

# Restore Logical Files
system("perl /home/ec2-user/RestoreLogicalFiles.pl");
#----------------------------------------------------
#----------------------------------------------------
sub loopUntilAllFilesCopiedFromS3{

my @private_ips=split("\n",`cat /home/ec2-user/private_ips.txt`);
my $NumberOfInstances=scalar(@private_ips);
#print "Entering loopUntilAllFilesCopiedFromS3. NumberOfInstances=$NumberOfInstances\n";
my @InstanceFilesNotCopiedTo=@private_ips;
my $InstancesCopiedFilesFromS3=0;

do{
#   print "TopOfDOLoop: \@InstanceFilesNotCopiedTo=isFilesCopiedFromS3(",join(",",@InstanceFilesNotCopiedTo),");\n";
   @InstanceFilesNotCopiedTo=isFilesCopiedFromS3(@InstanceFilesNotCopiedTo);
   $InstancesCopiedFilesFromS3=scalar(@private_ips)-scalar(@InstanceFilesNotCopiedTo);
#   print "After isFilesCopiedFromS3. InstancesCopiedFilesFromS3=$InstancesCopiedFilesFromS3\n";
   sleep(1) if $InstancesCopiedFilesFromS3 < $NumberOfInstances;
} while ( $InstancesCopiedFilesFromS3 < $NumberOfInstances );

print "All Files Have Been Copied to S3.\r\n";
}
#----------------------------------------------------
sub isFilesCopiedFromS3{
my ( @InstanceFilesNotCopiedTo )=@_;
  my @not_copied_instances=();

#  print "Entering isFilesCopied: \@InstanceFilesNotCopiedTo=(",join(",",@InstanceFilesNotCopiedTo),");\n";

  # Check every instance to see if files have been copied to S3
  foreach my $ip (@InstanceFilesNotCopiedTo){
#     print "\$_=\`ssh -o stricthostkeychecking=no -i $pem ec2-user\@$ip \"bash /home/ec2-user/done.sh\"\`\n";
     $_=`ssh -o stricthostkeychecking=no -i $pem ec2-user\@$ip "bash /home/ec2-user/done.sh $cpfs3_DoneAlertFile"`;
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
