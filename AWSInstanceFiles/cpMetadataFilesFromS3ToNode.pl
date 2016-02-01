#!/usr/bin/perl
#cpMetadataFilesFromS3ToNode.pl

$thisDir = ( $0 =~ /^(.+)\// )? $1 : '.';

require "$thisDir/getConfigurationFile.pl";
require "$thisDir/common.pl";

openLog($cpfs3_logname);

if ( scalar(@ARGV) == 0 ){
   printLog($cpfs3_logname,"In cpMetadataFilesFromS3ToNode.pl. EXITING. Mising argument (from_s3_bucket)\n");
   exit 1;
}

$from_s3_bucket = shift @ARGV;
$from_s3_bucket = "s3://$from_s3_bucket" if $from_s3_bucket !~ /^s3:\/\//i;
printLog($cp2s3_logname,"Entering cpMetadataFilesFromS3ToNode.pl. from_s3_bucket=\"$from_s3_bucket\"\n");

#Does bucket exists?
system("sudo s3cmd ls $from_s3_bucket 2> /tmp/bucket_exists.txt");
if ( `cat /tmp/bucket_exists.txt` =~ /not exist/i ){
   printLog($cpfs3_logname,"In cpMetadataFilesFromS3ToNode.pl. The s3 bucket, $from_s3_bucket, DOES NOT EXISTS.\nEXITing.\n");
   exit 0;
}

#Copy metadata files from S3 to $MetadataFolder of $ThisNodePip
system("mkdir $MetadataFolder") if ! -e "$MetadataFolder";
print("cd $thisDir;sudo s3cmd get $from_s3_bucket/metadata --recursive 2\> /dev/null \> /dev/null\n");
system("cd $thisDir;sudo s3cmd get $from_s3_bucket/metadata --recursive 2> /dev/null > /dev/null");

#-------------------------------------------------------------------------------------------------------------
# Change private ips in each file's metadata to the private ips of the TO slaves.
#-------------------------------------------------------------------------------------------------------------

# Get the names of all metadata xml files
if ( opendir(DIR,$MetadataFolder) )
{
      @dir_entry = readdir(DIR);
      closedir(DIR);
      @metadatafile=grep( /\.xml$/,@dir_entry); # Get the names of ONLY the metadata xml files
      my $NumberMetadataFiles=scalar(@metadatafile);
      printLog($cpfs3_logname,"DEBUG: In cpMetadataFilesFromS3ToNode.pl. There are $NumberMetadataFiles metadata files.\n");
}
else
{
     printLog($cpfs3_logname,"In cpMetadataFilesFromS3ToNode.pl. ERROR: In $0. Couldn't open directory for \"$MetadataFolder\"\n");
     exit 1;
}

@slave_pip = get_ordered_thor_slave_ips();

# Change thor slave IPs in metadata xml files to current IPs, i.e. @slave_pip.
$comma_separated_slave_ips=makeIPGroup();
printLog($cpfs3_logname,"DEBUG: In cpMetadataFilesFromS3ToNode.pl. comma_separated_slave_ips=\"$comma_separated_slave_ips\"\n");
undef $/; # Make line/record delimiter NULL so read brings in whole file.
foreach my $mfile (@metadatafile){
   printLog($cpfs3_logname,"DEBUG: In cpMetadataFilesFromS3ToNode.pl. Open metadata file: $mfile.\n");
   open(IN,"$MetadataFolder/$mfile") || die "Can't open for input metadata file: \"$mfile\"";
   local $_=<IN>;
   close(IN);

   printLog($cpfs3_logname,"DEBUG: In cpMetadataFilesFromS3ToNode.pl. In $mfile, change <Group> private ips.\n");
   s/<Group>.+?<\/Group>/<Group>$comma_separated_slave_ips<\/Group>/s;
   open(OUT,">$MetadataFolder/t") || die "Can't open for output metadata file: \"t\"\n";
   print OUT $_;
   close(OUT);
   printLog($cpfs3_logname,"DEBUG: In cpMetadataFilesFromS3ToNode.pl. system(\"mv -f $MetadataFolder/t $MetadataFolder/$mfile\")\n");
   print("mv -f $MetadataFolder/t $MetadataFolder/$mfile\n");
   system("mv -f $MetadataFolder/t $MetadataFolder/$mfile");
}

printLog($cpfs3_logname,"In cpMetadataFilesFromS3ToNode.pl. Completed copying from S3 metadata files to node and changing slave ips of them.\n");
#=======================================================================
sub makeIPGroup{
  $[=1;
  my @SlaveIPs=reverse @slave_pip;
  # Fill array with IPs starting with last one first.
  # Slave IPs are stored in @SlaveIPs. The order: last slave ip is first in @SlaveIPs.
  my @IPsByNodeNumber=();
  my $nSlaves=$non_support_instances*$slavesPerNode;
  for( $i=1; $i <= $nSlaves; $i++){
     my $j= $i % $non_support_instances;
     $IPsByNodeNumber[$i] = $SlaveIPs[$j]; 
  }
  $[=0;
  return join(",",@IPsByNodeNumber);
}
