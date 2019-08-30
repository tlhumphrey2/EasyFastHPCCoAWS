#!/usr/bin/perl
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
                "sshuser=s", "stackname=s", "region=s", "pem=s", "channels=s"
                ))      # Add Options as necessary
{
  print STDERR "\n[$0] -- ERROR -- Invalid/Missing options...\n\n";
  exit(1);
}
$sshuser=$opt_sshuser || 'ec2-user';
$ValueOfCfgVariable{'sshuser'}=$sshuser;
$stackname=$opt_stackname || die "FATAL ERROR: In setupCfgFileVariables.pl. stackname WAS NOT GIVEN (REQUIRED)";
$ValueOfCfgVariable{'stackname'}=$stackname;
$region=$opt_region || die "FATAL ERROR: In setupCfgFileVariables.pl. region WAS NOT GIVEN (REQUIRED)";
$ValueOfCfgVariable{'region'}=$region;
$pem=$opt_pem || die "FATAL ERROR: In setupCfgFileVariables.pl. pem WAS NOT GIVEN (REQUIRED)";
$ValueOfCfgVariable{'pem'}="$ThisDir/$pem.pem";
$channelsPerSlave=$opt_channels || "1";
$ValueOfCfgVariable{'channelsPerSlave'}=$channelsPerSlave;
$EIP=$opt_eip;
$ValueOfCfgVariable{'EIP'}=$EIP if $EIP !~ /^\s*$/;
print "Entering setupCfgFileVariables.pl. Inputted arguments are: sshuser=\"$sshuser\", stackname=\"$stackname\", region=\"$region\", channelsPerSlave=\"$channelsPerSlave\", EIP=\"$EIP\"\n";
foreach my $k (sort keys %ValueOfCfgVariable){
  print "DEBUG: In setupCfgFileVariables.pl. After getting parameters. ValueOfCfgVariable{$k}=\"$ValueOfCfgVariable{$k}\"\n";
}
#===============END Get Input Arguments ================================

#--------------------------------------------------------------------------------
# Get any configuration variables, and their values, in the instance descriptions.
#--------------------------------------------------------------------------------
# First get instance descriptions for just instance having StackName equal to $stackname.
$StackNameInstanceDescriptions=`aws ec2 describe-instances --region $region --filter "Name=tag:slavesPerNode,Values=*,Name=tag:StackName,Values=$stackname"`;
print "DEBUG: In setupCfgFileVariables.pl. length of stack instance descriptions is ",length($StackNameInstanceDescriptions),"\n";

# Note. This function's output will be in the hash %ValueOfCfgVariable, where the key is the cfg variable and value is its value
getCfgVariablesFromInstanceDescriptions($StackNameInstanceDescriptions, keys %DefaultValuesOfCfgVariables);
foreach my $k (sort keys %ValueOfCfgVariable){
  print "DEBUG: In setupCfgFileVariables.pl. ValueOfCfgVariable{$k}=\"$ValueOfCfgVariable{$k}\"\n";
}
#-------------------------------------------------------------------------------------
# END Get any configuration variables, and their values, in the instance descriptions.
#-------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------
# Get Instance Ids of HPCC System
#------------------------------------------------------------------------------------
my @InstanceIds=getHPCCInstanceIds($region, $stackname);

# Save instance ids in $instance_ids file.
open(OUT,">$instance_ids") || die "Can't open for output: \"$instance_ids\"\n";
print STDERR "Outputting all instance ids to $instance_ids\n";
print OUT join("\n",@InstanceIds),"\n";
close(OUT);

#------------------------------------------------------------------------------------
# Adjust 'non_support_instances' and put all config values in cfg_BestHPCC.sh 
#------------------------------------------------------------------------------------
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
print OUT "\n";
foreach my $cfgvar (keys %ValueOfCfgVariable){
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
      my $base_version = $1 if $version =~ /^(\d+\.\d+\.\d+)(?:-\d+)?/;
      my $First2Digits = $1 if $base_version =~ /^(\d+\.\d+)/;

      # OLD FORMAT BEFORE 20190829: my $platformpath="http://cdn.hpccsystems.com/releases/CE-Candidate-<base_version>/bin/platform";   
      my $platformpath="https://d2wulyp08c6njk.cloudfront.net/releases/CE-Candidate-<base_version>/bin/platform";   
      if ( $First2Digits>=6.0 ){
        # OLD FORMAT BEFORE 20190829: $platformpath="http://wpc.423A.rhocdn.net/00423A/releases/CE-Candidate-<base_version>/bin/platform";
        $platformpath="https://d2wulyp08c6njk.cloudfront.net/releases/CE-Candidate-<base_version>/bin/platform";
	print OUT "IsPlatformSixOrHigher=1\n";
        my $FirstDigitOfPlatformVersion=$First2Digits;
	$FirstDigitOfPlatformVersion =~ s/^(.).*$/$1/;
	print OUT "FirstDigitOfPlatformVersion=$FirstDigitOfPlatformVersion\n";
	$IsPlatformSixOrHigher=1;
      }
      my $platformBefore5_2=($First2Digits>=6.0)? "hpccsystems-platform_community-<version>.<osversion>.x86_64.rpm":"hpccsystems-platform_community-with-plugins-<version>.el6.x86_64.rpm";# Has underscore between platform and community  
      my $platformAfter5_2=($First2Digits>=6.0)? "hpccsystems-platform-community_<version>.<osversion>.x86_64.rpm":"hpccsystems-platform-community-with-plugins_<version>.el6.x86_64.rpm";# Has dash between platform and community   
print "DEBUG: First2Digits=\"$First2Digits\"\n";
      $platformpath =~ s/<base_version>/$base_version/;
      my $hpcc_platform;
      if ( $First2Digits >= 5.2 ){
         $hpcc_platform= "$platformpath/$platformAfter5_2";
	 print "DEBUG: GT 5.2 hpcc_platform=\"$hpcc_platform\"\n";
      }
      else{
         $hpcc_platform= "$platformpath/$platformBefore5_2";
	 print "DEBUG: LT 5.2 hpcc_platform=\"$hpcc_platform\"\n";
      }
      $hpcc_platform =~ s/<version>/$version/;
      $osversion = getOSVersion();
      $hpcc_platform =~ s/<osversion>/$osversion/;
      print "DEBUG: hpcc_platform=$hpcc_platform\n";
      print OUT "hpcc_platform=$hpcc_platform\n";
   }
   else{
      next if $cfgvar eq 'channelsPerSlave';
      print "DEBUG: $cfgvar=$ValueOfCfgVariable{$cfgvar}\n";
      print OUT "$cfgvar=$ValueOfCfgVariable{$cfgvar}\n";
   }
}

if ( exists($ValueOfCfgVariable{'channelsPerSlave'}) && ($ValueOfCfgVariable{'channelsPerSlave'}>1) ){
   if ( $IsPlatformSixOrHigher ){
     print "DEBUG: Platform is version 6 or higher and ValueOfCfgVariable{'channelsPerSlave'}=\"$ValueOfCfgVariable{'channelsPerSlave'}\".\n";
     print OUT "channelsPerSlave=$ValueOfCfgVariable{'channelsPerSlave'}\n";
   }
   else{
      print "WARNING! Platform version is less than 6 but channelsPerSlave=$channelsPerSlave. NOT ALLOWED.\n";
   }
}

close(OUT);

# Get and put private and public ips in their respective files
system("perl $ThisDir/getPublicAndPrivateIps.pl $EIP");
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
