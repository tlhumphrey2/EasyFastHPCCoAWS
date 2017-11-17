#!/usr/bin/perl
$ThisDir=($0=~/^(.*)\//)? $1 : ".";
=pod
#Server side code
updateEnvGenConfigurationForHPCC.pl

System Files are:
  /etc/HPCCSystems/genenvrules.conf
=cut

#----------------------------------------------------------------------------------------------------------
# Table showing 1) system files to be updated, 2) regex to identify items to be updated, 3) the update

$EnvGenConfigurationAndChanges2Make=<<EOFF1;
#  SYSTEM FILE PATH              |        REGEX THAT IDENTIFIES ITEM     	|        ITEM'S UPDATE      
/etc/HPCCSystems/genenvrules.conf|	\\bavoid_combo=.+         		|	append:,thor-roxie
EOFF1

@EnvGenConfigurationAndChanges2Make=split(/\n/,$EnvGenConfigurationAndChanges2Make);


#----------------------------------------------------------------------------------------------------------
# Prepare for updating system files by placing the above table in 2 hash tables: %changes and %item_ids.

$prev_sysfile='';
foreach (@EnvGenConfigurationAndChanges2Make){
   next if /^#/ || /^\s*$/;
   my ($sysfile,$id_re,$change)=split(/\s*\|\s*/,$_);
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
# If the item isn't found then the item's new content is placed on the end of the file or just after the last
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
               $contents[$j] = ($mods[$k] =~ s/append:// )? "$contents[$j]$mods[$k]" : $mods[$k];
               $mods_found{$mods[$k]}=1;
               print "DEBUG: sysfile=\"$sysfile\". Found mod replaces contents: \$contents[$j]=\"$contents[$j]\"\n";
               $LastModFoundIndex = $j if $LastModFoundIndex > $j;
            }
         }
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
