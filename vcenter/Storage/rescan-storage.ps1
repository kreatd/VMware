<#
.SYNOPSIS
  Rescanning HBAs is a tedious task.
   
.DESCRIPTION
  This script will rescan all HBAs, given the vcenter server name and cluster name.
  
.PARAMETER Clusters
    This is a 1 or more VMware cluster objects that the script will loop through.

.NOTES
  Version:        1.0
  Author:         Dan Kreatsoulas
  Date:           6/28/2017
  
.EXAMPLE
  .\rescan-storage.ps1 -Cluster "My Cluster" -vCenter "vCenter2"
#>
param(
	$Cluster,
	$vCenter
	)

function rescan-storage{

[CmdletBinding()]
	param(		
[Parameter(Mandatory=$true)] [string] $Cluster = $(Read-Host -prompt "vCenter Cluster Object needed"),
		[Parameter(Mandatory=$true)] [string] $vCenter = $(Read-Host -prompt "vCenter server name needed")
		)

	$vc = connect-viserver $vcenter
		if($vc -eq $NULL)
		{
			write-output "$vCenter is not a valid vCenter, please pass a valid vCenter name."
			break
		}	

    $cstr = get-cluster $Cluster
    $hosts = $cstr | Get-VMHost

    Get-VMHostStorage -vmhost $hosts -RescanAllHba
}
rescan-storage -Cluster $Cluster -vCenter $vCenter 
