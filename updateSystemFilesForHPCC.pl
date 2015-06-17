#!/usr/bin/perl
=pod
#Server side code
updateSystemFilesForHPCC.pl

System Files are:
  /etc/security/limits.conf
  /etc/ssh/sshd_config
  /etc/sysctl.conf
=cut

#----------------------------------------------------------------------------------------------------------
# Table showing 1) system files to be updated, 2) regex to identify items to be updated, 3) the update

$SystemFilesAndChanges2Make=<<EOFF1;
#  SYSTEM FILE PATH             |        REGEX THAT IDENTIFIES ITEM     	|        ITEM'S UPDATE      
/etc/security/limits.conf	|	\\bhpcc\\s+soft\\s+nofile\\b		|	hpcc    soft    nofile    16384
/etc/security/limits.conf	|	\\bhpcc\\s+hard\\s+nofile\\b		|	hpcc    hard    nofile    65536
/etc/security/limits.conf	|	\\bhpcc\\s+soft\\s+core\\b		|	hpcc    soft    core      unlimited
/etc/security/limits.conf	|	\\bhpcc\\s+hard\\s+core\\b		|	hpcc    hard    core      unlimited
/etc/security/limits.conf	|	\\bhpcc\\s+soft\\s+nproc\\b		|	hpcc    soft    nproc     1967946
/etc/security/limits.conf	|	\\bhpcc\\s+hard\\s+nproc\\b		|	hpcc    hard    nproc     1967946
/etc/security/limits.conf	|	\\bhpcc\\s+soft\\s+rtprio\\b		|	hpcc    soft    rtprio    0
/etc/security/limits.conf	|	\\bhpcc\\s+hard\\s+rtprio\\b		|	hpcc    hard    rtprio    4
/etc/ssh/sshd_config		|	\\bMaxSessions\\b			|	MaxSessions 30
/etc/ssh/sshd_config		|	\\bMaxStartups\\b			|	MaxStartups 30:45:100
/etc/sysctl.conf		|	\\bnet\\.core\\.optmem_max\\b		|	net.core.optmem_max = 16777216
/etc/sysctl.conf		|	\\bnet\\.core\\.rmem_default\\b		|	net.core.rmem_default = 16777216
/etc/sysctl.conf		|	\\bnet\\.core\\.rmem_max\\b		|	net.core.rmem_max = 16777216
/etc/sysctl.conf		|	\\bnet\\.core\\.wmem_default\\b		|	net.core.wmem_default = 16777216
/etc/sysctl.conf		|	\\bnet\\.core\\.wmem_max\\b		|	net.core.wmem_max = 16777216
EOFF1

@SystemFilesAndChanges2Make=split(/\n/,$SystemFilesAndChanges2Make);


#----------------------------------------------------------------------------------------------------------
# Prepare for updating system files by placing the above table in 2 hash tables: %changes and %item_ids.

$prev_sysfile='';
foreach (@SystemFilesAndChanges2Make){
   next if /^#/ || /^\s*$/;
   my ($sysfile,$id_re,$change)=split(/	+\|	+/,$_);
   if ( $sysfile ne $prev_sysfile ){
      if ( $prev_sysfile ne '' ){
         my @c=@changes;
         my @i=@id_res;
         $changes{$prev_sysfile}=\@c;
         $item_ids{$prev_sysfile}=\@i;
         push @SystemFile, $prev_sysfile;
      }
      @changes=();
      @id_res=();
   }
   
   push @changes, $change;
   push @id_res, $id_re;
   $prev_sysfile = $sysfile;
}

if ( scalar(@changes) > 0 ){
   my @c=@changes;
   my @i=@id_res;
   $changes{$prev_sysfile}=\@c;
   $item_ids{$prev_sysfile}=\@i;
   push @SystemFile, $prev_sysfile;
}

print "DEBUG: \@SystemFile=(",join(", ",@SystemFile),")\n";

#----------------------------------------------------------------------------------------------------------
# The system file update process does the following:
# 1. Gets the contents of the system
# 2. Finds item to be updated in system file
# 3. Updates item once it is found
# If the item isn't found them the item's new content is placed on the end of the file or just after the last
#  item that was updated.

foreach my $sysfile (@SystemFile){
  if ( ! -e $sysfile ){
     print "WARNING: System file, $sysfile, DOES NOT EXISTS. So, no modifications will be made.\n";
  }
  else{
     # Save contents of system file in home directory before it is updated
     print("cp $sysfile .\n");
     system("cp $sysfile .");

     print "\$contents gets the contents of the file: \"$sysfile\"\n";
     my $contents=`cat $sysfile`;
     my @contents=split(/\n/,$contents);
     my @mods=@{$changes{$sysfile}};
     my @id_res=@{$item_ids{$sysfile}};
     
     my %mods_found=();
     foreach my $mod (@mods){
        $mods_found{$mod}=0;
     }

     my $LastModFoundIndex=$#contents; # Initialize to last line of content
     for( my $j=0; $j < scalar(@contents); $j++){
         for( my $k=0; $k < scalar(@id_res); $k++){
            my $id_re=$id_res[$k];
            if ( $contents[$j] =~ /^\s*[^# ]?.*($id_re)/ ){
               $contents[$j] = $mods[$k];
               $mods_found{$mods[$k]}=1;
               print "DEBUG: sysfile=\"$sysfile\". Found mod replaces contents: \$contents[$j]=\"$contents[$j]\"\n";
               $LastModFoundIndex = $j if $LastModFoundIndex > $j;
            }
         }
     }
     
     my @mods_not_found=();
     foreach my $mod (keys %mods_found){
        push @mods_not_found, $mod if $mods_found{$mod} == 0;
     }

     print "DEBUG: Number of mods NOT FOUND =",scalar(@mods_not_found),"\n";
     if ( scalar(@mods_not_found) > 0 ){ # If this is true, we must place mods not currently in contents someplace.
         my @temp_contents=();
         my $temp_j=0;
         for( my $j=0; $j < scalar(@contents); $j++){
            $temp_contents[$temp_j]=$contents[$j];
            $temp_j++;
             if ( $j == $LastModFoundIndex ){
               foreach my $mod (@mods_not_found){
                  $temp_contents[$temp_j]=$mod;
                  print "DEBUG: Unfound mod added to contents: \$temp_contents[$temp_j]=\"$temp_contents[$temp_j]\", sysfile=\"$sysfile\"\n";
                  $temp_j++;
               }
            }
         }
         @contents=@temp_contents;
     }
     
     $contents = join("\n",@contents)."\n";
     
     my $sysfile_basename = $1 if $sysfile =~ /([^\\\/]+)$/;
     my $tmp_sysfile="$sysfile_basename.tmp";
     print "DEBUG: sysfile_basename=\"$sysfile_basename\", tmp_sysfile=\"$tmp_sysfile\"\n";
     open(OUT,">$tmp_sysfile") || die "Can't open for output \"$tmp_sysfile\"\n";
     print OUT $contents;
     close(OUT);
     print("mv $tmp_sysfile $sysfile\n");
     system("mv $tmp_sysfile $sysfile");
  }
}
