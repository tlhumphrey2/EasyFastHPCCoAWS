#!/usr/bin/perl
$ThisDir=($0=~/^(.*)\//)? $1 : ".";

$thisDir = ( $0 =~ /^(.+)\// )? $1 : '.';

require "$thisDir/getConfigurationFile.pl";
require "$thisDir/cp2s3_common.pl";

openLog($cp2s3_logname);

($master_pip, @slave_pip)=thor_nodes_ips();
printLog($cp2s3_logname,"In cpToS3.pl. master_pip=\"$master_pip\"\n");

$ThisNodesPip = get_this_nodes_private_ip($cp2s3_logname);
printLog($cp2s3_logname,"In cpToS3.pl. ThisNodesPip=\"$ThisNodesPip\"\n");

if ( $master_pip eq $ThisNodesPip ){
   printLog($cp2s3_logname,"In cpToS3.pl. perl $thisDir/cpLZAndMetadataFilesToS3.pl\n");
   system("perl $thisDir/cpLZAndMetadataFilesToS3.pl");
}
else{
   printLog($cp2s3_logname,"In cpToS3.pl. perl $thisDir/cpAllFilePartsToS3.pl\n");
   system("perl $thisDir/cpAllFilePartsToS3.pl");
}

printLog($cp2s3_logname,"Leaving cpToS3.pl. Done copying files to S3.\n");
close(LOG);
