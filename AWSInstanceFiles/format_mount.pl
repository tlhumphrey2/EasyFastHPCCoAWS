#!/usr/bin/perl
$ThisDir=($0=~/^(.*)\//)? $1 : ".";
=pod
format_mount.pl xvdf ~/deeplearning-cats-dogs-tutorial-back
=cut

$device=shift @ARGV;
$mountpoint=shift @ARGV;

print("sudo apt-get install xfsprogs -y\n");
system("sudo  apt-get install xfsprogs -y");

#----------------------------------------------------------------
# Construct XFS filesystem on $devic
print("sudo mkfs.xfs /dev/$device\n");
system("sudo mkfs.xfs /dev/$device");

#----------------------------------------------------------------
print("sudo mount /dev/$device $mountpoint\n");
system("sudo mount /dev/$device $mountpoint");
