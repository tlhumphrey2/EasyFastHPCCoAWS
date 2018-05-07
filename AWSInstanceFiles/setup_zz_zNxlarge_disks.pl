#!/usr/bin/perl
@argv=@ARGV;
print "DEBUG: Entering setup_zz_zNxlarge_disks.pl. JUST AFTER 1ST LINE. \@argv=(",join(", ",@argv),")\n";
$ThisDir=($0=~/^(.*)\//)? $1 : ".";
require "$ThisDir/getConfigurationFile.pl";
require "$ThisDir/common.pl";
$sshuser=getSshUser();

# Get all devices
$_=`lsblk`;
@x=split("\n",$_);
@xvdlines=sort grep(/\bxvd[b-z]/,@x);
print "\@xvdlines=(",join(", ",@xvdlines),")\n";

print "DEBUG: In setup_zz_zNxlarge_disks.pl. AFTER require getConfigurationFile.pl. \@ARGV=(",join(", ",@ARGV),")\n";

# If there are command line arguments and the 1st is nummeric or volume id
#  So, 1) if argument is number then make an ebs volume the size given in 1st commandline argument, 2) attach volume to this
#  instance, 3) if argument is number then format file system, and 4) mount it to /var/lib/HPCCSystems
if ( ( scalar(@argv) > 0 ) && (( $argv[0] =~ /^\d+$/ ) || ( $argv[0] =~ /^vol\-/ )) ){
  my $ebssize = shift @argv;
  my $ClusterComponent = shift @argv;
  my $instanceID=`curl http://169.254.169.254/latest/meta-data/instance-id`;
  my $az = getAZ($region,$instanceID);
  my $nextdriveletter=getNextDriveLetter($xvdlines[$#xvdlines]);
  print "DEBUG: AS FOR EBS. ebssize=\"$ebssize\", region=\"$region\", az=\"$az\", nextdriveletter=\"$nextdriveletter\"\n";
  my $v='';
  if ( $ebssize =~ /^\d+$/ ){
    print "aws ec2 create-volume --size $ebssize --region $region --availability-zone $az --volume-type gp2  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=$stackname-$ClusterComponent}]'\n";
    my $makeebs=`aws ec2 create-volume --size $ebssize --region $region --availability-zone $az --volume-type gp2  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=$stackname-$ClusterComponent}]'`;
    print "DEBUG: makeebs=\"$makeebs\"\n";
    $v = ($makeebs=~/"VolumeId"\s*: "(vol-[^"]+)"/)? $1 : '';


  }
  else{
    $v = $ebssize;
    print "aws ec2 create-tags --resources $v --tags Key=Name,Value=$stackname-$ClusterComponent --region $region\n";
    my $changeTag=`aws ec2 create-tags --resources $v --tags Key=Name,Value=$stackname-$ClusterComponent --region $region`;
    print "DEBUG: changeTag=\"$changeTag\"\n";
  }

  local $dev = "/dev/xvd$nextdriveletter";

  # Loop until volume is attached (if instance isn't ready volume won't be attached).
  ATTACHVOLUME:
    print("aws ec2 attach-volume --volume-id $v --instance-id $instanceID --device $dev --region $region &> /home/ec2-user/attach-volume.log\n");
    system("aws ec2 attach-volume --volume-id $v --instance-id $instanceID --device $dev --region $region &> /home/ec2-user/attach-volume.log");
    my $attach_vol=`cat /home/ec2-user/attach-volume.log`;
    $attach_vol =~ s/\n+//g;
    print "DEBUG: attach_vol=\"$attach_vol\"\n";
    sleep(5);
    goto "ATTACHVOLUME" if $attach_vol =~ /IncorrectState/s;

  if ( $ebssize =~ /^\d+$/ ){
    # modify DeleteOnTermination to be true
    print "Change DeleteOnTermination to true\n";
    print("bash /home/ec2-user/DeleteOnTermination2True.sh $instanceID $dev $region\n");
    system("bash /home/ec2-user/DeleteOnTermination2True.sh $instanceID $dev $region");
  }

  my $mountdevice = "/dev/xvd$nextdriveletter";

  # Setup file system ONLY IF $dbssize is numeric which means the volume was just created and therefore needs file system.
  if ( $ebssize =~ /^\d+$/ ){
   print(" mkfs.ext4 $mountdevice\n");
   system(" mkfs.ext4 $mountdevice");
  }

  print(" mkdir -p /var/lib/HPCCSystems &&  mount $mountdevice /var/lib/HPCCSystems\n");
  system(" mkdir -p /var/lib/HPCCSystems &&  mount $mountdevice /var/lib/HPCCSystems");
  print "DEBUG: Leaving EBS processing code.\n";
  exit 0;
}

#----------------------------------------------------------------
# If drives xvd[b-z] exists, then do what is needed to raid, format, and mount them
if ( scalar(@xvdlines) >= 1 ){
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
   if ( scalar(@xvdlines) > 1 ){
     # Do raid
     print("$_\n");
     system("$_");
     $mountdevice="/dev/md0"
   }
   else{
     my $drv=getdrv($xvdlines[0]);
     $mountdevice="/dev/$drv"
   }

   #----------------------------------------------------------------
   print(" yum install xfsprogs.x86_64 -y\n");
   system(" yum install xfsprogs.x86_64 -y");

   #----------------------------------------------------------------
   print(" mkfs.ext4 $mountdevice\n");
   system(" mkfs.ext4 $mountdevice");

   #----------------------------------------------------------------
   print(" mount $mountdevice /mnt\n");
   system(" mount $mountdevice /mnt");

   #----------------------------------------------------------------
   print(" yum install bonnie++.x86_64 -y\n");
   system(" yum install bonnie++.x86_64 -y");

   #----------------------------------------------------------------
   print(" mount -o remount -o noatime /mnt/\n");
   system(" mount -o remount -o noatime /mnt/");

   #----------------------------------------------------------------
   print(" mkdir -p /var/lib/HPCCSystems &&  mount $mountdevice /var/lib/HPCCSystems\n");
   system(" mkdir -p /var/lib/HPCCSystems &&  mount $mountdevice /var/lib/HPCCSystems");
#   print("mkdir -p /mnt/var/lib/HPCCSystems && ln -s  /mnt/var/lib/HPCCSystems  /var/lib/HPCCSystems\n");
#   system("mkdir -p /mnt/var/lib/HPCCSystems && ln -s  /mnt/var/lib/HPCCSystems  /var/lib/HPCCSystems");
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
#----------------------------------------------------------------
sub getNextDriveLetter{
my ($lastxvdline)=@_;
my $lastdrv=getdrv($lastxvdline);
my $lastdrvletter=substr($lastdrv,length($lastdrv)-1);
my $nextdrvletter=++$lastdrvletter;
return $nextdrvletter;
}
#----------------------------------------------------------------
sub getAZ{
my ($region,$instanceID)=@_;
  # Get instance id from metadata
  print "DEBUG: In getAZ. instanceID=\"$instanceID\"\n";
  # Use describe-instance to get az
  local $_=`aws ec2 describe-instances --instance-ids $instanceID --region $region --output table|egrep -i availability|sed "s/^.*us-/us-/"`;
  my $az=(/(\S+)/)? $1 : $_;
  return $az;
}
