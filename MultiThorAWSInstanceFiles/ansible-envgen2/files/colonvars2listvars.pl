#!/usr/bin/perl
=pod

files/colonvars2listvars.pl -debug -outfile test_example_tlh_environment.yml inventories/example_tlh_environment.yml.pre &> colonvars2listvars.log
../files/colonvars2listvars.pl example_tlh_environment.yml
../files/colonvars2listvars.pl example_tlh_environment.yml.pre 

EXAMPLE INPUT
[ldap]
prod_ldap
roxie_qa_ldap
10.0.0.01

[prod_ldap:vars]
filesBasedn="ou=Files,ou=ecl"
groupsBasedn="ou=groups,ou=ecl,dc=internal,dc=sds"
modulesBasedn="ou=prod_hql,ou=prod_ecl,dc=internal,dc=sds"
sudoersBasedn="ou=SUDOers"
systemBasedn="cn=Users,dc=internal,dc=sds"
systemPassword="blanked"
systemUser="in_ternal"
usersBasedn="ou=users,ou=ecl,dc=internal,dc=sds"
workunitsBasedn="ou=workunits,ou=prod_ecl"

[roxie_qa_ldap:vars]
filesBasedn="ou=Files,ou=ecl"
groupsBasedn="ou=groups,ou=ecl,dc=internal,dc=sds"
modulesBasedn="ou=adl_roxie_qa,ou=prod_ecl,dc=internal,dc=sds"
sudoersBasedn="ou=SUDOers"
systemBasedn="cn=Users,dc=internal,dc=sds"
systemPassword="blanked"
systemUser="in_ternal"
usersBasedn="ou=users,ou=ecl,dc=internal,dc=sds"
workunitsBasedn="ou=workunits,ou=ecl"

=cut

$debug=0;
$options="(?:-debug|-outfile)";
while ( $ARGV[0] =~ /^($options)$/ ){
  my $a=$1;
  if ( $a eq "-debug" ){
    shift @ARGV;
    $debug=1;
  }
  elsif  ( $a eq "-outfile" ){
    shift @ARGV;
    $outfile=shift @ARGV;
  }
}

#-------------------------------------------
# Input inventory file
#-------------------------------------------
print "DEBUG: Input file is \"$ARGV[0]\"\n" if $debug;

if ( $ARGV[0] !~ /\.yml$/ ){
   die "EXIT WITH ERROR. INVENTORY FILE MUST HAVE THE EXTENSION, .yml, AND IT DOES NOT ($ARGV[0]).\n";
}

# if .pre file exists then use it. Otherwise use inputted file (without .pre ext).
$infile= ( -e "$ARGV[0].pre" )? "$ARGV[0].pre" : $ARGV[0];

print "DEBUG: In $0. \$ARGV\[0\]=\"$ARGV[0]\"\n" if $debug;

if ( ! -e $infile ){ # .pre file DOES NOT EXIST.
  if ( ! -e $ARGV[0] ){ # .yml file DOES NOT EXIST.
   die "EXIT WITH ERROR. NEITHER .pre FILE NOR THE INPUTTED FILE, \"$ARGV[0]\", EXIST.\n";
  }
}

print "DEBUG: In $0. EXISTS infile=\"$infile\"\n" if $debug;

# Read in all of the .pre file
undef $/;
open(IN,$infile) || die "Can't open for input: \"$infile\"\n";
$_=<IN>;
close(IN);

# Split into lines
@inline=split(/\n/,$_);

#----------------------------------------------------------------------------
# Get list of groups in @ListOfGroups and vars of groups in @varsOfGroup
#----------------------------------------------------------------------------
$name_re='[a-zA-Z]\w*';
$ip_re='\d+\.\d+\.\d+\.\d+';
$gmember_re='(?:'. $name_re .'|'. $ip_re .')\n';
# Names of groups whose colon:vars list will be placed after its name.
@ListOfGroups=grep(s/^($name_re)\s*$/$1/,@inline);              #A group name will appear on a line by itself.
@varsOfGroup=m/\[$name_re:vars\]\n(?:$name_re=".*?"\n)+/sg;     #One entry of @varsOfGroups will contain the name of the group and all variables of it.

print "DEBUG: First few entries in \@ListOfGroups=(",join(", ",@ListOfGroups[0..3]),").\n" if $debug;

$group_re='(?:'.join("|",unique(@ListOfGroups)).')';           #Regular expression (or list) of all group names.
print "DEBUG: group_re=\"$group_re\"\n" if $debug;

exit 0 if scalar(@varsOfGroup)==0; # There where NO groups with colon vars. So exit with changing anything.
#-----------------------------------------------------------------------------------------------------------------------------------------
# Get names of all groups with vars in @gname. And, all vars for each group in $vars{$gname}, where $gname contains the name of the group
#-----------------------------------------------------------------------------------------------------------------------------------------

