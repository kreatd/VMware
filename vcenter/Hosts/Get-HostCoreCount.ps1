<#

.DESCRIPTION
This script will take user input (vcenter(s)) and provide the the total host core count.

.PARAMETER <Parameter_Name>
 $vcenter list vcenter(s)

.NOTES
  Version:        1.0
  Author:         Daniel Kreatsoulas
  Creation Date:  2020.5.5
  Purpose/Change: Initial script development
.EXAMPLE

#>
param(
[Parameter(Mandatory=$true)] [array] $vcenter = $(Read-Host -prompt "vcenter is needed")
)

connect-viserver $vcenter


$ALL = get-vmhost -server "all vcenters" | select name,numcpu | measure-object -property numcpu -sum
$dc2 = get-vmhost -server "dc2 vcenters" | select name,numcpu | measure-object -property numcpu -sum
$dc1 = get-vmhost -server "dc1 vcenters" | select name,numcpu | measure-object -property numcpu -sum




###Linux listing
$clusters = get-cluster -server $vcenter | where {$_.name -notlike "*generalclusters" -and $_.name -notlike "*oneapp" -and $_.name -notlike "*stagingcluster" -and $_.name -notlike "*citrixcluster*" -and $_.name -notlike "*managementcluster"}
$LINUX = get-cluster $clusters|get-vmhost -server $vcenter | select name,numcpu | measure-object -property numcpu -sum

write-output "ALL vCenters"
$ALL
write-output "DC1 vCenters"
$DC1
write-output "DC2 vCenters"
$DC1
write-output "Linux Only"
$LINUX

