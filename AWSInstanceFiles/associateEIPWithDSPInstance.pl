#!/usr/bin/perl

require "/home/ec2-user/getConfigurationFile.pl";

die "In associateEIPWithDSPInstance.pl. FATAL ERROR. Expected argument, i.e. an eip allocation id. None given. EXITING.\n" if scalar(@ARGV)<=0;

$eip_allocation_id=shift @ARGV;

=pod
1. Get dsp instance id $asgs_descriptions
2. Get region from getConfigureationFile.pl
3. Make association
=cut

# Get json summary descriptions of all ASGs
$asgs_descriptions=`aws autoscaling describe-auto-scaling-instances --region $region`;

# Split $asg_descriptions into array of descriptions
@asg_description=splitASGs($asgs_descriptions);
#print "AD: ",join("\nAD: ",@asg_description),"\n\n";

# Extract ASG names from $asgs_descriptions
@asgnames=ArrayOfValues('AutoScalingGroupName',@asg_description);

# Extract DSP's ASG name from @asgnames
( $dsp_asgname ) = grep(/DSPMySQLASG/,@asgnames);
print "DEBUG: dsp_asgname=\"$dsp_asgname\"\n";

# Get only the DSP ASG's Description
($dsp_asg_description)=grep(/$dsp_asgname/s,@asg_description);

# Get DSP instance id
($dsp_instance_id)=ArrayOfValues('InstanceId',($dsp_asg_description));
print "DEBUG: dsp_instance_id=\"$dsp_instance_id\"\n";

# Associate EIP with the DSP instance
print "aws ec2 associate-address --allocation-id $eip_allocation_id --instance-id $dsp_instance_id --region $region\n";
system "aws ec2 associate-address --allocation-id $eip_allocation_id --instance-id $dsp_instance_id --region $region";
#------------------------------------------------------
# Subroutine: Get all lines of @asg_descriptions that contain $key.
#------------------------------------------------------
sub ArrayOfValues{
my ($key,@asg_descriptions)=@_;
#print "DEBUG: key=\"$key\" Enter ArrayOfValues: ",join("\nDEBUG: Enter ArrayOfValues: ",@asg_descriptions),"\n\n";
my @d1=grep(s/^ +\"$key\"\s*:\s*\"([^\"]+)\".*$/$1/s,split(/\n/,join("\n",@asg_descriptions)));
#print "DEBUG: $key: ",join("\nDEBUG: $key: ",@d1),"\n\n";

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
#--------------------------------------------------------------------------------
# Subroutine: Split $asg_descriptions into individual asg descriptions -- one per array cell.
#--------------------------------------------------------------------------------
sub splitASGs{
my ( $x )=@_;
$x =~ s/^.+\"AutoScalingInstances\"\s*: *\[\s*\n//s;
$x =~ s/\n +\]\s*\n\}\s*$//s;
#print $x,"\n";

my @y=split(/\n( +)\},\s*\n/s,$x);
@y=grep(!/^\s*$/,@y);

return @y;
}
