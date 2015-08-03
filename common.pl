#!/usr/bin/perl

$thisDir = ( $0 =~ /^(.+)\// )? $1 : '.';

require "$thisDir/getConfigurationFile.pl";

$ENV{'AWS_ACCESS_KEY_ID'}=$S3_ACCESS_KEY;
$ENV{'AWS_SECRET_ACCESS_KEY'}=$S3_SECRET_KEY;
$ENV{'AWS_DEFAULT_REGION'}=$region;
print "In common.pl AWS_ACCESS_KEY_ID=\"$ENV{AWS_ACCESS_KEY_ID}\"\n";
print "In common.pl AWS_SECRET_ACCESS_KEY=\"$ENV{AWS_SECRET_ACCESS_KEY}\"\n";

#Log and Alert files
$cpfs3_logname = "$thisDir/${stackname}_cpFilesFromS3.log";
$cpfs3_DoneAlertFile = "$thisDir/done_cpFilesFromS3";
$cp2s3_logname = "$thisDir/${stackname}_cpFiles2S3.log";
$cp2s3_DoneAlertFile = "$thisDir/done_cpFiles2S3";
$AlertDoneRestoringLogicalFiles = "$thisDir/done_restoring_logical_files";

#HPCC System folders
$FilePartsFolder='/var/lib/HPCCSystems/hpcc-data';
$DropzoneFolder='/var/lib/HPCCSystems/mydropzone';
$SlaveNodesFile='/var/lib/HPCCSystems/mythor/slaves';     # This file must be on master

#Metadata folder
$MetadataFolder="$thisDir/metadata";

# HPCCSystems paths of interest and utilities.
$hsbin='/opt/HPCCSystems/sbin';
$configgen="$hsbin/configgen";
$hbin='/opt/HPCCSystems/bin';
$dfuplus="/opt/HPCCSystems/bin/dfuplus";
$daliadmin="/opt/HPCCSystems/bin/daliadmin";

print "In common.pl Completed initializing all global variables.\n";

#===================== Subroutines/Functions =======================================
#-----------------------------------------------------------------------------------
sub openLog{
my ( $logname )=@_;

   open my $log_fh, '>>', $logname;
   *STDOUT = $log_fh;
   *STDERR = $log_fh;
   $handler{$logname}=$log_fh;
}
#-----------------------------------------------------------------------------------
sub printLog{
my ( $logname, $text2print )=@_;
  $log_fh = $handler{$logname};
  print STDOUT $text2print;
}
#-----------------------------------------------------------------------------------
sub cp2S3{
my ($logname,$From, $To)=@_;

  printLog($logname,"sudo s3cmd put --recursive $From $To\n");
  system("sudo s3cmd put --recursive $From $To");
}
#-----------------------------------------------------------------------------------
sub setupS3Bucket{
my ($logname,$s3bucket)=@_;

#if s3 bucket, $s3bucket, does not exist, create it.
print("sudo s3cmd ls $s3bucket 2> /tmp/bucket_exists.txt\n");
system("sudo s3cmd ls $s3bucket 2> /tmp/bucket_exists.txt");
if ( `cat /tmp/bucket_exists.txt` =~ /not exist/i ){
   printLog($logname,"sudo s3cmd mb $s3bucket\n");
   system("sudo s3cmd mb $s3bucket");
}
else{
   printLog($logname,"In common.pl::setupS3Bucket. WARNING. s3 bucket, $s3bucket, already EXISTS\nSo, we do not need to create it.\n");
}
}
#-----------------------------------------------------------------------------------
sub unset_aws_env_variables{
  system("unset AWS_ACCESS_KEY_ID;unset AWS_SECRET_ACCESS_KEY;unset AWS_DEFAULT_REGION");
}
#-----------------------------------------------------------------------------------
sub thor_nodes_ips{
  my ($master_pip,@slave_pip);
  my @all=split("\n",`cat $private_ips`);
  my $master_pip = shift @all;
  my $number_of_ips=scalar(@all);

  if ( $number_of_ips == 0 ){
     @slave_pip=($master_pip);
  }
  else{
     @slave_pip=@all[0 .. ($non_support_instances-1)];
  }
return ($master_pip, @slave_pip);
}
#-----------------------------------------------------------------------------------
# This can only be used on the master node
sub get_ordered_thor_slave_ips{
  my ($master_pip,@slave_pip) = thor_nodes_ips();
return @slave_pip;
}
#-----------------------------------------------------------------------------------
sub get_this_nodes_private_ip{
my ($logname)=@_;

  # Get the private ip address of this slave node 
  $_=`ifconfig`;
  my $ThisNodesPip='99.99.99.99';
  $ThisNodesPip = $1 if /inet addr:(\d+\.\d+\.\d+\.\d+)/;
  if ( $ThisNodesPip ne '99.99.99.99' ){
     printLog($logname,"In get_this_nodes_private_ip.pl. ThisNodesPip=\"$ThisNodesPip\"\n");
  }
  else{
     printLog($logname,"In get_this_nodes_private_ip. Could not find ThisNodesPip in ifconfig's output. EXITing\n");
     exit 0;
  }
return $ThisNodesPip;
}
#-----------------------------------------------------------------------------------
sub get_thor_slave_number{
my ($ThisSlaveNodesPip,$slave_pip_ref)=@_;
my @slave_pip = @$slave_pip_ref;

  # Find the private ip address of @slave_pip that matches this
  #  slave node's ip address. When found index, where index begins with 1, into @all_slave_nod_ips will
  #     be $ThisSlaveNodeId.
  my $thor_slave_number='';
  my $FoundThisSlaveNodeId=0;
  for( my $i=0; $i < scalar(@slave_pip); $i++){
     if ( $slave_pip[$i] eq $ThisSlaveNodesPip ){
        $thor_slave_number=$i+1;
        printLog($cpfs3_logname,"In get_thor_slave_number. thor_slave_number=\"$thor_slave_number\"\n");
        $FoundThisSlaveNodeId=1;
        last;
     }
  }  
 
  if ( $FoundThisSlaveNodeId==0 ){
      printLog($cpfs3_logname,"Could not find thor slave number for this slave ($ThisSlaveNodesPip). EXITING without copying file parts to S3.\n");
  }
return $thor_slave_number;
}
#-----------------------------------------------------------------------------------
sub FilesOnThor{
my ( $master_pip )=@_;
  # Get list of files on thor
  my @file=split(/\n/,`$dfuplus server=$master_pip action=list name=*`);
  shift @file;
  if ( scalar(@file)==0 ){
     printLog($cp2s3_logname,"In isFilesOnThor. There are no files on this thor.\n");
  }
return @file;
}
#-----------------------------------------------------------------------------------
sub cpAllFilePartsOnS3{
my ( $thor_folder, $s3folder )=@_;
   printLog($cpfs3_logname,"DEBUG: Entering cpAllFilePartsOnS3. thor_folder=\"$thor_folder\", s3folder=\"$s3folder\"\n");
   my $entries=`sudo s3cmd ls $s3folder --recursive`;

   my @entry=split(/\n/s,$entries);
   @entry = grep(! /^\s*$/,@entry);
   foreach my $e (@entry){
     printLog($cpfs3_logname,"DEBUG: In cpAllFilePartsOnS3. s3 bucket entry=\"$e\"\n");
   }

   my $found_at_least_one_part = 0;
   foreach (@entry){
      # Is this entry a directory?
      if ( s/^\s*DIR\s*// ){
         s/\/\s*$//;
         printLog($cpfs3_logname,"DEBUG: In cpAllFilePartsOnS3. Found DIR \$_=\"$_\"\n");
         my $subfolder = $1 if /\/([^\/]+)\s*$/;
         printLog($cpfs3_logname,"DEBUG: In cpAllFilePartsOnS3. subfolder=\"$subfolder\"\n");
         
         if ( ! -e $thor_folder ){
            printLog($cpfs3_logname,"DEBUG: In cpAllFilePartsOnS3. Saw DIR. system(\"sudo mkdir $thor_folder\")\n");
            system("sudo mkdir $thor_folder"); 
         }
         
         my $newfolder="$thor_folder/$subfolder";
         printLog($cpfs3_logname,"DEBUG: In cpAllFilePartsOnS3. Calling cpAllFilePartsOnS3(\"$newfolder\",\"$_\");\n");
         cpAllFilePartsOnS3($newfolder,$_);
      }
      else{
         $found_at_least_one_part = 1;
      }
   }

   if ( $found_at_least_one_part ){
      printLog($cpfs3_logname,"DEBUG: In cpAllFilePartsOnS3. Found at least one file part. So, copying it from S3 to node.\n");
      if ( ! -e $thor_folder ){
         printLog($cpfs3_logname,"DEBUG: In cpAllFilePartsOnS3. system(\"sudo mkdir $thor_folder\")\n");
         system("sudo mkdir $thor_folder"); 
      }
      printLog($cpfs3_logname,"DEBUG: In cpAllFilePartsOnS3. system(\"cd $thor_folder;sudo s3cmd get $s3folder --recursive\")\n");
      system("cd $thor_folder;sudo s3cmd get $s3folder --recursive > /dev/null 2> /dev/null");
   }
   else{
      printLog($cpfs3_logname,"DEBUG: In cpAllFilePartsOnS3. NO FILE PARTS FOR THE FOLDER, $thor_folder.\n");
   }
   printLog($cpfs3_logname,"DEBUG: Leaving cpAllFilePartsOnS3\n");
}

1;
