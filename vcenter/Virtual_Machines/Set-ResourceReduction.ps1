<#
.SYNOPSIS
  Takes parameters and performs a shutdown guest os / power off (if the shutdown guest os doesn't complete in time) and reduces VM resources based off our vrops resource reclamation report.  All VMs are powered on after resource reductions have been completed.  These reconfigure/power ons occur consecutively.


.DESCRIPTION
  Enter vcenter and paths to the vrops/vmdetails reports

.PARAMETER <Parameter_Name>
    $vcenter :  vcenter 
    $oversizedVMs : Path to our vrops oversized vms report
    $oldVMinventory: Path to our vmdetails report

.NOTES
  Version:        1.0
  Author(s):         Daniel Kreatsoulas
  Creation Date:  05/16/2019
  Purpose/Change: Initial script development


.EXAMPLE
./Set-ResourceReduction.ps1  -vcenter (enter in vcenter(s))
#>



param(
	[Parameter(Mandatory=$true)]
	$vcenter
	)
	


$RAMlimit = 4
$CPUlimit = 2
###testing
#$selectedVMs = import-csv "\\test-$(get-date -f yyy.MM.dd).csv" |sort-object -property name
####

$selectedVMs = import-csv "\\VM-Resource-Reduction-Before-$(get-date -f yyy.MM.dd).csv"
if($selectedVMs)
{
	$outputObject = $selectedVMs | select-Object -property Name,"CPU Provisioned", "Memory Provisioned" | sort-object -property name
	#$VmsToReduce.name
#Get all $VMs and shutdown guest os
connect-viserver $vcenter
$VMsToReduceCount = get-vm $selectedVMs.name -server $vcenter 
$VMsToReduceCount | Shutdown-VMGuest -Confirm:$False



#add expected cpu and memory / status fields


#Sleep 2 minutes
#change to 10 minutes on friday
#Start-Sleep -s 600
Start-Sleep -s 10
#Get VMs that may still be powered on, if Null continue, if not, force-shutdown
If(get-vm $selectedVMs.name -server $vcenter | where {$_.powerstate -eq "PoweredOn"})
{
	get-vm $selectedVMs.name -server $vcenter | where {$_.powerstate -eq "PoweredOn"} | Stop-VM -Confirm:$False -RunAsync
}
#Get VMs that are still powered on (errors)
#Start-Sleep -s 120
Start-Sleep -s 10
#$numPoweredOn = (get-vm $selectedVMs.name -server $vcenter | where {$_.powerstate -eq "PoweredOn"}).count
 
#Get VMs that will be reduced
 $offVMs = (get-vm $selectedVMs.name -server $vcenter | where {$_.powerstate -eq "PoweredOff"} | sort-object name)
 $x=0;
	$outputObject | add-member -memberType noteproperty -Name "Expected CPU" -value 0
	$outputObject | add-member -memberType noteproperty -Name "Expected Memory" -value 0
	$outputObject | add-member -memberType noteproperty -Name "isReduced" -value False

	
	
 
 foreach ($vm in $offVMs)
 {

	$newVmSize = $selectedVMs|where-object {$_.name -eq $vm.name}
	#Getting new CPU value, but not lower than CPUlimit
	$newCPU = [math]::max($CPUlimit,($newVmSize."CPU Provisioned" - $newVmSize."CPU Reclaimable"))
	#Getting new RAM value, but not lower than RAMlimit
	$newMem = [math]::max($RAMlimit,($newVmSize."Memory Provisioned" - $newVmSize."Memory Reclaimable"))
	
	$setvm = get-vm $vm -server $vcenter | set-vm -MemoryGB $newMem -NumCpu $newCPU -Confirm:$False -RunAsync

	$outputObject[$x]."Expected CPU" = $newCPU
	$outputObject[$x]."Expected Memory" = $newMem

if($setvm)
{
	$outputObject[$x].isReduced = "True"	
}else{
$LogError
#error log not finished for setvm
}
	$x++;
}




get-vm $selectedVMs.name -server $vcenter | start-vm -Confirm:$False -RunAsync

Start-Sleep -s 60

$poweredOffVMs = get-vm $selectedVMs.name -server $vcenter | where {$_.powerstate -eq "PoweredOff"} | sort-object name

foreach ($vm in $poweredOffVMs)
{
$newCPU = $outputObject | where {$_.name -eq $vm.name} | select "Expected CPU"

	get-vm $vm -server $vcenter | set-vm -corespersocket $newCPU."Expected CPU" -Confirm:$False
	Start-Sleep -s 10
	get-vm $vm -server $vcenter | start-vm -Confirm:$False
}
### at the end compared each VM's CPU / MEMORY with the final CPU/MEMORY list to determine isresized and set value as necessary.



#Start-Sleep -s 120
Start-Sleep -s 10
#Check for Powered off VMs

$poweredOffVMs = get-vm $selectedVMs.name -server $vcenter | ? {$_.powerstate -eq "PoweredOff"} | sort-object -Property name
$completedVMs = get-vm $selectedVMs.name -server $vcenter |  select name, numcpu, memorygb 

$failures = get-vm $poweredOffVMs -server $vcenter | Select name, NumCpu, MemoryGB



	$outputObject = $outputObject | Select-Object name,@{Name="Before CPU";Expression={$_."CPU Provisioned"}},@{Name="Before Memory";Expression={$_."Memory Provisioned"}},"Expected CPU","Expected Memory","isReduced"
	$outputObject| export-csv -path "\\VM-Resource-Reduction-Completed-$(get-date -f yyy.MM.dd).csv"
#Report on sucessess

if($poweredOffVMs.count -eq 0 )
{

	Send-MailMessage -BodyAsHtml -Body "$($outputObject | convertTo-html)"`
	-From "scriptinghost" `
	-To "teamname" `
	-Smtpserver "smtpserver" `
	-Subject "Dev/Test Resource Reduction Completed"
}else{

	$failures| export-csv -path "\\Resource_Reduction\VM-Resource-Reduction-Failures-$(get-date -f yyy.MM.dd).csv" 
	$FailuresOutput=$failures | sort-object -Property name | ConvertTo-Html -head $format

	Send-MailMessage -BodyAsHtml -Body "$($FailuresOutput)"`
	-From "scriptinghost" `
	-To "teamname" `
	-Smtpserver "smtpserver" `
    -Subject "Dev/Test Resource Reduction Completed With Errors"

}
#Email Summary

disconnect-viserver $vcenter -Confirm:$False
}
