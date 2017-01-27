#!/usr/bin/perl
#cpAllFilePartsFromS3ToThisSlaveNode.pl

$thisDir = ( $0 =~ /^(.+)\// )? $1 : '.';

require "$thisDir/getConfigurationFile.pl";
require "$thisDir/cp2s3_common.pl";

openLog($cpfs3_logname);

printLog($cpfs3_logname,"Entering cpAllFilePartsFromS3ToThisSlaveNode.pl\n");

if ( scalar(@ARGV) == 0 ){
   printLog($cpfs3_logname,"In cpAllFilePartsFromS3ToThisSlaveNode.pl. EXITING. Mising argument (from_s3_bucket)\n");
   exit 1;
}

$from_s3_bucket = shift @ARGV;
$from_s3_bucket = "s3://$from_s3_bucket" if $from_s3_bucket !~ /^s3:\/\//i;
printLog($cp2s3_logname,"In cpAllFilePartsFromS3ToThisSlaveNode.pl. from_s3_bucket=\"$from_s3_bucket\"\n");

# Make sure this thor slave's s3 bucket exists. If it doesn't then print a WARNING and exit.
system("sudo s3cmd ls $from_s3_bucket 2> /tmp/bucket_exists.txt");
if ( `cat /tmp/bucket_exists.txt` =~ /not exist/i ){
   printLog($cpfs3_logname,"In cpAllFilePartsFromS3ToThisSlaveNode.pl. WARNING. The s3 bucket, $from_s3_bucket, DOES NOT EXISTS. EXITing.\n");
   system("echo \"done\" > $cpfs3_DoneAlertFile");
   exit 0;
}

if ( ! -e $FilePartsFolder ){
   print("FilePartsFolder=\"$FilePartsFolder\" DOES NOT EXIST. sudo mkdir $FilePartsFolder\n");
   system("sudo mkdir $FilePartsFolder");
   print("sudo chown hpcc:hpcc $FilePartsFolder\n");
   system("sudo chown -R hpcc:hpcc $FilePartsFolder");
}

# Copy all file part on $from_s3_bucket into $FilePartsFolder
printLog($cpfs3_logname,"DEBUG: In cpAllFilePartsFromS3ToThisSlaveNode. system(\"cd $FilePartsFolder;sudo s3cmd get $from_s3_bucket --recursive\")\n");
system("cd $FilePartsFolder;sudo s3cmd get $from_s3_bucket --recursive > /dev/null 2> /dev/null");
print("sudo chown hpcc:hpcc $FilePartsFolder\n");
system("sudo chown -R hpcc:hpcc $FilePartsFolder");

# Let everyone know this node has completed copying file parts from S3 to node.
system("echo \"done\" > $cpfs3_DoneAlertFile");
