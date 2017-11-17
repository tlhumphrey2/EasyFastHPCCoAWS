#!/usr/bin/perl
$ThisDir=($0=~/^(.*)\//)? $1 : ".";

# Ran ONLY on master (esp)

$thisDir = ( $0 =~ /^(.+)\// )? $1 : '.';

require "$thisDir/getConfigurationFile.pl";
require "$thisDir/cp2s3_common.pl";

openLog($cp2s3_logname);

printLog($cp2s3_logname,"Entering cpLZAndMetadataFilesToS3.pl\n");

($master_pip, @slave_pip)=thor_nodes_ips();
printLog($cp2s3_logname,"In cpLZAndMetadataFilesToS3.pl. master_pip=\"$master_pip\"\n");

$s3bucket = "${ToS3Bucket}-master";
$s3bucket = "s3://$s3bucket" if $s3bucket !~ /^s3:\/\//;
printLog($cp2s3_logname,"In cpLZAndMetadataFilesToS3.pl. s3bucket=\"$s3bucket\"\n");

#Check for files on this THOR
@FilesOnThor = FilesOnThor($master_pip);
printLog($cp2s3_logname, "\@FilesOnThor=(".join(", ",@FilesOnThor).").\n");

@FilesOnThor = FilesOnThor($master_pip);
printLog($cp2s3_logname, "\@FilesOnThor=(".join(", ",@FilesOnThor).").\n");

#-------------------------------------------------------------------------------------------
# Put mydropzone files out to $s3bucket.
#-------------------------------------------------------------------------------------------
if ( $CopyLZFiles ){
  # check for files on dropzone
  system("ls -l $DropzoneFolder > /tmp/dropzone-files.txt");
  if ( `cat /tmp/dropzone-files.txt` !~ /\btotal\s+0\b/is ){
    #Copy all files on dropzone into S3.
    printLog($cp2s3_logname,"cp2S3($cp2s3_logname,\"$DropzoneFolder/*\",\"$s3bucket/lz/\")\n");
    cp2S3($cp2s3_logname,"$DropzoneFolder/*","$s3bucket/lz/");
  }
}

#-------------------------------------------------------------------------------------------
# Put metadata for all files on mythor out to $s3bucket. Plus, copy files of LZ to $s3bucket.
#-------------------------------------------------------------------------------------------

if (scalar(@FilesOnThor) > 0 ){
# Make a folder for metadata files
  mkdir $MetadataFolder if ! -e $MetadataFolder;
  
  #For each of the above files, get and put its metadata in ~/metadata
  printLog($cp2s3_logname,"Get metadata file for: ".join("\nGet metadata file for: ",@FilesOnThor)."\n");
  foreach (@FilesOnThor){
     s/^\.:://;
     printLog($cp2s3_logname,"sudo $dfuplus server=$master_pip action=savexml srcname=$_ dstxml=$MetadataFolder/$_.xml\n");
     system("sudo $dfuplus server=$master_pip action=savexml srcname=$_ dstxml=$MetadataFolder/$_.xml");
  }
  printLog($cp2s3_logname,"Completed getting metadata for files.\n");

  #Copy all metadata to $s3bucket/metadata
  printLog($cp2s3_logname,"cp2S3($cp2s3_logname,\"$MetadataFolder/*\",\"$s3bucket/metadata/\")\n");
  cp2S3($cp2s3_logname,"$MetadataFolder/*","$s3bucket/metadata/");
}
else{
   printLog($cp2s3_logname,"In cpLZAndMetadataFilesToS3.pl. There are no files on the thor.\n");
}

system("echo \"done\" > $cp2s3_DoneAlertFile");
printLog($cp2s3_logname,"Done copying files to S3\n");
