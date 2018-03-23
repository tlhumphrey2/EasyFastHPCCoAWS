#!/bin/bash -e
j2file=$1;
bin=`dirname $0`;
b=`basename $j2file`;
templatefile="$j2file.template";
$bin/replaceWithJinja2Required2.pl $templatefile > $j2file;
$bin/rmPrefixSpacesJ2.pl $j2file > t;
mv t $j2file;
