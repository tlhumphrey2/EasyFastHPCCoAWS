#!/usr/bin/perl
$ThisDir=($0=~/^(.*)\//)? $1 : ".";
=pod
./chgSlavesPerNode.pl 01slavesPerNode-5slave-instances-environment.xml 10
=cut
$xmlfile=shift @ARGV || die "Usage Error $0 FILE NAME MUST be 1st argument on commandline.\n";
$nSlaves=shift @ARGV || die "Usage Error $0 NUMBER OF SLAVES MUST be 2nd argument on commandline.\n";
die "Usage Error $0, 2nd argment WAS NOT NUMERIC ($nSlaves).\n" if $nSlaves !~ /^\d+$/; 
$outfile="tmp-$xmlfile";
undef $/;
open(IN,$xmlfile) || die "Can't open for input: \"$xmlfile\".\n";
$_=<IN>;
close(IN);

s/slavesPerNode="\d+"/slavesPerNode="$nSlaves"/;

open(OUT,">$outfile") || die "Can't open for output: \"$outfile\"\n";
print OUT $_;
close(OUT);
print "Outputting $outfile\n";
