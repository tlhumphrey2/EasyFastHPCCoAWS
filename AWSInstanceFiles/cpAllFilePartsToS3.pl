#!/usr/bin/perl

#NOTE: This code is ran on master (esp) ONLY.

$thisDir = ( $0 =~ /^(.+)\// )? $1 : '.';

require "$thisDir/getConfigurationFile.pl";
require "$thisDir/cp2s3_common.pl";

openLog($cp2s3_logname);

printLog($cp2s3_logname,"Entering cpAllFilePartsToS3.pl\n");

($master_pip, @slave_pip)=thor_nodes_ips();
printLog($cp2s3_logname,"In cpAllFilePartsToS3.pl. master_pip=\"$master_pip\", \@slave_pip=(".join(", ",@slave_pip).")\n");

$ThisSlaveNodesPip = get_this_nodes_private_ip();
printLog($cp2s3_logname,"In cpAllFilePartsToS3.pl. ThisSlaveNodesPip=\"$ThisSlaveNodesPip\"\n");

$thor_slave_number = sprintf "%02d",get_thor_slave_number($ThisSlaveNodesPip,\@slave_pip);

$snode = "snode-$thor_slave_number";
$s3bucket = "${ToS3Bucket}-$snode";
printLog($cp2s3_logname,"In cpAllFilePartsToS3.pl. s3bucket=\"$s3bucket\", snode=\"$snode\"\n");

@FilesOnThor = FilesOnThor($master_pip);
printLog($cp2s3_logname,"In cpAllFilePartsToS3.pl. \@FilesOnThor=(".join(", ",@FilesOnThor).")\n");
if ( scalar(@FilesOnThor)==0 ){
   printLog($cp2s3_logname,"In cpAllFilePartsToS3. There are no files on the thor.\nSo EXITing.");
   system("echo \"done\" > $cp2s3_DoneAlertFile");
   exit 0;
}

=pod
# If s3 bucket, $s3bucket, does not exist, create it.
system("sudo s3cmd ls $s3bucket 2> /tmp/bucket_exists.txt");
if ( `cat /tmp/bucket_exists.txt` =~ /not exist/i ){
   system("sudo s3cmd mb $s3bucket");
}
else{
   printLog($cp2s3_logname,"In cpAllFilePartsToS3.pl. s3 bucket, $s3bucket, already EXISTS\nSo, we do not need to create it.\n");
}
=cut

if ( scalar(@FilesOnThor)>0 ){
     printLog($cp2s3_logname,"In cpAllFilePartsToS3.pl. cd $FilePartsFolder;sudo s3cmd put --recursive . $s3bucket\n");
     system("cd $FilePartsFolder;sudo s3cmd put --recursive . $s3bucket");
}
else{
     printLog($cp2s3_logname,"NO File parts to copy to S3.\n");
}

system("echo \"done\" > $cp2s3_DoneAlertFile");
printLog($cp2s3_logname,"In cpAllFilePartsToS3.pl. Done copying file parts to S3.\n");
