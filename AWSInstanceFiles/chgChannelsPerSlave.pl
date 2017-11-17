#!/usr/bin/perl
$ThisDir=($0=~/^(.*)\//)? $1 : ".";
$xmlfile=shift @ARGV || die "Usage Error $0 FILE NAME MUST be 1st argument on commandline.\n";
$nChannels=shift @ARGV || die "Usage Error $0 NUMBER OF CHANNELS MUST be 2nd argument on commandline.\n";
die "Usage Error $0, 2nd argment WAS NOT NUMERIC ($nChannels).\n" if $nChannels !~ /^\d+$/; 
$outfile="tmp-$xmlfile";
undef $/;
open(IN,$xmlfile) || die "Can't open for input: \"$xmlfile\".\n";
$_=<IN>;
close(IN);

s/channelsPerSlave="\d+"/channelsPerSlave="$nChannels"/;

open(OUT,">$outfile") || die "Can't open for output: \"$outfile\"\n";
print OUT $_;
close(OUT);
print "Outputting $outfile\n";
