sub formatDateTimeString{
my ($sec,$min,$hour,$mday,$mon,$year)=localtime();
$year+=1900;
$mon+=1;
$mon=substr("00".$mon, -2);
$mday=substr("00".$mday, -2);
$hour=substr("00".$hour, -2);
$min=substr("00".$min, -2);
$sec=substr("00".$sec, -2);
return sprintf "%04d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec;
}
1;
