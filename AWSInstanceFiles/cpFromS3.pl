#!/usr/bin/perl

$thisDir = ( $0 =~ /^(.+)\// )? $1 : '.';

require "$thisDir/getConfigurationFile.pl";
require "$thisDir/cp2s3_common.pl";

openLog($cpfs3_logname);

if ( scalar(@ARGV) == 0 ){
   printLog($cpfs3_logname,"In cpFromS3.pl. EXITING. Mising argument (from-thor_s3_bucket)\n");
   exit 1;
}

$from_thor_s3_buckets = shift @ARGV;
@from_thor_s3_buckets=split(/,/,$from_thor_s3_buckets);

($master_pip, @slave_pip)=thor_nodes_ips();
printLog($cpfs3_logname,"In cpFromS3.pl. master_pip=\"$master_pip\"\n");

$ThisNodesPip = get_this_nodes_private_ip($cpfs3_logname);
printLog($cpfs3_logname,"In cpFromS3.pl. ThisNodesPip=\"$ThisNodesPip\"\n");

if ( $master_pip eq $ThisNodesPip ){
   $FromBucket=$from_thor_s3_buckets[0];
   printLog($cpfs3_logname,"In cpFromS3.pl. perl $thisDir/cpLZAndMetadataFilesFromS3ToMaster.pl $FromBucket\n");
   system("perl $thisDir/cpLZAndMetadataFilesFromS3ToMaster.pl $FromBucket");
}
else{
   $thor_slave_number = get_thor_slave_number($ThisNodesPip,\@slave_pip);
   $FromBucket=$from_thor_s3_buckets[$thor_slave_number];
   printLog($cpfs3_logname,"In cpFromS3.pl. perl $thisDir/cpAllFilePartsFromS3ToThisSlaveNode.pl $FromBucket\n");
   system("perl $thisDir/cpAllFilePartsFromS3ToThisSlaveNode.pl $FromBucket");
}

printLog($cpfs3_logname,"Leaving cpFromS3.pl. Done copying files from S3.\n");
close(LOG);
