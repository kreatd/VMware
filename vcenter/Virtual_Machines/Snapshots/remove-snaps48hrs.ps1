param(
	[array] $vCenters,
	$Webroot = "e:\Webroot\VMware"
	)
	
Connect-VIServer $vCenters
$vmNames=Get-View -server $vcenters -ViewType VirtualMachine -Property Name,Snapshot -Filter @{"Snapshot"="VMware.Vim.VirtualMachineSnapshotInfo"} | %{$_.Name}
$snapshots = get-vm $vmnames -server $vcenters|get-snapshot #|?{$_.created -lt (Get-Date).AddDays(-2)}
$snapshot_details=@()
$excludes=get-content "E:\Snapshots\exclude.txt"
function excluded ($excludeList, $item)
{
	$match = @($excludeList|?{$item -match $_})
	[bool]$match
}

if ($snapshots -ne $null)
{
	foreach ($snapshot in $snapshots)
    {
        if(($snapshot.description -match '^\d+$') -and ($snapshot.created -gt (get-date).adddays(-$([int]$snapshot.description)))){$action="Remove in: $($([int]$snapshot.description) - ((get-date) - ($snapshot.created)).days) days"}
		elseif ((excluded $excludes $snapshot.vm.name) -and ($snapshot.created -gt (get-date).adddays(-30))){$action="Remove in: $(30 - ((get-date) - ($snapshot.created)).days) days"}    
        elseif (!(excluded $excludes $snapshot.vm.name) -and ($snapshot.created -gt (get-date).adddays(-3))){$action="Remove in: $(3 - ((get-date) - ($snapshot.created)).days) days"}    
		else
        {
            $snapshot|Remove-Snapshot -Confirm:$false
            $action = "Removed"
        }
		$snapshot_details+=$snapshot|select vm, @{n="sizeGB";e={[int]$_.sizegb}}, Name, created,@{n="vCenter";e={$_.Uid.Split(":")[0].Split("@")[1]}},@{n="Action";e={$action}}
    }
	$snapshot_details = $snapshot_details | sort sizegb -Descending
    $snapshot_details|Out-File "\\acct.upmchs.net\ETG\VISupport\Reports\SnapshotRemovals\$(get-date -format yyyy.MM.dd)_snapshot_removals.log"
	if ($snapshot_details -ne $null)
	{
	$snapshot_details|ConvertTo-Html|out-file "$Webroot\Snapshots.html"
	Send-MailMessage -Subject "Snapshot Removals" -From "scripthost" -To "teamemail" -Smtpserver "smtpserver" -Bodyashtml "$($snapshot_details|ConvertTo-Html)"}

}
Disconnect-VIServer * -Confirm:$false -force