@vgroup=();
%vgroup=();
foreach (@varsOfGroup){
  s/\n$//;
  my @l=split(/\n/,$_);           # Split into lines where 1st will contain group name and the rest are variables and their values.

  # Get line containing group name and isolate group name
  my $vgroup=shift @l;            # Get line with group name
  $vgroup =~ s/[\[\]]//g;         # Remove brackets
  $vgroup =~ s/:vars$//;          # Remove ':vars' leaving just the group name
  if ( exists($vgroup{$vgroup}) ){# This group name should only appear once in inventory file
    die "EXIT WITH ERROR: THE GROUP WITH \":vars\", i.e. \"$vgroup\" APPEARS MORE THAN ONCE. NOT ALLOWED!";
  }
  else{
    push @vgroup, $vgroup;
    $vgroup{$vgroup}=1;
  }
print "DEBUG: In \@varsOfGroup loop. vgroup=\"$vgroup\"\n" if $debug;
  $vars{$vgroup}=join(" ",@l);   # Put all its variables in $vars{$vgroup}.
}
print "DEBUG: Size of \@varsOfGroup is ",scalar(@varsOfGroup),": (",join(",",@vgroup),")\n" if $debug;

$vgroup_re='(?:'.join("|",@vgroup).')';  # MAKE regular (or) expression with all group names
print "DEBUG: vgroup_re=\"$vgroup_re\"\n" if $debug;

# For each vgroup, mark $VarsAppendedAfterGroupName is false. This enables us to check if were vgroups that didn't get their vars appended.
foreach (@vgroup){
  $VarsAppendedAfterGroupName{$_}=0;
}
#-----------------------------------------------------------------------------------------------------------------------------------------
# Read each line of the input file. Find group names that have :vars and put these on same line with group name
#-----------------------------------------------------------------------------------------------------------------------------------------
$FoundColonVarsLine=0;
$FoundAtLeastOneGroupWithColonVars=0;
@outline=();
foreach (@inline){
  print "DEBUG: line=\"$_\"\n" if $debug;
  if ( /^($vgroup_re)\s*$/ ){             # Found group name on a line by itself.
     my $vgroup=$1;
     push @outline, listVarsAfterGroupName($vgroup);
     if ( $outline[$#outline] =~ /^$vgroup $name_re=/ ){
       $FoundAtLeastOneGroupWithColonVars=1;
       $VarsAppendedAfterGroupName{$vgroup}=1;
     }
    $FoundColonVarsLine=0;
  }
  elsif ( /\[($vgroup_re):vars\]\s*$/ ){  # Found the beginning of group:vars.
    $curvgroup=$1;
    print "DEBUG: Found start vars of a subgroup, curvgroup=\"$curvgroup\"\n" if $debug;
    $FoundColonVarsLine=1;
  }
  elsif ( $FoundColonVarsLine && /^\w+=".*"$/ ){ # Found variable and value after colon var line.
    print "DEBUG: Found assignment statement, \"$_\", of a vars group, curvgroup=\"$curvgroup\"\n" if $debug;
  }
  elsif ( $FoundColonVarsLine && /^\s*$/ ){ # Found blank line after colon vars.
    print "DEBUG: Found END of assignment statements of vars group, curvgroup=\"$curvgroup\"\n" if $debug;
    $FoundColonVarsLine=0;
    undef $curvgroup;
    push @outline, "";
  }
  else{
    push @outline, $_;
    $FoundColonVarsLine=0;
    undef $curvgroup;
  }
}

exit 0 if ! $FoundAtLeastOneGroupWithColonVars; 

# Check to see if any var groups did NOT get their vars appended after their names.
$AllWereAppended=1;
foreach (@vgroup){
  if ( $VarsAppendedAfterGroupName{$_}==0 ){
    $AllWereAppended=0;
    print STDERR "ERROR: Group name, $_, WAS NOT FOUND ON A LINE BY ITSELF. SO ITS VARS WERE NOT APPENDED: i.e. \"$vars{$_}\"\n"; 
  }
}

exit 1 if $AllWereAppended==0;

#-----------------------------------------------------------------------------------------------------------------------------------------
# Output all lines of created inventory file
#-----------------------------------------------------------------------------------------------------------------------------------------
$_=join("\n",@outline);
s/\n\n\n+/\n\n/sg;
if ( $outfile =~ /^\s*$/ ){
  $outfile="$infile";
  $outfile=~ s/\.pre$//;
}

if ( length($_) > 0 ){
 open(OUT,">$outfile") || die "Can't open for output: \"$outfile\"\n";
 print OUT "$_\n";
 close(OUT);
 print "DEBUG: Outputting: $outfile\n" if $debug;
}
else{
   die "EXIT WITH ERROR. OUTPUT FILE, $outfile, IS EMPTY.\n";
}
#======================================================================
#======================================================================
sub unique{
my (@group)=@_;
my %group=();
my @reduced_group=();
  foreach my $g (@group){
    if ( exists($group{$g}) ){
       print "ERROR: The group, \"$g\" appears more than once in the inputted inventory template.\n";
    }
    else{
       $group{$g}=1;
       push @reduced_group, $g;
    }
  }
return @reduced_group;
}
#======================================================================
sub listVarsAfterGroupName{
my ($vgroup)=@_;
print "DEBUG: Entering makeGroupOutlines. vgroup=\"$vgroup\"\n" if $debug;
  my $newline=$vgroup;
  if ( exists($vars{$vgroup}) ){
    $newline .=" $vars{$vgroup}";
  }
return $newline;
}
