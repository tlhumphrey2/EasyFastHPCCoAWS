#!/usr/bin/perl
@argv=@ARGV;
print "DEBUG: Entering setup_zz_zNxlarge_disks.pl. JUST AFTER 1ST LINE. \@argv=(",join(", ",@argv),")\n";
$ThisDir=($0=~/^(.*)\//)? $1 : ".";
require "$ThisDir/getConfigurationFile.pl";
require "$ThisDir/common.pl";
$sshuser=getSshUser();

# Get all lsblk lines with non-root device lines.
@xvdlines=get_lsblk_xvdlines();
local $nextdriveletter=(scalar(@xvdlines)>0)? getNextDriveLetter($xvdlines[$#xvdlines]) : 'b';
print "DEBUG: nextdriveletter=\"$nextdriveletter\"\n";

print "DEBUG: In setup_zz_zNxlarge_disks.pl. AFTER require getConfigurationFile.pl. \@ARGV=(",join(", ",@ARGV),")\n";

$sixteenTB=16384;

# If there are command line arguments and the 1st is nummeric or volume id
#  So, 1) if argument is nummeric then make an ebs volume the size given in 1st commandline argument, 2) attach volume to this
#  instance
if ( ( scalar(@argv) > 0 ) && (( $argv[0] =~ /^\d+$/ ) || ( $argv[0] =~ /^vol\-/ )) ){
  $ebssize = shift @argv;
  local $ClusterComponent = shift @argv;
  local $instanceID=`curl http://169.254.169.254/latest/meta-data/instance-id`;
  local $az = getAZ($region,$instanceID);
  print "DEBUG: AS FOR EBS. ebssize=\"$ebssize\", region=\"$region\", az=\"$az\", nextdriveletter=\"$nextdriveletter\"\n";
  local $v='';
  local @Volume2Attach=();
  @xvdlines=();
  if ( $ebssize =~ /^\d+$/ ){
    # if volume size <= 16TB, which is maximum allowable size of single EBS volume.
    if ( $ebssize <= $sixteenTB ){
      my $v=makeEBSVolume($ebssize);
      push @Volume2Attach, $v;
      push @xvdlines, "xvd$nextdriveletter";
    }
    # Multiply ebs volumes must be made because $ebssize > 16TB.
    else{
      my $save_ebssize=$ebssize;
      my $v=makeEBSVolume($sixteenTB);
      push @Volume2Attach, $v;
      push @xvdlines, "xvd$nextdriveletter";
      $ebssize = $ebssize-$sixteenTB;
      while ( $ebssize > $sixteenTB ){
        $nextdriveletter++;
        my $v=makeEBSVolume($sixteenTB);
        push @Volume2Attach, $v;
        push @xvdlines, "xvd$nextdriveletter";
        $ebssize = $ebssize-$sixteenTB;
      }
      if ( $ebssize > 0 ){
        $nextdriveletter++;
        my $v=makeEBSVolume($ebssize);
        push @Volume2Attach, $v;
        push @xvdlines, "xvd$nextdriveletter";
      }
      $ebssize = $save_ebssize;
    }
  }
  else{
    $v = $ebssize;
    print "aws ec2 create-tags --resources $v --tags Key=Name,Value=$stackname-$ClusterComponent --region $region\n";
    my $changeTag=`aws ec2 create-tags --resources $v --tags Key=Name,Value=$stackname-$ClusterComponent --region $region`;
    print "DEBUG: changeTag=\"$changeTag\"\n";
    push @Volume2Attach, $v;
    push @xvdlines, "xvd$nextdriveletter";
  }

  # Attach all ebs volumes
  for (my $i=0; $i < scalar(@xvdlines); $i++){
    my $v=$Volume2Attach[$i];
    my $dev = $xvdlines[$i];

    #-------------------------------------------------------------------------------------------------------------------------
    # Loop until volume is attached (if instance isn't ready volume won't be attached).
    ATTACHVOLUME:
     print("aws ec2 attach-volume --volume-id $v --instance-id $instanceID --device $dev --region $region &> /home/ec2-user/attach-volume.log\n");
     system("aws ec2 attach-volume --volume-id $v --instance-id $instanceID --device $dev --region $region &> /home/ec2-user/attach-volume.log");
     my $attach_vol=`cat /home/ec2-user/attach-volume.log`;
     $attach_vol =~ s/\n+//g;
     print "DEBUG: attach_vol=\"$attach_vol\"\n";
     sleep(5);
    goto "ATTACHVOLUME" if $attach_vol =~ /IncorrectState/s;
    #-------------------------------------------------------------------------------------------------------------------------

    # modify DeleteOnTermination to be true
    print "Change DeleteOnTermination to true\n";
    print("bash /home/ec2-user/DeleteOnTermination2True.sh $instanceID $dev $region\n");
    system("bash /home/ec2-user/DeleteOnTermination2True.sh $instanceID $dev $region");
  }
  print "DEBUG: Leaving EBS processing code.\n";
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
   if ((!defined($ebssize)) || ( $ebssize =~ /^\d+$/ )){
     print(" mkfs.ext4 $mountdevice\n");
     system(" mkfs.ext4 $mountdevice");
   }

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
  s/^\s*xvd(.).*$/$1/;
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
sub get_lsblk_xvdlines{
# Get all devices
local $_=`lsblk`;
my @x=split("\n",$_);
my @xvdlines=sort grep(/\bxvd[b-z]\b/,@x);
print "\@xvdlines=(",join(", ",@xvdlines),")\n";
return @xvdlines;
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
#----------------------------------------------------------------
sub makeEBSVolume{
my ($ebssize)=@_;
   print "aws ec2 create-volume --size $ebssize --region $region --availability-zone $az --volume-type gp2  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=$stackname-$ClusterComponent}]'\n";
   my $makeebs=`aws ec2 create-volume --size $ebssize --region $region --availability-zone $az --volume-type gp2  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=$stackname-$ClusterComponent}]'`;
   print "DEBUG: makeebs=\"$makeebs\"\n";
   my $v = ($makeebs=~/"VolumeId"\s*: "(vol-[^"]+)"/)? $1 : '';
return $v;
}
