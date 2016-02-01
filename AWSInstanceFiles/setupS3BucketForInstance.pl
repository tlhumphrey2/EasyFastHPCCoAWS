#!/usr/bin/perl

$thisDir = ( $0 =~ /^(.+)\// )? $1 : '.';

require "$thisDir/getConfigurationFile.pl";
require "$thisDir/common.pl";

openLog($cp2s3_logname);

$bucketname=shift @ARGV;
printLog($cp2s3_logname,"In setupS3BucketForInstance.pl. bucketname=\"$bucketname\"\n");
setupS3Bucket($cp2s3_logname,$bucketname);
printLog($cp2s3_logname,"Leaving setupS3BucketForInstances.pl. Done setting-up S3 bucket ($bucketname).\n");
close(LOG);
