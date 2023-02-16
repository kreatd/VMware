<#
.DESCRIPTION
	This script takes a list of VMs and shuts them down safely and once they're shutdown, it'll power them all back on.
.PARAMETER NONE
	$vCenter, vCenter(s) that you'd like to connect to
	$inputfile, CSV of VMs

.NOTES
  Version:        1.0
  Author:         Daniel Kreatsoulas
  Creation Date:  05/20/2019
  Purpose/Change: Initial script development

  Update Date:

.EXAMPLE
Shutdown-VMs.ps1 -vcenter "vcenter1" -inputfile "C:\temp2106524152.csv"

#>


param(
    $vcenter,
    $inputfile
)

$inputfile = import-csv $inputfile -header "vms"


$VMs=get-vm $inputfile.vms | where {$_.powerstate -eq "poweredon"}

foreach ($vm in $VMs)
 {
    get-vm $vm | Shutdown-VMGuest -Confirm:$False
 }

 Start-Sleep -s 120

 If(get-vm $VMs | ? {$_.powerstate -eq "PoweredOn"})
{
	get-vm $VMs | ? {$_.powerstate -eq "PoweredOn"} | Stop-VM -Confirm:$False -RunAsync
}

Start-Sleep -s 10

get-vm $VMs | ? {$_.powerstate -eq "PoweredOff"} | Start-VM -Confirm:$False