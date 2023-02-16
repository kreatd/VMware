<#
.SYNOPSIS
  Script reads a report from Dell and updates vCenter host lease end dates

.DESCRIPTION
  Script pulls information from Dell, parses it and compares serial numbers to those
  that exist in the given vCenters.  If the vCenter lease end dates don't match the spreadsheet
  the code will report/update vCenter depending on paramter passed.

.PARAMETER <Parameter_Name>
    $vCenters : The string array list of vCenters to connected to for the scope of the script
    $path : The full path to the Dell excel report file
    $update: Boolean value indicating if the script should update ($true) or report ($false) on the lease dates

.INPUTS
  <Inputs if any, otherwise state None>

.OUTPUTS
  All output text is logged to write-output

.NOTES
  Version:        1.0
  Author:         David Burton
  Creation Date:  2018.10.23
  Purpose/Change: Initial script development
  Version:        2.0
  Author:         Daniel Kreatsoulas
  Creation Date:  1/22/2020
  Purpose/Change: Had to add a client secret
.EXAMPLE
  .\update-hostLeaseDates.ps1 -vCenters "vcenter1","vcenter2" -update $false
#>
#-----------------------
#Parameters
param(
	$vCenters,
	$Apikey,
	$Client_Secret,
	[boolean]$update = $false)
	
#-----------------------
#Functions
#function Get-ScriptDirectory { Split-Path $MyInvocation.ScriptName }

#-----------------------
# External Library References
#$script = Join-Path (Get-ScriptDirectory|split-path|split-path) "\Dell\get-DellWarrantyStatus.ps1"
#. $script
#
#-----------------------

. "E:\Dell\get-DellWarrantyStatus.ps1"


$vcs = connect-viserver $vCenters
$vmhosts = get-vmhost -server $vcs #|where{$_.name -like "esxhostname*"}
$warranties = @()
$newhosts = @()
$DellHosts = $vmhosts|Where-Object{$_.Manufacturer -like "*Dell*"}
$DellHosts|foreach-object {
		$_|add-member -NotePropertyName Serial -NotePropertyValue (($_.ExtensionData.Hardware.SystemInfo.OtherIdentifyingInfo|Where-Object{$_.IdentifierType.Key -eq "ServiceTag"}).identifiervalue)
	}
$serials = $DellHosts.serial

foreach ($dellhost in $dellhosts)
{
	$hostlease = ($dellhost|Get-Annotation -CustomAttribute Lease_End).value
	
	if($hostlease -and $hostlease -ne "No Data Found")
	{
		write-output "Reporting: $($Dellhost.name) has a current lease_date value of $($hostlease).  No changes required."

	}else{
		$newhosts += $dellhost
	}


}

	$warranties = get-DellWarrantyStatus -servicetag $newhosts.serial -apikey $Apikey -client_secret $Client_Secret

	
foreach ($DellHost in $newhosts)
{
	$currentLease = ($dellhost|Get-Annotation -CustomAttribute Lease_End).value
	$warranty = $warranties|where-object {$_.servicetag -eq $DellHost.serial}
	#if($currentLease -eq "No Data Found" -or $currentLease -eq $NULL)
	$dates = $warranty.EndDate -split','
	$datearray=@()
	foreach ($date in $dates){
		$datearray+=get-date($date) -format "yyyy-MM-dd"
	}

	$warranty = $datearray | sort -descending | select -first 1
	if($currentLease)
	#if($DellHost.serial -and $warranty)
	{
		$leaseDate = $warranty
	}
	else{
		$leaseDate = "No Data Found"
	}
	if ($update)
	{
		if ($currentLease -ne $leaseDate)
		{	
			
			write-output "Updating $($Dellhost.name) from '$currentLease' to '$leaseDate'"
			$dellhost|Set-Annotation -CustomAttribute Lease_End -value $leaseDate
		}
		else
		{
			write-output "Reporting: $($Dellhost.name) has a current lease_date value of $($currentLease).  No changes required."
		}
	}
    else
    {
		if ($currentLease -ne $leaseDate)
		{
			write-output "Reporting: $($Dellhost.name) from '$currentLease' to '$leaseDate'"
		}
		else
		{
			write-output "Reporting: $($Dellhost.name) has a current lease_date value of $($currentLease).  No changes required."
		}
    }
}
