


param(
    $admin,
    [Parameter(Mandatory=$true)] [string] $path = $(Read-Host -prompt "Enter path of csv for input (C:\path\to\file.csv)"),
    $dnsip
	)

    $idracs = import-csv $path -header "name"
    $output=@()
    $output2=@()
    $output3=@()
foreach($idrac in $idracs)
{
#$x=1;
$NTP1Output=""
$NTP2Output=""
$NTP3Output=""
$idracname=""

#while ($x -lt $snmpcount){
$NTP3Output = racadm -r $idrac.name -u USER -p $admin get idrac.NTPConfigGroup.ntp1
$NTP1Output = racadm -r $idrac.name -u USER -p $admin get idrac.NTPConfigGroup.NTPEnable
$NTP2Output = racadm -r $idrac.name -u USER -p $admin get idrac.time.timezone

$idracname=$idrac.name

$NTP1Destination=$NTP1Output | select-string -pattern "NTPEnable"
$NTP2Destination=$NTP2Output | select-string -pattern "Timezone"
$NTP3Destination=$NTP3Output | select-string -pattern "NTP1"

$state = $NTP1Destination -replace '[A-Z]*=',""
$timezone = $NTP2Destination -replace '[A-Z]*=',""
$ntpserver = $NTP3Destination -replace '[NTP1]*=',""
if ($state -and $timezone -and $ntpserver) {
    if($NTP1Output -match "Enabled" -and $NTP2Output -match "US/Eastern" -and $NTP3Output -match $dnsip){
    $output += New-Object PsObject -property @{
        'idrac' = $idracname
        'NTP State' = $state
        'Timezone' = $timezone
        'NTP Server' = $ntpserver
        }
        write-output "$idracname is verified."
    }
    else{
        $output += New-Object PsObject -property @{
            'idrac' = $idracname
            'value' = $state
            'Timezone' = $timezone
            'NTP Server' = $ntpserver

            } 
            $output | where {$_.idrac -like $idracname}
        }
            }


#$x=$x+1
#}

}
 $output| export-csv output.csv
