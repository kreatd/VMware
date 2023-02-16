<#
.DESCRIPTION
	This script takes a list of NAAs from the user and spits out a list of VMs that live on those NAAs.
.PARAMETER NONE
	$vCenter, vCenter(s) that you'd like to connect to
	$inputfile, CSV of NAAs

.NOTES
  Version:        1.0
  Author:         Daniel Kreatsoulas
  Creation Date:  05/08/2019
  Purpose/Change: Initial script development

  Update Date:

.EXAMPLE
 Get-VMsByNaa.ps1 -server "vcenter1" -inputfile "C:\temp2106524152.csv"

#>


param(
    $vCenter,
    $inputfile
)

$inputfile = import-csv $inputfile -header "luns"

$LatestReport = gci "\\Reports\Inventory\" | sort LastWriteTime | Where-object { $_ -match "VMware_datastore*" } | select -last 1
$LatestReport = $LatestReport.Name
$Inventory = import-csv "\Inventory\$LatestReport"

$vc = connect-viserver $vCenter

#$hash=@{}
$a=@()
$x=0
while( $x -lt $inputfile.length){
$Datastore=$Inventory | where-object { $_.Serial -match $inputfile.luns[$x]}

#$hash.add($Datastore.Serial,$Datastore.Name)
$a+=$Datastore.Name
$x++
}

#$hash['naa.$']
$y=0
$VMs=@()
while($y -lt $a.length){
$VMs+=Get-Datastore $a[$y] |get-vm | where {$_.powerstate -eq "PoweredOn"}
$y++
}
$VMs=$VMs | sort -Unique
$VMs
get-vm $VMs | select name | export-csv tempoutput.csv

