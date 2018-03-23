#!/usr/bin/perl
=pod
replaceWithJinja2Required2.pl EspProcessAndService.xml.j2.template > EspProcessAndService.xml.j2
replaceWithJinja2Required2.pl t.xml.j2.template > t.xml.j2
replaceWithJinja2Required2.pl LDAPServerProcess.xml.j2.template > LDAPServerProcess.xml.j2
replaceWithJinja2Required2.pl EclAgentProcess.xml.j2.template > EclAgentProcess.xml.j2

EXAMPLE INPUT FILE CONTENTS (lines beginning with *myldap are replaced with template $required_template):
{% if groups['ldap'] is defined %}
{% for myldap in groups['ldap'] %}
  <LDAPServerProcess build="_"
                     buildSet="ldapServer"
                     cacheTimeout="30"
                     description="LDAP server process"
*myldap                     filesBasedn="ou=files,ou=ecl"
*myldap                     groupsBasedn="ou=groups,ou=ecl,dc=internal,dc=sds"
                     ldapPort="389"
                     ldapSecurePort="636"
*myldap                     modulesBasedn="ou=prod_hql,ou=prod_ecl,dc=internal,dc=sds"
                     name="{{myldap}}"
*myldap                     sudoersBasedn="ou=SUDOers"
*myldap                     systemBasedn="cn=Users,dc=internal,dc=sds"
                     systemCommonName="in_ternal"
*myldap                     systemPassword="blanked"
*myldap                     systemUser="in_ternal"
*myldap                     usersBasedn="ou=users,ou=ecl,dc=internal,dc=sds"
*myldap                     workunitsBasedn="ou=workunits,ou=prod_ecl">
{% for ldapip in groups[myldap] %}
   <Instance computer="node{{ hostvars[ldapip]['inventory_hostname'] | ipaddr('int') }}"
{% if (loop.index == 1) and (groups[myldap] | count > 1) %}
             directory="/var/lib/HPCCSystems/{{myldap}}"
{% endif %}
             name="s{{ loop.index }}"
             netAddress="{{ hostvars[ldapip]['inventory_hostname'] }}"/>
{% endfor %}
  </LDAPServerProcess>
{% endfor %}
{% endif %}
=cut

while(<>){
  chomp;
  $_=assignment($_);
  push @line, $_;
}

print join("\n",@line);
#===================================================
sub assignment{
my ( $x )=@_;
my $assignment_re='(\w+)="(.*)"';
local $_=$x;

  if ( s/^([\*\&\-])('?\w+'?)(\s+\<\w+ +| +)$assignment_re(\S*)(\s*)$/<ASSIGNMENT>$7/s ){ 
     my $op=$1;
     my $componentname=$2;
     my $prefixtext=$3;
     my $variablename=$4;
     my $defaultvalue=$5;
     my $suffix=$6;
     s/^\s+<ASSIGNMENT>/<ASSIGNMENT>/;
    
    if ( $op eq '*' ){
      s/<ASSIGNMENT>/{{mac.REQUIRED(\'$prefixtext\',$componentname,\'$variablename\',\'$suffix\')}}/;
    }
    elsif ( $op eq '&' ){
      s/<ASSIGNMENT>/{{mac.DEFAULT(\'$prefixtext\',$componentname,\'$variablename\',\'$defaultvalue\',\'$suffix\')}}/;
    }
    elsif ( $op eq '-' ){
      s/<ASSIGNMENT>/{{mac.OMIT(\'$prefixtext\',$componentname,\'$variablename\',\'$suffix\')}}/;
    }
    else{
      print STDERR "ERROR: op=\"$op\" is NOT recognized. Input was \"$x\".\n";
    }
  }
  return $_;
}  