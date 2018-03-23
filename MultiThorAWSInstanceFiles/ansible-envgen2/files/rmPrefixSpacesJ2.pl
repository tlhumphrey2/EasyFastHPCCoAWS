#!/usr/bin/perl

while(<>){
  if ( /^ +(?:\{[\%#\{]|ANSIBLE TEMPLATE ERROR:)/ ){
    s/^ +//;
  }
  print $_;
}
