#!/usr/bin/perl

$thisDir = ( $0 =~ /^(.+)\// )? $1 : '.';

require "$thisDir/cp2s3_common.pl";

openLog($cpfs3_logname);

($master_pip, @slave_pip)=thor_nodes_ips();
printLog($cpfs3_logname,"In RestoreLogicalFiles.pl. master_pip=\"$master_pip\"\n");

#-------------------------------------------------------------------------------------------------------------
# Change private ips in each file's metadata to the private ips of the current slaves and restore logical file.
#-------------------------------------------------------------------------------------------------------------

if ( opendir(DIR,$MetadataFolder) )
{
      @dir_entry = readdir(DIR);
      closedir(DIR);
      @metadatafile=grep( /\.xml$/,@dir_entry);
      my $nFiles=scalar(@metadatafile);
      printLog($cpfs3_logname,"DEBUG: In RestoreLogicalFiles.pl. There are $nFiles metadata files.\n");
}
else
{
     printLog($cpfs3_logname,"In RestoreLogicalFiles.pl. WARNING: In $0. Couldn't open directory for $MetadataFolder\n");
     exit 0;
}

undef $/;
$comma_separated_slave_ips=join(",",@slave_pip);
foreach my $mfile (@metadatafile){
   # Restore logical file whose physical parts have been loaded to slaves.
   my $filename = $mfile;
   $filename =~ s/\.xml//;
   printLog($cpfs3_logname,"DEBUG: In RestoreLogicalFiles.pl. system(cd $MetadataFolder;$dfuplus server=$master_pip action=add srcxml=$mfile dstname=$filename)\n");
   system("cd $MetadataFolder;$dfuplus server=$master_pip action=add srcxml=$mfile dstname=$filename");

}

system("echo \"done\" > $AlertDoneRestoringLogicalFiles");
printLog($cpfs3_logname,"In RestoreLogicalFiles.pl. Completed logical file restoration.\n");
