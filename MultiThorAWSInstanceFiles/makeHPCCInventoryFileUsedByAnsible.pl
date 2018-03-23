#!/usr/bin/perl
$ThisDir=($0=~/^(.*)\//)? $1 : ".";
print "DEBUG: Entering makeHPCCInventoryFileUsedByAnsible.pl. ThisDir=\"$ThisDir\". \@ARGV=(",join(" ",@ARGV),").\n";

require "$ThisDir/getConfigurationFile.pl";
require "$ThisDir/cf_common.pl";
require "$ThisDir/common.pl";

=pod
makeHPCCInventoryFileUsedByAnsible.pl -ripr "2,2" -outfile inventory_for_2_roxies_no_thors.yml
makeHPCCInventoryFileUsedByAnsible.pl -sipt "1,1" -snpipt "3,4" -ripr "1,1" -outfile inventory_for_2_thors_2_roxies.yml
makeHPCCInventoryFileUsedByAnsible.pl -sipt "1,1" -snpipt "10,5" -ripr "2" -outfile inventory_for_2_thors_snpipt_10:5_1_roxie.yml
makeHPCCInventoryFileUsedByAnsible.pl -sipt "2,1" -snpipt "1,1" -outfile inventory_for_2_thors_snpipt_1:1_no_roxies.yml

THE INVENTORY FILE CREATED BY THIS PROGRAM WILL LOOK SOMETHING LIKE THE FOLLOWING:
[master]
master_01
master_02

[master_01]
10.0.0.113

[master_02]
10.0.0.81

[thor]
thor_01 name="thor_01"
thor_02 name="thor_02"

[thor_01]
10.0.0.6
10.0.0.53

[thor_02]
10.0.0.124

[dali]
dali_01 name="dali_01"

[dali_01]
10.0.0.221

=cut

#================== Get Input Arguments ================================
require "newgetopt.pl";
if ( ! &NGetOpt(
                "cfg=s", "sipt=s", "snpipt=s", "ripr=s", "outfile=s"
                ))      # Add Options as necessary
{
  print STDERR "\n[$0] -- ERROR -- Invalid/Missing options...\n\n";
  exit(1);
}
$ClusterInventoryFile         = $opt_cfg || '';
$SlaveInstancesPerTHOR        = $opt_sipt || 0;
@sipt=split(/,/,$SlaveInstancesPerTHOR);
$RoxieInstancesPerROXIE       = $opt_ripr || 0;
@ript=split(/,/,$RoxieInstancesPerROXIE);
die "USAGE ERROR: $0. NO THORs or ROXIEs specified. MUST have at least one THOR or one ROXIE.\n" if ($SlaveInstancesPerTHOR==0) && ($RoxieInstancesPerROXIE==0);
$SlaveNodesPerInstancePerTHOR = $opt_snpipt || '';
$outfile                      = $opt_outfile || "$ThisDir/my_inventory.yml";

@ips=();
@labels=();
@master_ips=();
@slave_ips=();
@roxie_ips=();
@support_ips=();
@snpi=();

# Fill the above 7 arrays and return the number of IPs.
$nIPs=IpArraysByComponent($private_ips,$ip_labels);

$NumberOfMasters = scalar(@master_ips);
print "DEBUG: \@ips size is ",scalar(@ips),", \@labels size is ",scalar(@labels),", \@master_ips size is ",scalar(@master_ips),", \@slave_ips size is ",scalar(@slave_ips),", \@roxie_ips size is ",scalar(@roxie_ips),", \@support_ips size is ",scalar(@support_ips),", NumberOfMasters=\"$NumberOfMasters\".\n";
$IpsNeeded=sumNeededTHORAndROXIEInstances($SlaveInstancesPerTHOR, $RoxieInstancesPerROXIE) + $NumberOfMasters;
die "FATAL ERROR: In $0. Number of Instances started ($nIPs) DOES NOT meet the number of instances needed ($IpsNeeded) by the cluster."
    if $nIPs < $IpsNeeded;
#===============END Get Input Arguments ================================
@support_component=('dropzone','dali','dfuserver','eclcc','eclagent','eclscheduler','sasha'); # HAS eclcc and NO 'esp'.
#@support_component=('dropzone','dali','dfuserver','eclcc','eclagent','eclscheduler','sasha','esp'); # HAS eclcc
#@support_component=('dropzone','dali','dfuserver','eclserver','eclagent','eclscheduler','sasha','esp'); # HAS eclserver


if (( $ClusterInventoryFile eq '' ) || ( $ClusterInventoryFile eq 'NONE' )){

  open(OUT,">$outfile") || die "Can't open for output: \"$outfile\"\n";

  #------------------------------
  # Put masters in inventory file
  #------------------------------
  @mname=();
  @mip=();
  my $j=0;
  for( my $i=1; $i <= $NumberOfMasters; $i++){
   print OUT "\[master\]\n" if $i==1;
   my $master_name=sprintf "master_%02d", $i;
   push @mname, $master_name;
   push @mip, $master_ips[$j];
   $j++;
   print OUT "$master_name name=\"$master_name\"\n";
  }
  print OUT "\n";
  
  # Add IPs of each Master
  for( my $i=0; $i < scalar(@mname); $i++){
    print OUT "\[$mname[$i]\]\n";
    print OUT "$mip[$i]\n\n";
  }

  #------------------------------
  # Put slaves in inventory file
  #------------------------------
  @sname=();
  @sip=();
  for( my $i=0; $i < scalar(@slave_ips); $i++){
   print OUT "\[thor\]\n" if $i==0;
   my $thor_name=sprintf "thor_%02d", $i+1;
   push @sname, $thor_name;
   push @sip, $slave_ips[$i];
   print OUT "$thor_name name=\"$thor_name\" slavesPerNode=\"$snpi[$i]\"\n";
  }
  print OUT "\n";
  
  # Add IPs of each slave
  for( my $i=0; $i < scalar(@sname); $i++){
    print OUT "\[$sname[$i]\]\n";
    foreach my $sip (@{$slave_ips[$i]}){
      print OUT "$sip\n";
    }
    print OUT "\n";
  }

  #------------------------------
  # Put roxies in inventory file
  #------------------------------
  @rname=();
  @rip=();
  for( my $i=0; $i < scalar(@roxie_ips); $i++){
   print OUT "\[roxie\]\n" if $i==0;
   my $roxie_name=sprintf "roxie_%02d", $i+1;
   push @rname, $roxie_name;
   push @rip, $roxie_ips[$i];
   print OUT "$roxie_name name=\"$roxie_name\"\n";
  }
  print OUT "\n";
  
  # Add IPs of each roxie
  for( my $i=0; $i < scalar(@rname); $i++){
    print OUT "\[$rname[$i]\]\n";
    foreach my $rip (@{$roxie_ips[$i]}){
      print OUT "$rip\n";
    }
    print OUT "\n";
  }

  #------------------------------
  # Put support components in inventory file
  #------------------------------
  my $support_ip=$mip[0];
  if ( scalar(@support_ips)>=1 ){
    $support_ip=$support_ips[0];
  }

  # Add IPs of each component
  foreach my $sc (@support_component){
   print OUT "\[$sc\]\n";
   my $name=sprintf "${sc}_%02d", 1;
   print OUT "$name name=\"$name\"\n\n";
   print OUT "\[$name\]\n";
   print OUT "$support_ip\n\n";
  }

  close(OUT);
  print "Outputting: $outfile\n";

}
else{
  die "In $0. A cluster configuration file was given, $ClusterInventoryFile, but this option is NOT YET IMPLEMENTED.";
}
#=================================================================
sub calcNumberOfTHORs{
my ($SlaveInstancesPerTHOR)=@_;
return scalar(split(/,/,$SlaveInstancesPerTHOR));
}
#=================================================================
sub IpArraysByComponent{
my ($private_ips,$ip_labels)=@_;
print "DEBUG: Entering IpArraysByComponent. private_ips=\"$private_ips\", ip_labels=\"$ip_labels\"\n";
  # Get all private IPs
  my $nIPs=0;
  open(PRI,"$private_ips") || die "CANNOT open for input, \"$private_ips\"\n";
  while(<PRI>){
     chomp;
     if ( /^\s*\d+(?:\.\d+){3}\s*$/ ){
       $nIPs+=1;
       push @ips, $_;
     }
  }
  close(PRI);

  # Get all labels for private Ips
  open(LAB,"$ip_labels") || die "CANNOT open for input, \"$ip_labels\"";
  while(<LAB>){
     chomp;
     if ( ! /^\s*$/ ){
       push @labels, $_;
     }
  }
  close(LAB);

  # Fill 6 arrays (@ips, @labels, @master_ips, @slave_ips, @roxie_ips, @support_ips)
  for( my $i=0; $i < scalar(@labels); $i++){
    local $_=$labels[$i];
    print "DEBUG: labels\[$i\]=\"$labels[$i]\", ips\[$i\]=\"$ips[$i]\"\n";
    if ( /Master/ ){
      push @master_ips, $ips[$i];
    }
    elsif ( /Slave/ ){
      push @sips, $ips[$i];
    }
    elsif ( /Roxie/ ){
      push @rips, $ips[$i];
    }
    elsif ( /Support/ ){
      push @support_ips, $ips[$i];
    }
    else{
      print STDERR "Label $i, \"$_\", MUST BE either 'Master', 'Slave', 'Roxie', or 'Support'.\n";
    }
  }

  # Are there enough slave ips?
  my $needed=sumNeededInstances($SlaveInstancesPerTHOR);
  die "FATAL ERROR: In IpArraysByComponent. Not enough slave instances, ",scalar(@sips),", for what was asked for \"$SlaveInstancesPerTHOR\"\n" if scalar(@sips)<$needed;
  my $needed=sumNeededInstances($RoxieInstancesPerROXIE);
  die "FATAL ERROR: In IpArraysByComponent. Not enough roxie instances, ",scalar(@rips),", for what was asked for \"$RoxieInstancesPerROXIE\"\n" if scalar(@rips)<$needed;

  # Distribute IPs to appropriate thor
  @slave_ips=distributeIPs(\@sips,$SlaveInstancesPerTHOR);


  # Distribute IPs to appropriate roxie
  @roxie_ips=distributeIPs(\@rips,$RoxieInstancesPerROXIE);

  # Fill array, @snpi.
  # if SlaveNodesPerInstancePerTHOR is blank, 0 or 1
  if ( $SlaveNodesPerInstancePerTHOR =~ /^[01]|\s*$/ ){
    foreach (@master_ips){
      push @snpi, 1;
    }
  }
  # if SlaveNodesPerInstancePerTHOR is a single non-zero number
  elsif ( $SlaveNodesPerInstancePerTHOR =~ /^(\d+)$/ ){
    my $n=$1;
    foreach (@master_ips){
      push @snpi, $n;
    }
  }
  else{
    @snpi=split(/,/,$SlaveNodesPerInstancePerTHOR);
  }

  return $nIPs;
}
#=================================================================
sub distributeIPs{
my ($ips,$needed)=@_;
  my @distributed_ips=();
  my @ineeded=split(/,/,$needed);

  my $k=0;
  for( my $i=0; $i < scalar(@ineeded); $i++){
    my $n=$ineeded[$i];
    for( my $j=0; $j < $n; $j++){
      push @{$distributed_ips[$i]}, $$ips[$k];  
      $k++;
    }
  }
  return @distributed_ips;
}
#=================================================================
sub CorrectNumberOfIps{
my ($private_ips, $SlaveInstancesPerTHOR, $RoxieInstancesPerROXIE, $NumberOfSupportInstances)=@_;
  my $IpsNeeded=sumNeededTiiHORAndROXIEInstances($SlaveInstancesPerTHOR, $RoxieInstancesPerROXIE) + $NumberOfMasters;
  my $nIPs=0;
  open(IN,"$private_ips") || die "CANNOT open for input, \"$private_ips\"";
  while(<IN>){
     chomp;
     $nIPs+=1 if /^\s*\d+(?:\.\d+){3}\s*$/;
  }
  close(IN);
  
  my $rc = ($nIps>=$IpsNeeded)? 1 : 0 ;
  return $rc;
}
#=================================================================
sub sumNeededInstances{
my ($ListOfInstances)=@_;
  my @ninstances = split(/,/,$ListOfInstances);
  my $NeededInstances=0;
  foreach my $i (@ninstances){
    $NeededInstances += $i;
  }

  return $NeededInstances;
}
#=================================================================
sub sumNeededTHORAndROXIEInstances{
my ($SlaveInstancesPerTHOR, $RoxieInstancesPerROXIE)=@_;
  return sumNeededInstances($SlaveInstancesPerTHOR)+sumNeededInstances($RoxieInstancesPerROXIE);
}
#=================================================================

