#!/usr/bin/perl
$ThisDir=($0=~/^(.*)\//)? $1 : ".";
=pod
configureCassandra.pl 
=cut

$cassandra_yaml="/etc/cassandra/conf/cassandra.yaml";
open(IN,$cassandra_yaml) || die "Can't open for input \"$cassandra_yaml\"\n";

$thisDir = ( $0 =~ /^(.+)\// )? $1 : '.';

require "$thisDir/getConfigurationFile.pl";
require "$thisDir/cp2s3_common.pl";

($master_pip, @slave_pip)=thor_nodes_ips();
$all_private_ips=join(",",($master_pip, @slave_pip));
$ThisInstancePrivateIP = get_this_nodes_private_ip();


$re='^.*\b(cluster_name|initial_token|seeds|rpc_address|listen_address|rpc_port|broadcast_rpc_address|endpoint_snitch):';

$re{cluster_name}="s/(: *)'[^']+'/\$1'$stackname'/";
$re{initial_token}="s/^.*initial_token:.*/initial_token: 0/";
$re{seeds}="s/(: *)\"[^'\"]+\"/\${1}\"$all_private_ips\"/";
$re{listen_address}="s/(: *)[^'\"]+/\${1}$ThisInstancePrivateIP/";
$re{rpc_address}="s/(: *)[^'\"]+/\${1}0.0.0.0/";
$re{rpc_port}="s/(: *)[^'\"]+/\${1}9160/";
$re{broadcast_rpc_address}="s/^.*broadcast_rpc_address:/broadcast_rpc_address:/";
$re{endpoint_snitch}="s/(: *)[^'\"]+/\${1}Ec2Snitch/";

while(<IN>){
   chomp;
   if ( /$re/ ){
      my $p=$1;
      eval($re{$p});
      print "DEBUG:$_\n";
   }
   
   push @line,$_;
}
close(IN);

open(OUT,">$thisDir/c.yaml") || die "Can't open for output \"$thisDir/c.yaml\"\n";
print OUT join("\n",@line),"\n";
close(OUT);
print "In configCassandra.pl: outputted to $thisDir/c.yaml\n";

print("cp $thisDir/c.yaml /etc/cassandra/conf/cassandra.yaml\n");
system("cp $thisDir/c.yaml /etc/cassandra/conf/cassandra.yaml");
