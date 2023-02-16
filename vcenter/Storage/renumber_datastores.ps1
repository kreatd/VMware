<#
.SYNOPSIS
	This script renames datastores from $start to ending value of the array.

.DESCRIPTION
	This takes in your input of -vcenter -dscluster and -start value (1 for the first datastore in the primary dscluster or 65 for the first datastore in the second cluster)
	This script will rename your datastore to our naming convention.  It will always end with three integers
.PARAMETER NONE
-vcenter vcenter
-dscluster datastore cluster
-start starting value for your first datastore in the datastore cluster
.NOTES
  Version:        1.0
  Author:         Virtual Infrastructure Support - Daniel Kreatsoulas
  Creation Date:  05/22/2019
  Purpose/Change: Initial script development

  Update Date:

.EXAMPLE
 enable the -what if flag on the set-datastore piece of the script to test it.
  ./renumber_datastores.ps1 -vcenter vcenter1 -dscluster C03 -start 1

#>
param(
    $vcenter,
	$dscluster,
    $start
	)
function renumberDatastores{
[CmdletBinding()]
	param(
        [Parameter(Mandatory=$true)] [string] $vcenter = $(Read-Host -prompt "vCenter server name needed"),
		[Parameter(Mandatory=$true)] [string] $dscluster = $(Read-Host -prompt "vCenter Datastore Cluster Object needed"),
        [Parameter(Mandatory=$true)] [int] $start = $(Read-Host -prompt "Starting integer needed")
		)
	process
	{
		$vc = connect-viserver $vcenter
		if($vc -eq $NULL)
		{
			write-output "$vcenter is not a valid vCenter, please pass a valid vCenter name." 
			break
		}	
		$cluster = get-datastorecluster $dscluster -Server $vc
		if($cluster -eq $NULL)
		{
			write-output "$dscluster is not a valid Datastore Cluster in vCenter: $vcenter, please pass a valid cluster name." 
			break
		;}
        if($start -eq $NULL)
		{
			write-output "$start Please enter a valid starting integer. (ex. 1 for first ds cluster and 65 for 2nd datastore cluster due to the limit.)" 
			break
		}	

$ds=get-datastorecluster $cluster | Get-Datastore #| sort-object -property name

$y=0
$count=$start


foreach($x in $ds)

    {
        
        $oldname = get-datastore $ds[$y]
		#$newname=$ds[$y].Name -replace "...$"
		$newname="nameofdatastore-000" -replace "...$"
        $n="{0:000}" -f $count
        $newname=$newname+$n
        $newds=$ds[$y].name.replace($oldname,$newname)
		get-datastore -Name $ds[$y]| set-datastore -Name $newds #-whatif
		$newname
        $count++
        $y++

    }
    }
}
renumberDatastores -vcenter $vcenter -dsc $dscluster -start $start
disconnect-viserver $vcenter -Confirm:$False
