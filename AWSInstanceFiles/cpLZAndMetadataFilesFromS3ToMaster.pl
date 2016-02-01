#!/usr/bin/perl
# cpLZAndMetadataFilesFromS3ToMaster.pl

$thisDir = ( $0 =~ /^(.+)\// )? $1 : '.';

require "$thisDir/getConfigurationFile.pl";
require "$thisDir/common.pl";

openLog($cpfs3_logname);

printLog($cpfs3_logname,"Entering cpLZAndMetadataFilesFromS3ToMaster.pl\n");

if ( scalar(@ARGV) == 0 ){
   printLog($cpfs3_logname,"In cpLZAndMetadataFilesFromS3ToMaster.pl. EXITING. Mising argument (from_s3_bucket)\n");
   exit 1;
}

$from_s3_bucket = shift @ARGV;
$from_s3_bucket = "s3://$from_s3_bucket" if $from_s3_bucket !~ /^s3:\/\//i;
printLog($cp2s3_logname,"In cpAllFilePartsFromS3ToThisSlaveNode.pl. from_s3_bucket=\"$from_s3_bucket\"\n");

if ( $CopyLZFiles ){
  printLog($cpfs3_logname,"In cpLZAndMetadataFilesFromS3ToMaster.pl. perl $thisDir/cpLZFilesFromS3ToMaster.pl $from_s3_bucket\n");
  system("perl $thisDir/cpLZFilesFromS3ToMaster.pl $from_s3_bucket");
}

printLog($cpfs3_logname,"In cpLZAndMetadataFilesFromS3ToMaster.pl. perl $thisDir/cpMetadataFilesFromS3ToNode.pl $from_s3_bucket\n");
system("perl $thisDir/cpMetadataFilesFromS3ToNode.pl $from_s3_bucket");

system("echo \"done\" > $cpfs3_DoneAlertFile");
printLog($cpfs3_logname,"In cpLZAndMetadataFilesFromS3ToMaster.pl. All copies from S3 completed.\n");

