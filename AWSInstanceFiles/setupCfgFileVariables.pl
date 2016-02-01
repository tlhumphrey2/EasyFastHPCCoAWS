#!/usr/bin/perl

require "/home/ec2-user/getConfigurationFile.pl";

$stackname = shift @ARGV;
$region = shift @ARGV;
print "Entering setupCfgFileVariables.pl. Inputted arguments are: stackname=\"$stackname\", region=\"$region\"\n";

# Default values for some confuration variables
$DefaultValuesOfCfgVariables{'stackname'}=$stackname;
$DefaultValuesOfCfgVariables{'region'}=$region;
$DefaultValuesOfCfgVariables{'pem'}='';
$DefaultValuesOfCfgVariables{'slavesPerNode'}=1;
$DefaultValuesOfCfgVariables{'roxienodes'}=0;
$DefaultValuesOfCfgVariables{'supportnodes'}=1;
$DefaultValuesOfCfgVariables{'non_support_instances'}=1;
$DefaultValuesOfCfgVariables{'UserNameAndPassword'}='';
$DefaultValuesOfCfgVariables{'HPCCPlatform'}='HPCC-Platform-5.0.0-3';
$DefaultValuesOfCfgVariables{'ToS3Bucket'}='';

#--------------------------------------------------------------------------------
# Get any configuration variables, and their values, in the instance descriptions.
#--------------------------------------------------------------------------------
# First get instance descriptions for just instance having StackName equal to $stackname.
$StackNameInstanceDescriptions=`aws ec2 describe-instances --region $region --filter "Name=tag:slavesPerNode,Values=*,Name=tag:StackName,Values=$stackname"`;

# The following is DEBUG
`aws ec2 describe-instances --region $region --filter "Name=tag:slavesPerNode,Values=*,Name=tag:StackName,Values=$stackname" > /home/ec2-user/instance-descriptions.json`;

# Note. This function's output will be in the hash %ValueOfCfgVariable, where the key is the cfg variable and value is its value
%ValueOfCfgVariable=();
getCfgVariablesFromInstanceDescriptions($StackNameInstanceDescriptions, keys %DefaultValuesOfCfgVariables);

$ValueOfCfgVariable{'stackname'}=$stackname;
$ValueOfCfgVariable{'ToS3Bucket'}="s3://${stackname}-backup";

sub getCfgVariablesFromInstanceDescriptions{
my ($InstanceDescriptions,@CfgVariable)=@_;

   # Split descriptions into lines
   my @StackNameInstanceDescriptions=split(/\n/,$InstanceDescriptions);
   
   # Initialize %ValueOfCfgVariable with the default value of each cfg variable
   foreach my $cfgvar (@CfgVariable){
      $ValueOfCfgVariable{$cfgvar}=$DefaultValuesOfCfgVariables{$cfgvar};
   }
   
   # Look for the variable name and get its value. Store in ValueOfCfgVariable.
   my $re='\b'.join("|",@CfgVariable).'\b';
   my $VariablesFound=0;
   for( my $i=0; $i < scalar(@StackNameInstanceDescriptions); $i++){
       local $_=$StackNameInstanceDescriptions[$i];
       if ( /($re)/ ){
          my $v=$1;
          $_=$StackNameInstanceDescriptions[$i-1];
          s/^.*"Value"\s*:\s+"//;
          s/",\s*$//;
          $ValueOfCfgVariable{$v}=($v eq 'pem')? "/home/ec2-user/$_.pem" : $_;
          $VariablesFound=1;
print "DEBUG: In getCfgVariablesOfInstanceDescriptions. \$ValueOfCfgVariable{$v}=\"$ValueOfCfgVariable{$v}\"\n";
       }
   }
print "DEBUG: In getCfgVariablesOfInstanceDescriptions. NO VARIABLES FOUND in instance descriptions.\n" if $VariablesFound==0;   
}
#-------------------------------------------------------------------------------------
# END Get any configuration variables, and their values, in the instance descriptions.
#-------------------------------------------------------------------------------------

# Get in the file, t, just instances with tag:Name Value of "$stackname--*"
`aws ec2 describe-instances --region $region --filter "Name=tag:Name,Values=$stackname--*" > t`;
print "DEBUG: length of instance with stackname = \"$stackname\" is ",`wc -c t`,"\n";

$HPCCNodeTypes='Master|Slave|Roxie';
$m="$stackname--($HPCCNodeTypes)|InstanceId.:";
$x=`egrep "$m" t`;
print "DEBUG: length of lines matching \"InstanceId.:\" is ",length($x),", Lines are \"$x\"\n";
@x=split(/\n/,$x);
@x=reverse @x if $x[0] !~ /$HPCCNodeTypes/;
for( my $i=0; $i < scalar(@x); $i++){
  local $_=$x[$i];
  if ( /Master/ ){
     push @master, $x[$i+1];
  }
  elsif ( /Slave/ ){
     push @slave, $x[$i+1];
  }
  elsif ( /Roxie/ ){
     push @roxie, $x[$i+1];
  }
}
@x=(@master,@slave,@roxie);
print "DEBUG: instance ids=(",join(",",@x),")\n";

# Remove everything before instance id.
@x=grep(s/^.+InstanceId\":\s\"//,@x);

# Remove everything after instance id.
@x=grep(s/\",\s*$//,@x);

# Save instance ids in $instance_ids file.
open(OUT,">$instance_ids") || die "Can't open for output: \"$instance_ids\"\n";
print STDERR "Outputting all instance ids to $instance_ids\n";
print OUT join("\n",@x),"\n";
close(OUT);

$nInstances=scalar(@x);
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
   elsif ( $cfgvar eq 'HPCCPlatform' ){
      my $platformpath="http://cdn.hpccsystems.com/releases/CE-Candidate-<base_version>/bin/platform";   
      my $platformBefore5_2="hpccsystems-platform_community-with-plugins-<version>.el6.x86_64.rpm";# Has underscore between platform and community  
      my $platformAfter5_2= "hpccsystems-platform-community-with-plugins_<version>.el6.x86_64.rpm";# Has dash between platform and community   
      my $version = $1 if $ValueOfCfgVariable{$cfgvar} =~ /^hpcc-platform-(.+)$/i;
      my $base_version = $1 if $version =~ /^(\d+\.\d+\.\d+)(?:-\d+)?/;
      my $First2Digits = $1 if $base_version =~ /^(\d+\.\d+)/;
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
system("perl /home/ec2-user/getPublicAndPrivateIps.pl");
