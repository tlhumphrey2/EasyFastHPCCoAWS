#!/usr/bin/perl
=pod
....key="Tags":
.....GROUP[0]
......key=Key, value=aws:cloudformation:stack-id
......key=Value, value=arn:aws:cloudformation:us-east-2:123456789012:stack/test-inventory-file-2/837cfc80-1afb-11e8-b85a-503f3157b035
.....GROUP[1]
......key=Key, value=aws:autoscaling:groupName
......key=Value, value=test-inventory-file-2-InstanceASG-E3RA2FQJH4IL
.....GROUP[2]
......key=Key, value=UserNameAndPassword
......key=Value, value=
=cut

while(<STDIN>){
  chomp;
  if ( /^\.\.\.\.key="Tags":/ ){
    print "$_\n";
    my @tag=();
    $_=<STDIN>; chomp;
    while( /^\.\.\.\.\.GROUP\b/ ){
      $_=<STDIN>; chomp;
      my $tagname=$1 if / value=(.*)/;
      $_=<STDIN>; chomp;
      my $value=$1 if / value=(.*)/;
      $_=<STDIN>; chomp;
      push @tag,".....tagname=$tagname, value=$value";
    }
    print join("\n",@tag),"\n";
  }
  else{
    print "$_\n";
  }
}
