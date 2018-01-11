#!/usr/bin/perl
=pod
This program expects that all instances have the same "name" tag (except possibly at the end of the name).
For example the "name" tag, T, could be "HPCC-System-20170720". All instances must begin with this name.
Plus, this program expects the master's "name" tag to be appended with "--master".

In the program, used by this one, ClusterInitVariables.pl, $master_name is set to the master's "name" tag.
And, $other_name is set to the "name" tags given to all other instances, e.g. "HPCC-System-20170720", shown
above.
=cut
$ThisDir=($0 =~ /^(.+)[\\\/]/)? $1 : "." ;
require "$ThisDir/ClusterInitVariables.pl";

my ($id,$ip)=getPrivateIPsAndInstanceIDs();
open(OUT,">$instance_id_file") || die "Can't open for output: \"$instance_id_file\"\n";
print OUT join("\n",@$id),"\n";
close(OUT);
open(OUT,">$private_ips_file") || die "Can't open for output: \"$private_ips_file\"\n";
print OUT join("\n",@$ip),"\n";
close(OUT);

# Suspend "Launch", "Terminate", and "HealthCheck" processes for any ASGs.
#print("$ThisDir/suspendASGProcesses.pl\n");
#system("$ThisDir/suspendASGProcesses.pl");
#=====================================================================
sub getPrivateIPsAndInstanceIDs{
print "DEBUG: master_name=\"$master_name\", other_name=\"$other_name\", region=\"$region\"\n";

@other_name=split(/,/,$other_name);

local $t='';
foreach my $other_name (@other_name){
# Get all slave and (possibly roxie) instance descriptions
 $t .= `aws ec2 describe-instances --region $region --filter "Name=tag:Name,Values=$other_name"`;
 $t .= "\n";
}

# Split instances descriptions, $t, into lines.
my @t=split("\n",$t);
my $m_re="\"PrivateIpAddress\":|\"InstanceId\":";
my @x=grep(/$m_re/,@t);
print "DEBUG: All PrivateIpAddress and InstanceId. ",join("\n",@x),"\n";

# Get all slave and (possibly roxie) instance ids
my @id=grep(/\"InstanceId\":/,@x);

# Get all slave and (possibly roxie) private ips
my $id_prefix_spaces=$1 if $id[0] =~ /^(\s*)/;
my @ip=grep(/^$id_prefix_spaces\"PrivateIpAddress\":/,@x);

# Get only master instance description
my $t=`aws ec2 describe-instances --region $region --filter "Name=tag:Name,Values=$master_name"`;
my @t=split("\n",$t);
my $m_re="\"PrivateIpAddress\":|\"InstanceId\":";
my @x=grep(/$m_re/,@t);

# Get master instance id
my ($master_id)=grep(/\"InstanceId\":/,@x);
unshift @id, $master_id; # Put $master_id in $id[0]
# Get master private ip
my ($master_ip)=grep(/^$id_prefix_spaces\"PrivateIpAddress\":/,@x);
unshift @ip, $master_ip; # Put $master_ip in $ip[0]

# Extract just ID
@id=extract('"InstanceId":',@id);
$master_id=shift @id;
@id=grep(!/\b$master_id\b/,@id);
unshift @id,$master_id;

# Extract just IP
@ip=extract('"PrivateIpAddress":',@ip);
$master_ip=shift @ip;
@ip=grep(!/\b$master_ip\b/,@ip);
unshift @ip,$master_ip;

return (\@id,\@ip);
}
#=====================================================================
sub extract{
my ($re,@x)=@_;
my @y=();
foreach (@x){
  my $y=$_;
  if ( /$re \"(.*)\",/ ){
    $y=$1;
  }
  push @y, $y
}
return @y;
}
#=====================================================================
