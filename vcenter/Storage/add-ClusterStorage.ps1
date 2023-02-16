<#
.SYNOPSIS
  Managing storage presentation is a tedious task and this script was created to address that issue.

.DESCRIPTION
  This script will review the given VMware compute clusters and search for new blank disks within each
  followed by formatting and naming the VMFS filesystems and placing the new Datastore within the appropriate
  VMware Datastore Cluster.  The naming convention and Datastore cluster selection is based on the current patterns.

  **This script was written to replace a manual task requiring 60min/week.**

.PARAMETER Clusters
    This is a 1 or more VMware cluster objects that the script will loop through.

.NOTES
  Version:        3.0
  Updated by:     Daniel Kreatsoulas
  Date:           1/26/2021
  Purpose/Change: commented out old if statements and modified how datatore names are picked
  
  Version:        2.0
  Author:         David Burton
  Date:           10/17/2014
  Purpose/Change: Updated to be more automated and be able to run from Nimbus

  Version:        1.0
  Author:         David Burton
  Creation Date:  6/2/2014
  Purpose/Change: Initial script development


.EXAMPLE
  .\add-ClusterStorage.ps1 -ClusterName "My Cluster" -vCenter "vCenter1"
#>
param(
	$Cluster,
	$vCenter
	)

function add-clusterstorage{
[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)] [string] $ClusterName = $(Read-Host -prompt "vCenter Cluster Object needed"),
		[Parameter(Mandatory=$true)] [string] $vCenter = $(Read-Host -prompt "vCenter server name needed")
		)
	begin
	{
	}
	process
	{
		$vc = connect-viserver $vcenter
		if($vc -eq $NULL)
		{
			write-output "$vCenter is not a valid vCenter, please pass a valid vCenter name."
			break
		}
		$cluster = get-cluster $clustername -Server $vc
		if($cluster -eq $NULL)
		{
			write-output "$clustername is not a valid Cluster in vCenter: $vCenter, please pass a valid cluster name."
			break
		}
		$vmhost = $cluster|get-vmhost|where-object {$_.connectionstate -eq "Connected"}|select-object -last 1

		if ($vmhost.name -like "*vc2*")
			{
				$location = "vc2"
		}
		elseif ($vmhost.name -like "*vc3*") {

			$location = "vc3"
		}
		else 
		{
			$location = "vc1"
		}
		#if ($vmhost.version -like "6.7.0"){$vmfsversion = 6}
		#Else {$vmfsversion = 6}
		$vmfsversion = 6
		
		$Clusterdisks = $vmhost|get-scsilun -luntype disk
		$ClusterDS = $vmhost|get-datastore|where-object {$_.type -eq "vmfs" -and $_.name -like "*DATA*" -and $_.name -notlike "*Templates*" -and $_.name -notlike "*vrs*" -and $_.name -notlike "*Images*"}|sort-object name

<#		This block checks for RDMs, but currently we do not use them, so commenting them out saves time

		write-verbose "Retrieving New LUNs minus the RDMs"
		$vms = $cluster |Get-VM|get-view
		$RDMs = @()
		foreach($vm in $vms){
			foreach($dev in $vm.Config.Hardware.Device){
				if(($dev.gettype()).Name -eq "VirtualDisk"){
					if(($dev.Backing.CompatibilityMode -eq "physicalMode") -or
					($dev.Backing.CompatibilityMode -eq "virtualMode")){
						write-output $vm.name, $dev.Backing.DeviceName
						$RDMs+=$dev.Backing.DeviceName
					}
				}
			}
		}
#>
		$newdisks = $Clusterdisks|foreach-object{
			$disk=$_;
			if(($Clusterds|where-object {$_.extensiondata.info.vmfs.extent[0].diskname -match $disk.canonicalname}) -eq $NULL)
			{
				if(($RDMs|where-object {$_ -match $disk.canonicalname}) -eq $NULL)
				{$disk}
			}
		}
		#$DisksDataComp = $newdisks|where-object {($_.capacitygb -eq 8000) -or ($_.capacitygb -eq 10000) -or ($_.capacitygb -eq 14000)}
		$DisksDataComp = $newdisks|where-object {($_.capacitygb -eq 10000)}
		#### add if for VRS datastore
		If ($DisksDataComp)
		{
			$DatastoreCluster = $ClusterName.split("-")[0] + "-" + $location + "premiumdiskstorage*"

			$DSCluster = get-datastorecluster -server $vc $DatastoreCluster | sort-object name | select-object -last 1
			#$lastDS = $DSCluster|get-datastore|sort-object name|select-object -last 1
			$lastDS = $Cluster|get-datastore|where-object {$_.type -eq "vmfs" -and $_.name -like "*DATA*" -and $_.name -notlike "*Templates*" -and $_.name -notlike "*vrs*" -and $_.name -notlike "*Images*"}|sort-object name|select-object -last 1
			if($lastDS){
				$i = [int]$lastds.name.split("-")[-1] + 1
				$clusterprefix = $lastDS[-1].name.trim($lastDS[-1].name.split("-")[-1])
			}
			else{
				write-output "Empty DSCluster, no Datastore name pattern to copy.  Create first Datastore in cluster than re-run script."
				break}
			write-verbose "Formatting LUNs and placing them into DScluster: $DatastoreCluster"
			foreach ($newdisk in $DisksDataComp)
			{
				$dsname = "$clusterprefix$("{0:D3}" -f $i)"
				$i++
				$ds = new-datastore -server $vc -vmhost $vmhost -name $dsname -vmfs -FileSystemVersion $vmfsversion -path $newdisk.canonicalname
				$ds|move-datastore -server $vc -destination $DSCluster
				write-output "$($DS.name) added to cluster $($DSCluster.name)"
			}
		}

	}
}

$date = get-date -format yyyy-MM-dd.HH.mm
$Global:logfile = "\\logs\add-clusterstorage\output-" + $date + ".log"
$log = add-clusterstorage -ClusterName $Cluster -vCenter $vCenter
$log | out-file $global:logfile -append
