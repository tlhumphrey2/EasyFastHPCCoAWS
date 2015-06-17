#!/usr/bin/perl

# Get all devices
$_=`lsblk`;
@x=split("\n",$_);
@xvdlines=grep(/\bxvd[b-z]/,@x);
print "\@xvdlines=(",join(", ",@xvdlines),")\n";

#----------------------------------------------------------------
# If drives xvd[b-z] exists, then do what is needed to raid, format, and mount them
if ( scalar(@xvdlines) > 1 ){
   # umount devices that are mounted
   foreach (@xvdlines){
      # check to see if drive should be umounted
      my $drv=getdrv($_);
      push @drv, $drv;

      if ( /disk\s+[^\s]/ ){
         print(" umount /dev/$drv\n");
         system(" umount /dev/$drv");
      }
   }

   #----------------------------------------------------------------
   # MAKE raid command which, in $raid_template, replacing <ndrives> and <driveletters> with appropriate values.
   $raid_template=" mdadm --create /dev/md0 --run --assume-clean --level=0 --chunk=2048 --raid-devices=<ndrives> /dev/xvd[<driveletters>]";
   $ndrives=scalar(@drv);
   @driveletters=map(getsfx($_),@xvdlines);
   $driveletters=join('',@driveletters);
   $_=$raid_template;
   s/<ndrives>/$ndrives/;
   s/<driveletters>/$driveletters/;

   #----------------------------------------------------------------
   # Do raid
   print("$_\n");
   system("$_");

   #----------------------------------------------------------------
   print(" yum install xfsprogs.x86_64 -y\n");
   system(" yum install xfsprogs.x86_64 -y");

   #----------------------------------------------------------------
   print(" mkfs.xfs /dev/md0\n");
   system(" mkfs.xfs /dev/md0");

   #----------------------------------------------------------------
   print(" mount /dev/md0 /mnt\n");
   system(" mount /dev/md0 /mnt");

   #----------------------------------------------------------------
   print(" yum install bonnie++.x86_64 -y\n");
   system(" yum install bonnie++.x86_64 -y");

   #----------------------------------------------------------------
   print(" mount -o remount -o noatime /mnt/\n");
   system(" mount -o remount -o noatime /mnt/");

   #----------------------------------------------------------------
   print(" mkdir -p /var/lib/HPCCSystems &&  mount /dev/md0 /var/lib/HPCCSystems\n");
   system(" mkdir -p /var/lib/HPCCSystems &&  mount /dev/md0 /var/lib/HPCCSystems");
}
#----------------------------------------------------------------
# SUBROUTINES
#----------------------------------------------------------------
sub getdrv{
my ($l)=@_;
  local $_=$l;
  s/^\s*(xvd.).+$/$1/;
print "Leaving getdrv. return \"$_\"\n";
return $_;
}
#----------------------------------------------------------------
sub getsfx{
my ($l)=@_;
  local $_=$l;
  s/^\s*xvd(.).+$/$1/;
print "Leaving getsfx. return \"$_\"\n";
return $_;
}
