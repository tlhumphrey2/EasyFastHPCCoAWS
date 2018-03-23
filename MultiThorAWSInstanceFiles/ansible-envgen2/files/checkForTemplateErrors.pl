#!/usr/bin/perl
=pod
checkForTemplateErrors.pl environment.xml
=cut
die "NO environment.xml file WAS CREATED" if ($ARGV[0] =~ /^\s*$/) || ( ! -e $ARGV[0]) || (`cat $ARGV[0]` =~ /^\s*$/);
undef $/;
$_=<>;
@line=split(/\n/,$_);
@error=grep(/ANSIBLE TEMPLATE ERROR/,@line);
if ( scalar(@error) > 0 ){
  print STDERR join("\n",@error),"\n";
  exit 1; 
}
