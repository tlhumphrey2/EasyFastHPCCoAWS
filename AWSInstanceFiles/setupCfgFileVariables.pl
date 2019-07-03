#!/usr/bin/perl
=pod
sudo ./setupCfgFileVariables.pl -clustercomponent Master -stackname $stackname -region $region -pem $pem -channels $channels -eip 52.210.2.55 &> setupCfgFileVariables.log
=cut
# THIS PROGRAM adds lines to cfg_BestHPCC.sh and creates these 3 files: instance_ids.txt, public_ips.txt, and private_ips.txt
$ThisDir=($0=~/^(.*)\//)? $1 : ".";
print "DEBUG: Entering setupCfgFileVariables.pl. ThisDir=\"$ThisDir\"\n";

require "$ThisDir/getConfigurationFile.pl";
require "$ThisDir/cf_common.pl";
require "$ThisDir/common.pl";

# Default values for some configuration variables
require "$ThisDir/CfgFileVariables.pl";

# Initialize %ValueOfCfgVariable with the default value of each cfg variable
%ValueOfCfgVariable=();
foreach my $cfgvar (keys %DefaultValuesOfCfgVariables){
   $ValueOfCfgVariable{$cfgvar}=$DefaultValuesOfCfgVariables{$cfgvar};
}

#================== Get Input Arguments ================================
require "$ThisDir/newgetopt.pl";
if ( ! &NGetOpt(
                "clustercomponent=s", "sshuser=s", "stackname=s", "region=s", "pem=s", "channels=s","eip=s"
                ))      # Add Options as necessary
{
  print STDERR "\n[$0] -- ERROR -- Invalid/Missing options...\n\n";
  exit(1);
}

$clustercomponent=$opt_clustercomponent || die "FATAL USAGE ERROR: $0 MUST HAVE CLUSTER COMPONENT AS ARGUMENT\n";
$ValueOfCfgVariable{'ThisClusterComponent'}=$clustercomponent;
$sshuser=$opt_sshuser || 'ec2-user';
$ValueOfCfgVariable{'sshuser'}=$sshuser;
$stackname=$opt_stackname || die "FATAL ERROR: In setupCfgFileVariables.pl. stackname WAS NOT GIVEN (REQUIRED)";
$ValueOfCfgVariable{'stackname'}=$stackname;
$region=$opt_region || die "FATAL ERROR: In setupCfgFileVariables.pl. region WAS NOT GIVEN (REQUIRED)";
$ValueOfCfgVariable{'region'}=$region;
$eip=$opt_eip || getEIPFromS3Bucket();
$ValueOfCfgVariable{'EIPAllocationId'}=$eip;
$pem=$opt_pem || getPemFileFromS3Bucket();
$ValueOfCfgVariable{'pem'}="$ThisDir/$pem.pem";
$channelsPerSlave=$opt_channels || "1";
$ValueOfCfgVariable{'channelsPerSlave'}=$channelsPerSlave;
print "Entering setupCfgFileVariables.pl. Inputted arguments are: sshuser=\"$sshuser\", stackname=\"$stackname\", region=\"$region\", pem=\"$pem\", channelsPerSlave=\"$channelsPerSlave\"\n";
foreach my $k (sort keys %ValueOfCfgVariable){
  print "DEBUG: In setupCfgFileVariables.pl. After getting parameters. ValueOfCfgVariable{$k}=\"$ValueOfCfgVariable{$k}\"\n";
}
#===============END Get Input Arguments ================================

if ( !-e "$ThisDir/$pem.pem" ){
  $pem=getPemFileFromS3Bucket();
}

$email=getEmailFileFromS3Bucket();
$ValueOfCfgVariable{'email'}=$email;

my $lc_stackname=$stackname; $lc_stackname =~ s/([A-Z]+)/\L$1/g;
$ValueOfCfgVariable{'bucket_name'}=$lc_stackname;
print "DEBUG: \$ValueOfCfgVariable{bucket_name}=$InstanceVariable{'bucket_name'}\n";

#--------------------------------------------------------------------------------
# Get any configuration variables, and their values, in the instance descriptions.
#--------------------------------------------------------------------------------
my @sorted_InstanceInfo=InstanceVariablesFromInstanceDescriptions($region,$stackname);

$OutputOnceVariables{"HPCCPlatform"}=1;
$OutputOnceVariables{"pem"}=1;
$OutputOnceVariables{"roxienodes"}=1;
$OutputOnceVariables{"slavesPerNode"}=1;

my %InstanceVariable=%{$sorted_InstanceInfo[1]};
print "DEBUG: Instance Variables outputted once (ie. NOT arrays):\n";
foreach (sort keys %OutputOnceVariables){
  $InstanceVariable{$_} = '$ThisDir/'.$InstanceVariable{$_}.'.pem' if $_ eq 'pem';
  print "DEBUG: \$ValueOfCfgVariable{$_}=$InstanceVariable{$_}\n";

  $ValueOfCfgVariable{$_}=$InstanceVariable{$_};
}
#-------------------------------------------------------------------------------------
# END Get any configuration variables, and their values, in the instance descriptions.
#-------------------------------------------------------------------------------------

# Put information about each HPCC instance in files (file names in configuration, $ThisDir/cfg_BestHPCC.sh)
putHPCCInstanceInfoInFiles(\@sorted_InstanceInfo);

@nodetypes=split(/\n/,`cat $nodetypes`); @nodetypes=grep(!/^\s*$/,@nodetypes);
print "WARNING. In $0. Master's instance id, private_ip, public_ip, and nodetypes was NOT the 1st and MUST BE.\n" if $nodetypes[0] ne 'Master';

#------------------------------------------------------------------------------------
# Adjust 'non_support_instances' and put all config values in cfg_BestHPCC.sh 
#------------------------------------------------------------------------------------
# Get number of instances
@InstanceIds=split(/\n/,`cat $instance_ids`); @InstanceIds=grep(!/^\s*$/,@InstanceIds);
$nInstances=scalar(@InstanceIds);
print "DEBUG: nInstances=\"$nInstances\"\n";

$ValueOfCfgVariable{'supportnodes'}=$DefaultValuesOfCfgVariables{'supportnodes'};
if (($nInstances>0) && ($nInstances<=2)){
   $ValueOfCfgVariable{'non_support_instances'}=1;
   print "DEBUG: nInstances is gt 0 and le 2. nInstances=\"$nInstances\", ValueOfCfgVariable{'supportnodes'}=\"$ValueOfCfgVariable{'supportnodes'}\", ValueOfCfgVariable{'non_support_instances'}=\"$ValueOfCfgVariable{'non_support_instances'}\"\n";
}
else{
   $ValueOfCfgVariable{'non_support_instances'} = $nInstances - $ValueOfCfgVariable{'supportnodes'} - $ValueOfCfgVariable{'roxienodes'};
   print "DEBUG: nInstances is gt 2. nInstances=\"$nInstances\", ValueOfCfgVariable{'supportnodes'}=\"$ValueOfCfgVariable{'supportnodes'}\", ValueOfCfgVariable{'non_support_instances'}=\"$ValueOfCfgVariable{'non_support_instances'}\"\n";
}

#-------------------------------------------------
# Put all configuration values in cfg_BestHPCC.sh
#-------------------------------------------------
$cfgfile="$ThisDir/cfg_BestHPCC.sh";
open(OUT,">>$cfgfile") || die "Can't open for append: \"$cfgfile\"\n";

# Get date is \$date.
use POSIX qw(strftime); my $date = strftime "%m/%d/%Y", localtime;
print OUT "\n#======================= JUST ADDED VARIABLES ($date) =======================\n";

my $ThisInstanceIP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`;chomp $ThisInstanceIP;
print "DEBUG: ThisInstanceIP=$ThisInstanceIP\n";
print OUT "ThisInstanceIP=$ThisInstanceIP\n";

foreach my $cfgvar (sort keys %ValueOfCfgVariable){
   if (( $cfgvar eq 'UserNameAndPassword' ) && ( $ValueOfCfgVariable{$cfgvar} ne 'thumphrey/password' ) && ( $ValueOfCfgVariable{$cfgvar} =~ /^\w+\W.+$/ )){
      my $username = $1 if $ValueOfCfgVariable{$cfgvar} =~ /^(\w+)/;
      my $password = $1 if $ValueOfCfgVariable{$cfgvar} =~ /^$username.(.+)$/;
      print "DEBUG: system_username=$username\n";
      print OUT "system_username=$username\n";
      print "DEBUG: system_password=$password\n";
      print OUT "system_password=$password\n";
   }
   # Here we will adjust platform path based on whether version is before/after version 5.2. 
   # Also, we will determine OS version (either 'el6' or 'el7'.
   elsif ( $cfgvar eq 'HPCCPlatform' ){ 
      my $version = $1 if $ValueOfCfgVariable{$cfgvar} =~ /^hpcc-platform-(.+)$/i;
      my $base_version = $1 if $version =~ /^(\d+\.\d+\.\d+)(?:-\w+)?/;# examples: 6.2.4-3 or 7.0.0-rc3
      $First2Digits = $1 if $base_version =~ /^(\d+\.\d+)/;

      my $platformpath="http://cdn.hpccsystems.com/releases/CE-Candidate-<base_version>/bin/platform";   
      if ( $First2Digits>=6.0 ){
        $platformpath="http://wpc.423A.rhocdn.net/00423A/releases/CE-Candidate-<base_version>/bin/platform";
        if ( $First2Digits<7.0 ){
          print OUT "IsPlatformSix=1\n";
          $IsPlatformSix=1;
        }
        else{
          print OUT "IsPlatformSixOrHigher=1\n";
          $IsPlatformSixOrHigher=1;
        }
      }
      my $platformBefore5_2=($First2Digits>=6.0)? "hpccsystems-platform_community-<version>.<osversion>.x86_64.rpm":"hpccsystems-platform_community-with-plugins-<version>.el6.x86_64.rpm";# Has underscore between platform and community  
      my $platformAfter5_2=($First2Digits>=6.0)? "hpccsystems-platform-community_<version>.<osversion>.x86_64.rpm":"hpccsystems-platform-community-with-plugins_<version>.el6.x86_64.rpm";# Has dash between platform and community   
print "DEBUG: First2Digits=\"$First2Digits\"\n";
      $platformpath =~ s/<base_version>/$base_version/;
      my $HPCCPlatform;
      if ( $First2Digits >= 5.2 ){
         $HPCCPlatform= "$platformpath/$platformAfter5_2";
	 print "DEBUG: GT 5.2 HPCCPlatform=\"$HPCCPlatform\"\n";
      }
      else{
         $HPCCPlatform= "$platformpath/$platformBefore5_2";
	 print "DEBUG: LT 5.2 HPCCPlatform=\"$HPCCPlatform\"\n";
      }
      $HPCCPlatform =~ s/<version>/$version/;
      $osversion = getOSVersion();
      $HPCCPlatform =~ s/<osversion>/$osversion/;
      print "DEBUG: HPCCPlatform=$HPCCPlatform\n";
      print OUT "HPCCPlatform=$HPCCPlatform\n";
   }
   else{
      next if $cfgvar eq 'channelsPerSlave';
      print "DEBUG: $cfgvar=$ValueOfCfgVariable{$cfgvar}\n";
      print OUT "$cfgvar=$ValueOfCfgVariable{$cfgvar}\n";
   }
}

if ( exists($ValueOfCfgVariable{'channelsPerSlave'}) && ($ValueOfCfgVariable{'channelsPerSlave'}>1) ){
   if ( $First2Digits>=6.0 ){
     print "DEBUG: Platform is version 6 or higher and ValueOfCfgVariable{'channelsPerSlave'}=\"$ValueOfCfgVariable{'channelsPerSlave'}\".\n";
     print OUT "channelsPerSlave=$ValueOfCfgVariable{'channelsPerSlave'}\n";
   }
   else{
      print "WARNING! Platform version is less than 6 but channelsPerSlave=$channelsPerSlave. NOT ALLOWED.\n";
   }
}


#---------------------------------------------------------------------------------
# Put arrays of Instance Variables (from Instance Descriptions) in cfg_BestHPCC.sh
#---------------------------------------------------------------------------------
print "# Arrays of Instance Variables:\n";
for( my $i=0; $i < scalar(@sorted_InstanceInfo); $i++){
  my %InstanceVariable=%{$sorted_InstanceInfo[$i]};

  # If we have a downed instance then save that instance's Name (nodetype), ebs VolumeId, and InstanceId
  #  If there is more than one instance that has gone down that is the same as this instance's nodetype
  #   then the last one will be the most recent one to go down.
  if ( ($InstanceVariable{'State'} ne 'running') && ( $InstanceVariable{'Name'} eq $clustercomponent ) ){
    $DownedInstanceId=$InstanceVariable{'InstanceId'};
    $DownedNodeType=$InstanceVariable{'Name'};
    $DownedVolumeId=$InstanceVariable{'VolumeId'};
  }
  
  foreach my $v (@InstanceVariable){
    if ( ! $OutputOnceVariables{$v} ){
      $display_v = ($v eq 'Name')? 'nodetype' : $v ;
      print "DEBUG: $display_v\[$i\]=$InstanceVariable{$v}\n";
      print OUT "$display_v\[$i\]=$InstanceVariable{$v}\n";
    }
  }
}

# If there is a downed instance then save its info in /home/$user/cfg_BestHPCC.sh.
if ( $DownedInstanceId!~/^\s*$/ ){
      print "DEBUG: DownedInstanceId=$DownedInstanceId\n";
      print OUT "DownedInstanceId=$DownedInstanceId\n";
      print "DEBUG: DownedNodeType=$DownedNodeType\n";
      print OUT "DownedNodeType=$DownedNodeType\n";
      print "DEBUG: DownedVolumeId=$DownedVolumeId\n";
      print OUT "DownedVolumeId=$DownedVolumeId\n";

      print "In $0: AlertUserOfChangeInRunStatus($email, \"$DownedNodeType instance has gone down. We are automatically launching another. Will let you know when cluster is ready to use again.\")\n";
      AlertUserOfChangeInRunStatus($email, "$DownedNodeType instance has gone down. We are automatically launching another. Will let you know when cluster is ready to use again.");
}
else{
      print "DEBUG: DownedInstanceId=\n";
      print OUT "DownedInstanceId=\n";
      print "DEBUG: DownedNodeType=\n";
      print OUT "DownedNodeType=\n";
      print "DEBUG: DownedVolumeId=\n";
      print OUT "DownedVolumeId=\n";
}

close(OUT);
#==============================================================================
sub getOSVersion{
  my $osversion='el6';
  if ( -e "/etc/os-release" ){
    local $_=`cat /etc/os-release`;
    if ( /centos-7/si ){
      $osversion='el7';
    }
  }
  return $osversion;
}
#==============================================================================
sub getPemFileFromS3Bucket{
#--------------------------------------------------------------------------------
# Get pem file from s3 bucket and chmod 400 it. Also, put bucket name in cfg
#--------------------------------------------------------------------------------
my $lc_stackname=$stackname; $lc_stackname =~ s/([A-Z]+)/\L$1/g;
print "In getPemFileFromS3Bucket: aws s3 cp s3://$lc_stackname/$stackname.pem $ThisDir/$stackname.pem\n";
my $rc=`aws s3 cp s3://$lc_stackname/$stackname.pem $ThisDir/$stackname.pem 2>&1`;
print "In getPemFileFromS3Bucket. rc of cp of pem file from s3 bucket is \"$rc\"\n";

print "In getPemFileFromS3Bucket: chmod 400 $ThisDir/$stackname.pem\n";
my $rc=`chmod 400 $ThisDir/$stackname.pem 2>&1`;
print "In getPemFileFromS3Bucket. chmod 400 rc is \"$rc\"\n";
my $rc=`chown $sshuser:$sshuser $ThisDir/$stackname.pem 2>&1`;
print "In getPemFileFromS3Bucket. chown $sshuser:$sshuser $stackname.pem rc is \"$rc\"\n";
my $rc=`ls -l $ThisDir/$stackname.pem 2>&1`;
print "In getPemFileFromS3Bucket. ls -l $stackname.pem's rc is \"$rc\"\n";
return $stackname;
}
#==============================================================================
sub getEIPFromS3Bucket{
my $lc_stackname=$stackname; $lc_stackname =~ s/([A-Z]+)/\L$1/g;
print "In getEIPFromS3Bucket: aws s3 cp s3://$lc_stackname/EIPAllocationId $ThisDir/EIPAllocationId\n";
my $rc=`aws s3 cp s3://$lc_stackname/EIPAllocationId $ThisDir/EIPAllocationId 2>&1`;
print "In getEIPFromS3Bucket. rc of cp of EIPAllocationId file from s3 bucket is \"$rc\"\n";
my $EIPAllocationId=`cat $ThisDir/EIPAllocationId`; chomp $EIPAllocationId;
return $EIPAllocationId;
}
#==============================================================================
sub getEmailFileFromS3Bucket{
my $lc_stackname=$stackname; $lc_stackname =~ s/([A-Z]+)/\L$1/g;
print "In getEmailFileFromS3Bucket: aws s3 cp s3://$lc_stackname/destination_email $ThisDir/destination_email\n";
my $rc=`aws s3 cp s3://$lc_stackname/destination_email $ThisDir/destination_email 2>&1`;
print "In getEmailFileFromS3Bucket. rc of cp of destination_email file from s3 bucket is \"$rc\"\n";
my $email=`cat $ThisDir/destination_email`; chomp $email;
return $email;
}
