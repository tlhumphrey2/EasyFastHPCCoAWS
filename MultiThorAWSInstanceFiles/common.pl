#!/usr/bin/perl
#==========================================================================================================
sub getSshUser{
  my $sshuser=`basename $ThisDir`;chomp $sshuser;
  return $sshuser;
}
#==========================================================================================================
sub addPathToHPCCPlatform{
my ($HPCCPlatform)=@_;
print "DEBUG: Entering addPathToHPCCPlatform, HPCCPlatform=\"$HPCCPlatform\"\n";
  my $IsPlatformSixOrHigher=0;
      my $version = $1 if $HPCCPlatform =~ /^hpcc-platform-(.+)$/i;
      my $base_version = $1 if $version =~ /^(\d+\.\d+\.\d+)(?:-\w+)?/;
      my $First2Digits = $1 if $base_version =~ /^(\d+\.\d+)/;

      # Set platform path based on whether platform version is >= 6.0.
      my $platformpath;
      if ( $First2Digits>=6.0 ){
        $platformpath="http://wpc.423A.rhocdn.net/00423A/releases/CE-Candidate-<base_version>/bin/platform";
        $IsPlatformSixOrHigher=1;
      }
      else{
        $platformpath="http://cdn.hpccsystems.com/releases/CE-Candidate-<base_version>/bin/platform";
      }

      my $PlatformFilenameBefore5_2=($First2Digits>=6.0)? "hpccsystems-platform_community-<version>.<osversion>.x86_64.rpm":"hpccsystems-platform_community-with-plugins-<version>.el6.x86_64.rpm";# Has underscore between platform and community
      my $PlatformFilenameAfter5_2=($First2Digits>=6.0)? "hpccsystems-platform-community_<version>.<osversion>.x86_64.rpm":"hpccsystems-platform-community-with-plugins_<version>.el6.x86_64.rpm";# Has dash between platform and community
      print "DEBUG: In addPathToHPCCPlatform. First2Digits=\"$First2Digits\"\n";
      $platformpath =~ s/<base_version>/$base_version/;
      my $FullPath2HPCCPlatform;
      if ( $First2Digits >= 5.2 ){
         $FullPath2HPCCPlatform= "$platformpath/$PlatformFilenameAfter5_2";
         print "DEBUG: In addPathToHPCCPlatform. GT 5.2 FullPath2HPCCPlatform=\"$FullPath2HPCCPlatform\"\n";
      }
      else{
         $FullPath2HPCCPlatform= "$platformpath/$PlatformFilenameBefore5_2";
         print "DEBUG: In addPathToHPCCPlatform. LT 5.2 FullPath2HPCCPlatform=\"$FullPath2HPCCPlatform\"\n";
      }
      $FullPath2HPCCPlatform =~ s/<version>/$version/;
      $osversion = getOSVersion();
      $FullPath2HPCCPlatform =~ s/<osversion>/$osversion/;
      print "DEBUG: In addPathToHPCCPlatform. FullPath2HPCCPlatform=$FullPath2HPCCPlatform\n";
return ($IsPlatformSixOrHigher,$FullPath2HPCCPlatform);
}
#==============================================================================
sub getOSVersion{
  my $osversion='el6';
  if ( -e "/etc/os-release" ){
    local $_=`cat /etc/os-release`;
    if ( /centos-7/si ){
      $osversion='el7';
    }
  }
  return $osversion;
}
#==============================================================================

1;
