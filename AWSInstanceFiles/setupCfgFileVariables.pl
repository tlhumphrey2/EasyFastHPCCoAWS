#!/usr/bin/perl
# THIS PROGRAM adds lines to cfg_BestHPCC.sh and creates these 3 files: instance_ids.txt, public_ips.txt, and private_ips.txt

require "/home/ec2-user/getConfigurationFile.pl";
require "/home/ec2-user/cf_common.pl";

$stackname = shift @ARGV;
$region = shift @ARGV;
$EIP = (scalar(@ARGV)==1)? shift @ARGV : '' ;
print "Entering setupCfgFileVariables.pl. Inputted arguments are: stackname=\"$stackname\", region=\"$region\", EIP=\"$EIP\"\n";

# Default values for some configuration variables
$DefaultValuesOfCfgVariables{'stackname'}=$stackname;
$DefaultValuesOfCfgVariables{'region'}=$region;
$DefaultValuesOfCfgVariables{'pem'}='';
$DefaultValuesOfCfgVariables{'slavesPerNode'}=1;
$DefaultValuesOfCfgVariables{'roxienodes'}=0;
$DefaultValuesOfCfgVariables{'supportnodes'}=1;
$DefaultValuesOfCfgVariables{'non_support_instances'}=1;
$DefaultValuesOfCfgVariables{'UserNameAndPassword'}='';
$DefaultValuesOfCfgVariables{'HPCCPlatform'}='HPCC-Platform-5.0.0-3';
$DefaultValuesOfCfgVariables{'ToS3Bucket'}="s3://${stackname}-backup";

#--------------------------------------------------------------------------------
# Get any configuration variables, and their values, in the instance descriptions.
#--------------------------------------------------------------------------------
# First get instance descriptions for just instance having StackName equal to $stackname.
$StackNameInstanceDescriptions=`aws ec2 describe-instances --region $region --filter "Name=tag:slavesPerNode,Values=*,Name=tag:StackName,Values=$stackname"`;
# Note. This function's output will be in the hash %ValueOfCfgVariable, where the key is the cfg variable and value is its value
%ValueOfCfgVariable=();
getCfgVariablesFromInstanceDescriptions($StackNameInstanceDescriptions, keys %DefaultValuesOfCfgVariables);

#==========================================================================================================
sub getCfgVariablesFromInstanceDescriptions{
my ($InstanceDescriptions,@CfgVariable)=@_;

   # Split descriptions into lines
   my @InstanceDescriptionsLine=split(/\n/,$InstanceDescriptions);
   
   # Initialize %ValueOfCfgVariable with the default value of each cfg variable
   foreach my $cfgvar (@CfgVariable){
      $ValueOfCfgVariable{$cfgvar}=$DefaultValuesOfCfgVariables{$cfgvar};
   }
   
   # Look for the variable name and get its value. Store in %ValueOfCfgVariable.
   my $re='\b'.join("|",@CfgVariable).'\b'; 
   my $VariablesFound=0;
   for( my $i=0; $i < scalar(@InstanceDescriptionsLine); $i++){
       local $_=$InstanceDescriptionsLine[$i];
       if ( /($re)/ ){
          my $v=$1; 
          $_=$InstanceDescriptionsLine[$i-1]; # Get value on previous line
          s/^.*"Value"\s*:\s+"([^\"]*)".*$/$1/; # Remove everything but the value
          $ValueOfCfgVariable{$v}=($v eq 'pem')? "/home/ec2-user/$_.pem" : $_; # If $v is 'pem' add '.pem' to end
          $VariablesFound=1;
print "DEBUG: In getCfgVariablesOfInstanceDescriptions. \$ValueOfCfgVariable{$v}=\"$ValueOfCfgVariable{$v}\"\n";
       }
   }
print "DEBUG: In getCfgVariablesOfInstanceDescriptions. NO VARIABLES FOUND in instance descriptions.\n" if $VariablesFound==0;
}
#==========================================================================================================
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
# Adjust 'non_support_instances' and put all config vlaues in cfg_BestHoA.sh 
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

# Put all configuration values in cfg_BestHoA.sh
$cfgfile="/home/ec2-user/cfg_BestHPCC.sh";
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
   elsif ( $cfgvar eq 'HPCCPlatform' ){ # Adjust platform path based on whether version is before/after version 5.2
      my $version = $1 if $ValueOfCfgVariable{$cfgvar} =~ /^hpcc-platform-(.+)$/i;
      my $base_version = $1 if $version =~ /^(\d+\.\d+\.\d+)(?:-\d+)?/;
      my $First2Digits = $1 if $base_version =~ /^(\d+\.\d+)/;

      my $platformpath="http://cdn.hpccsystems.com/releases/CE-Candidate-<base_version>/bin/platform";   
      $platformpath="http://wpc.423A.rhocdn.net/00423A/releases/CE-Candidate-<base_version>/bin/platform" if $First2Digits>=6.0;
      my $platformBefore5_2=($First2Digits>=6.0)? "hpccsystems-platform_community-<version>.el6.x86_64.rpm":"hpccsystems-platform_community-with-plugins-<version>.el6.x86_64.rpm";# Has underscore between platform and community  
      my $platformAfter5_2=($First2Digits>=6.0)? "hpccsystems-platform-community_<version>.el6.x86_64.rpm":"hpccsystems-platform-community-with-plugins_<version>.el6.x86_64.rpm";# Has dash between platform and community   
print "DEBUG: First2Digits=\"$First2Digits\"\n";
      $platformpath =~ s/<base_version>/$base_version/;
      $platformBefore5_2 =~ s/<version>/$version/;
      $platformAfter5_2 =~ s/<version>/$version/;
      my $hpcc_platform;
      if ( $First2Digits >= 5.2 ){
         $hpcc_platform= "$platformpath/$platformAfter5_2";
	 print "DEBUG: GT 5.2 hpcc_platform=\"$hpcc_platform\"\n";
      }
      else{
         $hpcc_platform= "$platformpath/$platformBefore5_2";
	 print "DEBUG: LT 5.2 hpcc_platform=\"$hpcc_platform\"\n";
      }
      print "DEBUG: hpcc_platform=$hpcc_platform\n";
      print OUT "hpcc_platform=$hpcc_platform\n";
   }
   else{
      print "DEBUG: $cfgvar=$ValueOfCfgVariable{$cfgvar}\n";
      print OUT "$cfgvar=$ValueOfCfgVariable{$cfgvar}\n";
   }
}
close(OUT);

# Get and put private and public ips in their respective files
system("perl /home/ec2-user/getPublicAndPrivateIps.pl $EIP");
