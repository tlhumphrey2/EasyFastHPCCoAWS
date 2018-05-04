#!/usr/bin/perl
print "Entering setupDisks.pl\n";

$ThisDir=($0 =~ /^(.+)[\\\/]/)? $1 : "." ;
require "$ThisDir/ClusterInitVariables.pl";

if ( scalar(@ARGV)>0 ){
  # Means you want to use private_ip file different than the one in ClusterInitVariables.pl.
  $private_ips_file=shift @ARGV;
}

$mountDisks=1;

# Get all private_ips
print "Get all private ips from $private_ips_file.\n";
open(IN,$private_ips_file) || die "Can't open for input: \"$private_ips_file\"\n";
while(<IN>){
   next if /^\s*$/;
   chomp;
   $esp_ip = $_ if $. == 1;
   $slave_ip = $_ if $. == 2;
   push @private_ips, $_;
}
close(IN);

print("chmod 400 $pem\n");
system("chmod 400 $pem");

for( my $i=$#private_ips; $i >= 0; $i--){ 
  my $ip=$private_ips[$i];

  print "sleep 5 seconds.\n";
  sleep(5);

  if ( $mountDisks  && ! $EBSVolumesMountedByFstab ){
    if ( $ephemeral ){
     if ( exists($EBS2Mount{$ip}) ){
      print "mountEBSVolume($ip);\n";
      mountEBSVolume($ip);
     }
     elsif ( exists($fstabMountedEBS{$ip}) ){
      print "ip=\"$ip\" has EBS VOLUME. NOTHING NEEDS TO BE DONE BECAUSE mount is in /etc/fstab\n";
     }
     else{
      # First, copy raid_format_mount.pl $sshuser\@$ip:/home/$sshuser/raid_format_mount.pl\n");
      print "scp -i $pem raid_format_mount.pl $sshuser\@$ip:/home/$sshuser/raid_format_mount.pl\n";
      my $rc=`scp -i $pem raid_format_mount.pl $sshuser\@$ip:/home/$sshuser/raid_format_mount.pl`;
      print("$dt $rc\n");
      # Second, execute raid_format_mount.pl on instance
      print("ssh -o StrictHostKeyChecking=no -t -t -i $pem $sshuser\@$ip \"sudo perl ./raid_format_mount.pl $mountpoint $sshuser\"\n");
      my $rc=`ssh -o StrictHostKeyChecking=no -t -t -i $pem $sshuser\@$ip "sudo perl ./raid_format_mount.pl $mountpoint $sshuser"`;
      print("$dt $rc\n");
     }
    }
    else{
     print "mountEBSVolume($ip);\n";
     mountEBSVolume($ip);
    }
  }
}

$rc=`for x in \$(cat $private_ips_file);do ssh -i $pem -t $sshuser@\$x "echo $x;df -BG $mountpoint";done`;
print "DEBUG: Results of doing \"dt -BG $mountpoint\" on all instances. rc=\"$rc\"\n";
#------------------------------------------
sub mountEBSVolume{
my ($ip)=@_;
     my $dev2mount=getDev2Mount($ip);
print "After calling getDev2Mount. dev2mount=\"$dev2mount\"\n";
     print("ssh -o StrictHostKeyChecking=no -t -t -i $pem $sshuser\@$ip \"sudo mount /dev/$dev2mount $mountpoint\"\n");
     system("ssh -o StrictHostKeyChecking=no -t -t -i $pem $sshuser\@$ip \"sudo mount /dev/$dev2mount $mountpoint\"");
}
#------------------------------------------
sub getDev2Mount{
my ($ip)=@_;
 my $tries=3;
 my $lsblk='';
 my $t=0;
 do {
   $lsblk=`ssh -o StrictHostKeyChecking=no -i $pem -t -t $sshuser\@$ip "lsblk|egrep \"^xvd\"|sort"`;
   print "DEBUG: In getDev2Mount. try=\"$t\", lsblk=\"$lsblk\"\n";
   $t++;
 } until (($lsblk !~ /^\s*$/) || ($t>=$tries));
 die "In getDev2Mount::setupDisks.pl. Tried $tries times to get lsblk of $ip but could NOT. EXITING!\n" if (($lsblk =~ /^\s*$/) && ($t>=$tries));
 my @line=split(/\n/,$lsblk);
 @line=sort grep(/^xvd/,@line);
print "DEBUG: In getDev2Mount. After sort. \@line=(",join("\n",@line),")\n";
 my $dev2mount=$1 if $line[$#line] =~ /^\s*(\S+)/;
 $dev2mount=~s/[^[:ascii:]]//g;
print "In getDev2Mount. AFTER extracting. dev2mount=\"$dev2mount\"\n";
return $dev2mount;
}
#------------------------------------------
sub waitUntilAlive{
my ( $ip, $tries, $SleepBetweenTries )=@_;
 my $saved_tries=$tries;
 my $rc=0;
  print "ping -c 1 $ip\n";
  local $_=`ping -c 1 $ip`;
  print $_;
  sleep($SleepBetweenTries);
  while ( ! /[1-9] received/s && ($tries>0) ){
    print "ping FAILED for ip=\"$ip\". Waiting until it works.\n";
    print "ping -c 1 $ip\n";
    sleep($SleepBetweenTries);
    $_=`ping -c 1 $ip`;
    print $_;
    $tries--;
  }

  if ( $tries <= 0 ){
     die "$saved_tries tries at pinging $ip. Still NOT alive.\n";
  }
}
