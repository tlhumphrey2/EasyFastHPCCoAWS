#!/usr/bin/perl
#cpLAFilesFromS3ToMaster.pl
$ThisDir=($0=~/^(.*)\//)? $1 : ".";

$thisDir = ( $0 =~ /^(.+)\// )? $1 : '.';

require "$thisDir/getConfigurationFile.pl";
require "$thisDir/cp2s3_common.pl";

openLog($cpfs3_logname);

if ( scalar(@ARGV) == 0 ){
   printLog($cpfs3_logname,"In cpLZFilesFromS3ToMaster.pl. EXITING. Mising argument (from_s3_bucket)\n");
   exit 1;
}

$from_s3_bucket = shift @ARGV;
$from_s3_bucket = "s3://$from_s3_bucket" if $from_s3_bucket !~ /^s3:\/\//i;
printLog($cp2s3_logname,"Entering cpLZFilesFromS3ToMaster.pl. from_s3_bucket=\"$from_s3_bucket\"\n");

# Does bucket exists?
system("sudo s3cmd ls $from_s3_bucket 2> /tmp/bucket_exists.txt");
if ( `cat /tmp/bucket_exists.txt` =~ /not exist/i ){
   printLog($cpfs3_logname,"In cpLZFilesFromS3ToMaster.pl. The s3 bucket, $from_s3_bucket, DOES NOT EXISTS.\nEXITing.\n");
   exit 0;
}

#Copy all S3 files of dropzone into mydropzone
system("mkdir $DropzoneFolder") if ! -e $DropzoneFolder;
print("cd $DropzoneFolder;sudo s3cmd get $from_s3_bucket/lz/ --recursive \> /dev/null 2\> /dev/null\n");
system("cd $DropzoneFolder;sudo s3cmd get $from_s3_bucket/lz/ --recursive \> /dev/null 2\> /dev/null");

printLog($cpfs3_logname,"In cpLZFilesFromS3ToMaster.pl. Completed copying from S3 all LZ files.\n");
