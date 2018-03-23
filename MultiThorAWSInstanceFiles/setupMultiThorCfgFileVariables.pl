#!/usr/bin/perl
# THIS PROGRAM adds lines to cfg_BestHPCC.sh and creates these 4 files: instance_ids.txt, public_ips.txt, and private_ips.txt ip_labels.txt
=pod
setupMultiThorCfgFileVariables.pl -sshuser ec2-user -stackname test-inventory-file-2 -cfg "" -sipt "1,1" -snpipt "3,4" -ripr "1,1" -region us-east-2 -support "" -pem tlh_keys_us_east_2.pem -platform HPCC-Platform-6.4.10-1 -s3bucket s3://BestHoA/instance_files

=cut
$ThisDir=($0=~/^(.*)\//)? $1 : ".";
print "DEBUG: Entering setupMultiThorCfgFileVaribles.pl. ThisDir=\"$ThisDir\". \@ARGV=(",join(" ",@ARGV),").\n";

require "$ThisDir/getConfigurationFile.pl";
require "$ThisDir/cf_common.pl";
require "$ThisDir/common.pl";
$error_messages='';
#================== Get Input Arguments ================================
require "newgetopt.pl";
if ( ! &NGetOpt(
                "sshuser=s", "stackname=s", "cfg=s", "sipt=s", "snpipt=s", "ripr=s", "support=s", "region=s", "pem=s",
                "platform=s", "uidpwd=s", "s3bucket=s"
                ))      # Add Options as necessary
{
  print STDERR "\n[$0] -- ERROR -- Invalid/Missing options...\n\n";
  exit(1);
}
$sshuser=getRequiredParameter($opt_sshuser,"USAGE ERROR: $0. NO SSH USER GIVEN. (REQUIRED)\n");
$stackname=getRequiredParameter($opt_stackname,"USAGE ERROR: $0. NO STACKNAME GIVEN. (REQUIRED)\n");
$ClusterInventoryFile         = $opt_cfg || 'NONE';
$SlaveInstancesPerTHOR        = $opt_sipt || 0;
@sipt=split(/,/,$SlaveInstancesPerTHOR);
$RoxieInstancesPerROXIE       = $opt_ripr || 0;
@ript=split(/,/,$RoxieInstancesPerROXIE);
$error_messages.="USAGE ERROR: $0. NO THORs or ROXIEs specified. MUST have at least one THOR or one ROXIE.\n" if ($SlaveInstancesPerTHOR==0) && ($RoxieInstancesPerROXIE==0);
$SlaveNodesPerInstancePerTHOR = $opt_snpipt || '';
$support=$opt_support;
$region=getRequiredParameter($opt_region,"USAGE ERROR: $0. NO REGION GIVEN. (REQUIRED)\n");
$pem=getRequiredParameter($opt_pem,"USAGE ERROR: $0. NO PEM FILE GIVEN. (REQUIRED)\n");
$HPCCPlatform=getRequiredParameter($opt_platform,"USAGE ERROR: $0. NO HPCC PLATFORM GIVEN. (REQUIRED)\n");
$UserNameAndPassword=$opt_uidpwd||'';
$bucket_name=getRequiredParameter($opt_s3bucket,"USAGE ERROR: $0. NO S3 BUCKET NAME GIVEN. (REQUIRED)\n");
#===============END Get Input Arguments ================================
die $error_messages if $error_messages ne '';
$pem .= '.pem' if $pem !~ /\.pem\s*$/;

# Separate username and password into the following 2 variables.
$system_username=''; $system_password='';
if ( $UserNameAndPassword =~ /(.+)\/(.+)/ ){
  $system_username=$1;
  $system_password=$2;
}

# Setup full path of hpcc platform
my ($IsPlatformSixOrHigher,$FullPath2HPCCPlatform)=addPathToHPCCPlatform($HPCCPlatform);

$cfgfile="$ThisDir/cfg_BestHPCC.sh";
open(OUT,">>$cfgfile") || die "Can't open for append: \"$cfgfile\"\n";
print OUT "\n";
print OUT <<EOFF;
sshuser="$sshuser"
stackname="$stackname"
ClusterInventoryFile="$ClusterInventoryFile"
SlaveInstancesPerTHOR="$SlaveInstancesPerTHOR"
RoxieInstancesPerROXIE="$RoxieInstancesPerROXIE"
SlaveNodesPerInstancePerTHOR="$SlaveNodesPerInstancePerTHOR"
support="$support"
region="$region"
pem="/home/$sshuser/$pem"
HPCCPlatform="$HPCCPlatform"
IsPlatformSixOrHigher="$IsPlatformSixOrHigher"
hpcc_platform="$FullPath2HPCCPlatform"
UserNameAndPassword="$UserNameAndPassword"
system_username="$system_username"
system_password="$system_password"
bucket_name="$bucket_name"
EOFF
#--------------------------------------------------------------------------------
# Get any configuration variables, and their values, in the instance descriptions.
#--------------------------------------------------------------------------------
# First get instance descriptions for just instance having StackName equal to $stackname.
system("aws ec2 describe-instances --region $region --filter \"Name=tag:StackName,Values=$stackname\" > $ThisDir/this-stacknames-instance-descriptions.json");

# Parse JSON
my $instance_info=`python $ThisDir/parseJSON.py $ThisDir/this-stacknames-instance-descriptions.json|$ThisDir/one-line-tagname-value.pl|egrep "^\.\.\.\.key=.*IpAddress|^\.\.\.\.key=InstanceId|^\.\.\.\.\.tagname=Name"`;
#print "\n";print "DEBUG: \$instance_info=\"$instance_info\"\n\n";

@instance_info=split(/\n/,$instance_info);
@instance_info=grep(s/^\.+//,@instance_info);
#print "DEBUG: \@instance_info:\n",join("\n",@instance_info),"\n"; exit; #DEBUG

# Get public ips, private ips, instance ids, and ip labels
@public_ips=();
@private_ips=();
@instance_ids=();
@ip_labels=();
while(scalar(@instance_info)>0){
  $_=shift @instance_info;
  push @public_ips, $1 if /, value=(.+)/;
  $_=shift @instance_info;
  push @private_ips, $1 if /, value=(.+)/;
  $_=shift @instance_info;
  push @instance_ids, $1 if /, value=(.+)/;
  $_=shift @instance_info;
# print "DEBUG: Should be tagname: \"$_\"\n";
  push @ip_labels, $1 if /, value=.+\-\-(Master|Roxie|Support|Slave)/;
}
#print "DEBUG: \@private_ips:\n",join("\n",@private_ips),"\n\n";
#print "DEBUG: \@ip_labels:\n",join("\n",@ip_labels),"\n\n";
#print "DEBUG: \@public_ips:\n",join("\n",@public_ips),"\n\n";
#print "DEBUG: \@instance_ids:\n",join("\n",@instance_ids),"\n\n"; exit; #DEBUG

storeOnDisk("$ThisDir/private_ips.txt",\@private_ips);
storeOnDisk("$ThisDir/ip_labels.txt",\@ip_labels);
storeOnDisk("$ThisDir/public_ips.txt",\@public_ips);
storeOnDisk("$ThisDir/instance_ids.txt",\@instance_ids);

print OUT <<EOFF;
private_ips="$ThisDir/private_ips.txt"
public_ips="$ThisDir/public_ips.txt"
instance_ids="$ThisDir/instance_ids.txt"
ip_labels="$ThisDir/ip_labels.txt"
EOFF
close(OUT);
#-------------------------------------------------------------------------------------
# END Get any configuration variables, and their values, in the instance descriptions.
#-------------------------------------------------------------------------------------
sub storeOnDisk{
my ($filename, $contents)=@_;
open(OUT2,">$filename") || die "In storeOnDisk. Can't open for output: \"$filename\"\n";
print OUT2 join("\n",@$contents),"\n";
close(OUT2);
}
#=======================================================================================
sub getRequiredParameter{
my ($parameter,$emessage)=@_;
  my $rc=$parameter;
  $error_messages.=$emessage if ( $parameter eq '' );
  return $rc;
}
#=======================================================================================
