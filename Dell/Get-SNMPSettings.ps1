


param(
    $admin,
    [Parameter(Mandatory=$true)] [string] $path = $(Read-Host -prompt "Enter path of csv for input (C:\path\to\file.csv)")
	)

    $idracs = import-csv $path -header "name"
    $output=@()
$snmpcount = 5
foreach($idrac in $idracs)
{
$x=1;
$SNMP1Output=""
$idracname=""

while ($x -lt $snmpcount){
$SNMP1Output = racadm -r $idrac.name -u USER -p $admin get idrac.SNMPAlert.$x
$idracname=$idrac.name
$SNMP1Destination=$SNMP1Output | select-string -pattern "Destination"
$new1 = $SNMP1Destination -replace '[A-Z]*=',""
if ($new1) {
    if($SNMP1Output -match "Enabled"){
    $output += New-Object PsObject -property @{
        'idrac' = $idracname
        'IP' = $new1
        'State' = "Enabled"
        }
    }
    else{
        $output += New-Object PsObject -property @{
            'idrac' = $idracname
            'IP' = $new1
            'State' = "Disabled"
            } 
            $output | where {$_.idrac -like $idracname}
        }
            }
$x=$x+1
}

}
$output | export-csv output.csv
$output
