$sshuser="ec2-user";
#$no_hpcc=1;
#$EBSVolumesMountedByFstab=1;                       #If this is set then mounting DOES NOT happen in startHPCCOnAllInstances.pl
#$asgfile="asgnames.txt";                           #File where all asg names and their instances are storaged.
#$ephemeral=1;
$region="us-west-2";                               #Region where this cluster exists
$stackname="another-test";#Name of cloudformation stack that started this hpcc
$name=($stackname !~ /^\s*$/)? $stackname : "test-python3-20171110-2";
$master_name="$name--Master";
$other_name="$name--Slave,$name--Roxie";
$pem="tlh_keys_us_west_2.pem";         #Private ssh key
$private_ips_file="private_ips.txt";          #File where all hpcc instances private IPs are stored (used by startHPCCOnAllInstances.pl)
$instance_id_file="instance_ids.txt";
$mountpoint=($no_hpcc)? "/home/$sshuser/data" : "/var/lib/HPCCSystems"; # IF HPCC
#@additional_instances=('i-021f2c22b883b5e0f','i-02d7096d4c11fab88','i-035643cb2869efdce','i-0433e5da7a46bd608','i-05db6001a1794b9ce','i-088322954d27d6598','i-0b07994a4f66f8516','i-0c6bb6537da791351','i-0ed60cb90498153e0','i-0f21976c94dd56a4a','i-0adaac29d115dffb0'); # Instance IDs for all Instances
1;
