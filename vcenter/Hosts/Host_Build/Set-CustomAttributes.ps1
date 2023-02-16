
<#
.SYNOPSIS
This script enters in cable label information into your hosts based off the following input from a CSV.  It will only work with this layout:
#Cable and Location are both separate columns.  You can obtain this information from patch manager.
#cable	location
#1216U41L1/1/2:1216U1SR1/1/2	1216-U1
#1216U41L1/1/1:1216U1SR-p1	1216-U1
######################################Be sure to sort your cable labels in your csv in order by U as the script will process them in that order.##############################
#
#

.DESCRIPTION

.PARAMETER NONE
-vcenter vcenter
-cluster cluster
-numberofnetworkcables input number of network cables attached to your hosts
.NOTES
  Version:        1.0
  Author:         Virtual Infrastructure Support - Daniel Kreatsoulas
  Creation Date:  07/05/19
  Purpose/Change: Initial script development

  Update Date:  4/28/21
  Purpose/Change: made it more user friendly and uploaded it to github.
.EXAMPLE

.\Set-CustomAttributes.ps1 -vcenter vcenter-2 -cluster C20 -test (enter -test test to run a whatif FIRST! then use -test prod once you've verified the output) -storagetype VSAN -csv "\path\to\your\csv.csv"

#>
param(
    $vcenter,
	$cluster,
    [ValidateSet("test","prod")]
    [parameter(mandatory=$true)]
    [string] $test = $(throw "Please specify if you're like to test or push to prod (enter test to test or prod to push to prod"),
    [ValidateSet("VSAN","SAN")]
    [parameter(mandatory=$true)]
    [string] $storageType = $(throw "specify what type of storage configuration you are working with (Enter SAN or VSAN)"),
    $csv
    )

connect-viserver $vcenter -credential $usercreds



$x = import-csv $csv
$vmhost = get-cluster $cluster | get-vmhost | sort -property name

$cables=@()
$hosts=@()
$Location=@()
$MGTcables=@()
$publiccables=@()
$storagecables=@()
$voicecables=@()


for ($i=0;$i -lt $vmhost.length;$i++)
{
    $hosts+=$vmhost[$i]
}
for ($i=0;$i -lt $x.length;$i++)
{
    $cables+=$x[$i]
}
for ($i=0;$i -lt $x.length;$i++)
{

    if($cables[$i].cable -like "*MGMT")
    {
    $MGTcables+=$cables[$i]
    $location+=$cables[$i].location
    }elseif($cables[$i].cable -notlike "*MGMT" -and $cables[$i].cable -notlike "*0-A" -and $cables[$i].cable -notlike "*0-B" )#voice -> -and $cables[$i].cable -notlike "*SR1/11/1" -and $cables[$i].cable -notlike "*SR-P2")
{
    $publiccables+=$cables[$i]

}elseif($cables[$i].cable -like "*0-A" -or $cables[$i].cable -like "*0-B")
{
    $storagecables+=$cables[$i]

}#elseif($cables[$i].cable -like "*SR1/11/1" -or $cables[$i].cable -like "*SR-P3")
#{
   # $voicecables+=$cables[$i]

#}
}
$y=0;
$z=1;
$c=2;
$v=3;
$b=0;

if($StorageType -eq "SAN"){

#works with 4 public network, 2 storage, 2 voice, 1 iDRAC
for ($i=0;$i -lt $hosts.length;$i++)
                {
                
                 if($test -eq "test"){
                 Set-Annotation -Entity $hosts[$i] -CustomAttribute "Rack_U" -Value $Location[$i] -whatif
                 Set-Annotation -Entity $hosts[$i] -CustomAttribute "IMM_Cables" -Value $MGTcables[$i].cable -whatif
                 Set-Annotation -Entity $hosts[$i] -CustomAttribute "MGMT_Cables" -Value $publiccables[$b].cable -whatif
                 Set-Annotation -Entity $hosts[$i] -CustomAttribute "BKP_Cables" -Value $publiccables[$z].cable -whatif
                 Set-Annotation -Entity $hosts[$i] -CustomAttribute "PUB_Cables" -Value $publiccables[$c].cable -whatif
                 Set-Annotation -Entity $hosts[$i] -CustomAttribute "VMO_Cables" -Value $publiccables[$v].cable -whatif
                 Set-Annotation -Entity $hosts[$i] -CustomAttribute "HBA1_Cable" -Value $storagecables[$y].cable -whatif
                 Set-Annotation -Entity $hosts[$i] -CustomAttribute "HBA2_Cable" -Value $storagecables[$y+1].cable -whatif
                                    }

                if ($test -eq "prod"){
                Set-Annotation -Entity $hosts[$i] -CustomAttribute "Rack_U" -Value $Location[$i]
                Set-Annotation -Entity $hosts[$i] -CustomAttribute "IMM_Cables" -Value $MGTcables[$i].cable
                Set-Annotation -Entity $hosts[$i] -CustomAttribute "MGMT_Cables" -Value $publiccables[$b].cable
                Set-Annotation -Entity $hosts[$i] -CustomAttribute "BKP_Cables" -Value $publiccables[$z].cable
                Set-Annotation -Entity $hosts[$i] -CustomAttribute "PUB_Cables" -Value $publiccables[$c].cable
                Set-Annotation -Entity $hosts[$i] -CustomAttribute "VMO_Cables" -Value $publiccables[$v].cable
                Set-Annotation -Entity $hosts[$i] -CustomAttribute "HBA1_Cable" -Value $storagecables[$y].cable
                Set-Annotation -Entity $hosts[$i] -CustomAttribute "HBA2_Cable" -Value $storagecables[$y+1].cable
                                    }
                    $y=$y+2
                    $z=$z+4
                    $c=$c+4
                    $v=$v+4
                    $b=$b+4
                }
            }
elseif($StorageType -eq "VSAN")
{
                for ($i=0;$i -lt $hosts.length;$i++)
                {
                
                 if($test -eq "test"){
                 Set-Annotation -Entity $hosts[$i] -CustomAttribute "Rack_U" -Value $Location[$i] -whatif
                 Set-Annotation -Entity $hosts[$i] -CustomAttribute "IMM_Cables" -Value $MGTcables[$i].cable -whatif
                 Set-Annotation -Entity $hosts[$i] -CustomAttribute "MGMT_Cables" -Value $publiccables[$b].cable -whatif
                 Set-Annotation -Entity $hosts[$i] -CustomAttribute "BKP_Cables" -Value $publiccables[$z].cable -whatif
                 Set-Annotation -Entity $hosts[$i] -CustomAttribute "PUB_Cables" -Value $publiccables[$c].cable -whatif
                 Set-Annotation -Entity $hosts[$i] -CustomAttribute "VMO_Cables" -Value $publiccables[$v].cable -whatif

                                    }

                if ($test -eq "prod"){
                Set-Annotation -Entity $hosts[$i] -CustomAttribute "Rack_U" -Value $Location[$i]
                Set-Annotation -Entity $hosts[$i] -CustomAttribute "IMM_Cables" -Value $MGTcables[$i].cable
                Set-Annotation -Entity $hosts[$i] -CustomAttribute "MGMT_Cables" -Value $publiccables[$b].cable
                Set-Annotation -Entity $hosts[$i] -CustomAttribute "BKP_Cables" -Value $publiccables[$z].cable
                Set-Annotation -Entity $hosts[$i] -CustomAttribute "PUB_Cables" -Value $publiccables[$c].cable
                Set-Annotation -Entity $hosts[$i] -CustomAttribute "VMO_Cables" -Value $publiccables[$v].cable

                    $z=$z+4
                    $c=$c+4
                    $v=$v+4
                    $b=$b+4
                }

            }else{
                write-output "storage type invalid"
            }

disconnect-viserver $vcenter -Confirm:$False