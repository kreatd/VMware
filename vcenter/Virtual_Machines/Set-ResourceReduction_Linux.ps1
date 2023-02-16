


param(
	[string[]] $vCenters = @("vcenter1"),
	$oversizedVMs,
	$oldVMinventory
	)

	Function Enable-MemHotAdd($vm){
		$vmview = Get-vm $vm | Get-View
		$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
		$extra = New-Object VMware.Vim.optionvalue
		$extra.Key="mem.hotadd"
		$extra.Value="true"
		$vmConfigSpec.extraconfig += $extra
		$vmview.ReconfigVM($vmConfigSpec)
		}	
	Function Enable-vCpuHotAdd($vm){
			$vmview = Get-vm $vm | Get-View
			$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
			$extra = New-Object VMware.Vim.optionvalue
			$extra.Key="vcpu.hotadd"
			$extra.Value="true"
			$vmConfigSpec.extraconfig += $extra
			$vmview.ReconfigVM($vmConfigSpec)
		}

$RAMlimit = 4
$CPUlimit = 2
connect-viserver $vCenters

$ImportedVMs = import-csv $oversizedVMs
$ExcludedVMs = get-content "\\exclusions.txt"


$VmsToReduce = $ImportedVMs | where-object {$ExcludedVMs -notcontains $_.name}
#Get VM monthly details report from 3 months back, VM must be on that list
$90dayinventory = import-csv $oldVMinventory|foreach-object{$_.vmname}|sort-object
$VmsToReduce = $VmsToReduce | where-object {$90dayinventory -contains $_.name}



#Get all $VMs and shutdown guest os

$VMsToReduceCount.count = get-vm $VmsToReduce.name | Shutdown-VMGuest -Confirm:$False



#Sleep 2 minutes
Start-Sleep -s 120
#Get VMs that may still be powered on, if Null continue, if not, force-shutdown
If(get-vm $VmsToReduce.name | ? {$_.powerstate -eq "PoweredOn"})
{
	get-vm $VmsToReduce.name | ? {$_.powerstate -eq "PoweredOn"} | Stop-VM -Confirm:$False -RunAsync
}
#Get VMs that are still powered on (errors)
Start-Sleep -s 120
$numPoweredOn = (get-vm $VmsToReduce.name | ? {$_.powerstate -eq "PoweredOn"}).count
 
#Get VMs that will be reduced
 $offVMs = (get-vm $VmsToReduce.name | ? {$_.powerstate -eq "PoweredOff"})

 foreach ($vm in $offVMs)
 {

	$newVmSize = $VmsToReduce|where-object {$_.name -eq $vm.name}
	#Getting new CPU value, but not lower than CPUlimit
	$newCPU = [math]::max($CPUlimit,($newVmSize."Configured vCPU" - $newVmSize."Reclaimable vCPU(s)"))
	#Getting new RAM value, but not lower than RAMlimit
	$newMem = [math]::max($RAMlimit,($newVmSize."Configured Memory" - $newVmSize."Reclaimable Memory"))
	get-vm $vm | set-vm -MemoryGB $newMem -NumCpu $newCPU -Confirm:$False
	$HotAdd = get-vm $vm | get-view | select @{N="CpuHotAddEnabled";E={$_.Config.CpuHotAddEnabled}},@{N="MemoryHotAddEnabled";E={$_.Config.MemoryHotAddEnabled}}

	if($HotAdd.CpuHotAddEnabled -eq $false -and $HotAdd.MemoryHotAddEnabled -eq $true)
	{
	Enable-vCpuHotAdd -vm $vm
	Start-Sleep -s 5
	}elseif($HotAdd.CpuHotAddEnabled -eq $true -and $HotAdd.MemoryHotAddEnabled -eq $false)
	{
	Enable-MemHotAdd -vm $vm
	Start-Sleep -s 5
	}elseif($HotAdd.CpuHotAddEnabled -eq $false -and $HotAdd.MemoryHotAddEnabled -eq $false)
	{
	Enable-vCpuHotAdd -vm $vm
	Enable-MemHotAdd -vm $vm
	Start-Sleep -s 5
	}
	get-vm $vm | start-vm -Confirm:$False

 }
Start-Sleep -s 300
#Check for Powered off VMs
$poweredOffVMs = get-vm $VmsToReduce.name | ? {$_.powerstate -eq "PoweredOff"} 
$completedVMs = get-vm $VmsToReduce.name | select name, numcpu, memorygb

$failures = $offVms.name | Select name, NumCpu, MemoryGB


#Report on sucessess

if($poweredOffVMs.count -eq $VMsToReduceCount.count)
{
	$output=$completedVMs
	$output| out-file -filepath "\\VM-Resource-Reduction-$(get-date -f yyy.MM.dd).txt" 
	$CompletedVMsOutput=$completedVMs | ConvertTo-Html
	$VMsToReduceOutput=$VmsToReduce | select-object Name,"Configured vCPU","Configured Memory"
	Send-MailMessage -BodyAsHtml -Body "<table><tr><td><center><h1>VMs To Be Reduced:</h1></center></td><td><center><h1>Completed VMs:</h1></center></td></tr><tr><td>$($VMsToReduceOutput | ConvertTo-Html)</td><td>$CompletedVMsOutput</td></tr></table>"`
	-From "scriptinghost" `
	-To "teamname" `
	-Smtpserver "smtpserver" `
	-Subject "Dev/Test Resource Reduction Completed"
}
#Report on errors
#Needs worked on
if($poweredOffVMs.count -ne $VMsToReduceCount.count)
{
	$output=$completedVMs
	$VMsToReduceOutput=$VmsToReduce | select-object Name,"Configured vCPU","Configured Memory"
	$output| out-file -filepath "\\VM-Resource-Reduction-$(get-date -f yyy.MM.dd).txt" 
	$failures| out-file -filepath "\\VM-Resource-Reduction-Failures-$(get-date -f yyy.MM.dd).txt" 
	$FailuresOutput=$failures | ConvertTo-Html
	$CompletedVMsOutput=$completedVMs | ConvertTo-Html
	Send-MailMessage -BodyAsHtml -Body "<table><tr><td><center><h1>VMs To Be Reduced:</h1></center></td><td><center><h1>Completed VMs:</h1></center></td><td><center><h1>Failures:</h1></center></td></tr><tr><td>$($VMsToReduceOutput | ConvertTo-Html)</td><td>$CompletedVMsOutput</td><td>$FailuresOutput</td></tr></table>"`
	-From "scriptinghost" `
	-To "teamname" `
	-Smtpserver "smtpserver" `
    -Subject "Dev/Test Resource Reduction Completed With Errors"

}
#Email Summary

disconnect-viserver $vCenters -Confirm:$False
