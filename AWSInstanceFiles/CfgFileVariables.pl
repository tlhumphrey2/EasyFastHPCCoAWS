#!/usr/bin/perl
$ThisDir=($0=~/^(.*)\//)? $1 : ".";

require "$ThisDir/getConfigurationFile.pl";
require "$ThisDir/cf_common.pl";
require "$ThisDir/common.pl";

# Default values for some configuration variables
$DefaultValuesOfCfgVariables{'stackname'}=$stackname;
$DefaultValuesOfCfgVariables{'region'}=$region;
$DefaultValuesOfCfgVariables{'pem'}='';
$DefaultValuesOfCfgVariables{'slavesPerNode'}=1;
$DefaultValuesOfCfgVariables{'roxienodes'}=0;
$DefaultValuesOfCfgVariables{'supportnodes'}=1;
$DefaultValuesOfCfgVariables{'non_support_instances'}=1;
$DefaultValuesOfCfgVariables{'UserNameAndPassword'}='';
$DefaultValuesOfCfgVariables{'HPCCPlatform'}='HPCC-Platform-6.4.20-1';
$DefaultValuesOfCfgVariables{'ToS3Bucket'}="s3://${stackname}-backup";
$DefaultValuesOfCfgVariables{'channelsPerSlave'}="";
$DefaultValuesOfCfgVariables{'sshuser'}="ec2-user";
$DefaultValuesOfCfgVariables{'EIP'}="";
foreach my $k (sort keys %DefaultValuesOfCfgVariables){
  print "DEBUG: In CfgFileVariables.pl. DefaultValuesOfCfgVariables{$k}=\"$DefaultValuesOfCfgVariables{$k}\"\n";
}
1;
