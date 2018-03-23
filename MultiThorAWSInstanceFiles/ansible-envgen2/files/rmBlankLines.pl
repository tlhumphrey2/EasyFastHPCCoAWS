#!/usr/bin/perl
=pod
rmBlankLines.pl environment.xml
=cut

$file=shift @ARGV;
undef $/;
open(IN,$file) || die "Can't open for input: \"$file\"\n";
$_=<IN>;
close(IN);

@line=split(/\n/,$_);
@line=grep(!/^\s*$/,@line); # Remove any blank lines

goto "CHECKOPTIONS" if $#line == 0;

#-------------------------------------------------------------
# Check for attribute start without any assignments afterwards
#-------------------------------------------------------------
my @line1=();
my $i=0;
for ( ; $i < $#line ; ){
  local $_=$line[$i];
  if ( /^( *)<\w+ *$/ ){
    my $initial_spaces=$1;
    $_.= $line[$i+1];
    s/ {2,}/ /g;
    s/^ */$initial_spaces/;
    $i++;
  }
  push @line1, $_;
  $i++;
}
push @line1, $line[$#line];
@line = @line1;
#-------------------------------------------------------------
# Check for attribute start without any assignments afterwards
#-------------------------------------------------------------

CHECKOPTIONS:
#---------------------------------------------
# Put <Option OR <PreferredCluster on one line
#---------------------------------------------
$option_re='(?:<Option|<PreferredCluster|<RoxieServerProcess)\b';
my @line1=();
my $i=$#line;
my $end_mark='';
for ( ; $i >= 0 ; ){
  local $_=$line[$i];

  if  ( /\/> *$/ ){
    $end_mark=$i;
  }
  elsif ( !/\>/ && ($end_mark =~ /^\d+$/ ) && ( /^( +)($option_re) / ) ){
    my $initial_spaces=$1;
    my $coption=$2;
    for ( my $j=($i+1); $j <= $end_mark; $j++){
      $_ .= $line[$j];
      shift @line1; # Take this line off @line1
    }
    s/\s+/ /g;            # Convert 2 or more spaces to one.
    s/^ +/$initial_spaces/; # Make prefix spaces same as those before $option.
    $end_mark='';
  }
  unshift @line1, $_;
  $i--;
}
@line = @line1;
#---------------------------------------------
# END Put <Option OR <PreferredCluster on one line
#---------------------------------------------

$_=join("\n",@line);

# Check for either '/>' or '>' on a line by itself. If found put it at the end of the previous line.
s/\s*\n\s*(\/?\>\s*\n)/$1/sg;

open(OUT,">${file}") || die "Can't open for output: \"${file}\"\n";
print OUT "$_\n";
close(OUT);
