#!/usr/bin/perl
=pod

This script does:
1. Stop HPCC
2. Detach all instances from their ASGs and decrement autoscaling capacity.
3. Stop all instances that have been detached (STOP MASTER instance LAST).
=cut
$ThisDir=($0 =~ /^(.+)[\\\/]/)? $1 : "." ;
require "$ThisDir/ClusterInitVariables.pl";
require "$ThisDir/formatDateTimeString.pl";

my $dt=formatDateTimeString();print "$dt Entering $0.\n";

if ( ! $ASGSuspended ){
  print("$ThisDir/suspendASGProcesses.pl\n");
  system("$ThisDir/suspendASGProcesses.pl");
  $ASGSuspended=1;
}

#===================================================================
# NOTE: This scripts REQUIRES the aws cli be installed and configured.
#===================================================================

if ( ! defined($no_hpcc) ){
 # 1. Stop HPCC System
 my $dt=formatDateTimeString(); print("$dt $ThisDir/stopHPCCOnAllInstances.pl\n");
 my $rc=`$ThisDir/stopHPCCOnAllInstances.pl`;
 print "$dt $rc";

 if ( $rc =~ /Still NOT alive/si ){
  my $dt=formatDateTimeString(); die "$dt FATAL ERROR: While ssh'ing to bastion to stop all hpcc instances. Contact Tim Humphrey. EXITING.\n";
 }
}

#-------------------------
# 2. Detach all instances from their ASGs and decrement autoscaling capacity.
# 3. Stop all instances that have been detached (STOP MASTER instance LAST).
#-------------------------

# IF ! defined($no_hpcc) then we assume there is a possibility of one or more ASGs
if ( ! defined($no_hpcc) && defined($stackname) ){
  # Get json summary descriptions of all ASGs
  $asgs_descriptions=`aws autoscaling describe-auto-scaling-instances --region $region 2> aws_errors.txt`;
  my $err=`cat aws_errors.txt`;
  if ( $err =~ /is now earlier than/ ){
    my $dt=formatDateTimeString(); die "$dt FATAL ERROR. Your computer's time is behind aws' time. Need to run \"sudo ntpdate -s time.nist.gov\" then try again. Contact Tim Humphrey. EXITING. \n";
  }

  @asgnames=ArrayOfValuesForKey('AutoScalingGroupName',$asgs_descriptions);
  @asgnames=grep(/\b$stackname\b/,@asgnames);
  my $dt=formatDateTimeString();print "$dt After getting \@asgnames from describe-auto-scaling-instances. \@asgnames=(",join(",",@asgnames),")\n";

  # Remove MasterASG because it has already been removed
  my @z=();
  foreach (@asgnames){
       push @z, $_ if ($in_asgname eq '') || ( /$in_asgname/ );
  }
  @asgnames=@z;
  #print "BEGIN ASGs\n",join("\n",@asgnames),"\nEND ASGs\n"; # exit; # DEBUG DEBUG DEBUG

  @asg_description=splitASGs($asgs_descriptions);
  @asg_description=grep(/\b$stackname/,@asg_description);
  #print "BEGIN ASGDs\n",join("\n#.........................................................\n",@asg_description),"\nEND ASGDs\n"; exit; # DEBUG DEBUG DEBUG
}
else{
 @asgnames=();
}

my @asgname_and_instances=();
foreach my $asgname (@asgnames){

  # Get asg description for $asgname
  my @asg=grep(/$asgname/s,@asg_description);
  my @asg_instance_id=ArrayOfValuesForKey('InstanceId',@asg);
#  print join("\n",@asg_instance_id),"\n";# exit;# DEBUG DEBUG DEBUG

  # Push current asg name and all its instances to @asgname_and_instances
  my $asg_instance_ids=join(",",@asg_instance_id);
  my $dt=formatDateTimeString(); print("$dt Push onto \@asgname_and_instances this asg's name and all its instances:$asgname:$asg_instance_ids\n"); 
  push  @asgname_and_instances, "$asgname:$asg_instance_ids";

  if ( ! $ASGSuspended ){
  foreach my $asg_instance_id (@asg_instance_id){

    my $dt=formatDateTimeString(); print("$dt Detach instance=$asg_instance_id from ASG=$asgname\n");
    my $dt=formatDateTimeString(); print("$dt aws autoscaling detach-instances --instance-ids $asg_instance_id --auto-scaling-group-name $asgname --should-decrement-desired-capacity --region $region\n");
    my $rc=`aws autoscaling detach-instances --instance-ids $asg_instance_id --auto-scaling-group-name $asgname --should-decrement-desired-capacity --region $region`;
    if ( $rc !~ /Detaching EC2 instance/s ){
      my $dt=formatDateTimeString(); die "$dt FATAL ERROR. While attempting to detach instance, \"$asg_instance\". Contact Tim Humphrey. EXITING. \n";
    }

    # Stop Instance
    my $dt=formatDateTimeString(); print("$dt STOP instance=$asg_instance_id\n");
    my $dt=formatDateTimeString(); print("$dt aws ec2 stop-instances --instance-ids $asg_instance_id --region $region\n");
    my $rc=`aws ec2 stop-instances --instance-ids $asg_instance_id --region $region`;

    if ( $rc !~ /StoppingInstances/s ){
      my $dt=formatDateTimeString(); die "$dt FATAL ERROR. While attempting to stop instance, \"$asg_instance\". Contact Tim Humphrey. EXITING. \n";
    }
  }
  }
}

if ( defined($instance_id_file) ){
   $_=`cat $instance_id_file`;
   s/^\s+//;
   s/\s+$//;
   my @i=split(/\n/,$_);
   # Put master on end
   my $tmp=shift @i;
   push @i, $tmp;
   foreach (@i){
     push @additional_instances, $_;
   }
}

my $dt=formatDateTimeString();print "$dt Number of instance ids in \@additional_instances is ",scalar(@additional_instances),"\n";
foreach my $instance_id (@additional_instances){
  my $dt=formatDateTimeString(); print("$dt aws ec2 stop-instances --instance-ids $instance_id --region $region\n");
  my $rc=`aws ec2 stop-instances --instance-ids $instance_id --region $region`;
}
#===========================================================
sub ArrayOfValuesForKey{
my ($key,@asg_descriptions)=@_;
my @d0=split("\n",join("\n",@asg_descriptions));
my @d1=grep(s/^ +\"$key\"\s*:\s*\"([^\"]+)\".*$/$1/,@d0);

# Remove duplicate names
my @asg_values=();
my %KeyValueExists=();
foreach (@d1){
  if ( ! exists($KeyValueExists{$_}) ){
     push @asg_values, $_;
     $KeyValueExists{$_}=1;
  }
}
return @asg_values;
}
#===========================================================
sub splitASGs{
my ( $x )=@_;
$x =~ s/^.+\"AutoScalingInstances\"\s*: *\[\s*\n//s;
$x =~ s/\n +\]\s*\n\}\s*$//s;
#print $x,"\n";

my @y=split(/\n( +)\},\s*\n/s,$x);
@y=grep(!/^\s*$/,@y);

return @y;
}
#===========================================================
