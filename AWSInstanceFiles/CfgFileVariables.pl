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
$DefaultValuesOfCfgVariables{'HPCCPlatform'}='HPCC-Platform-5.0.0-3';
$DefaultValuesOfCfgVariables{'ToS3Bucket'}="s3://${stackname}-backup";
1;
