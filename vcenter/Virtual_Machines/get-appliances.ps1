<#
.SYNOPSIS
	This script generates a list of unix appliances 

.PARAMETER NONE
-vcenters vcenters

.NOTES
  Version:        1.0
  Author:          Daniel Kreatsoulas
  Creation Date:  3/21/2018
  Purpose/Change: Initial script development

  Update Date: 5/24/2019 

.EXAMPLE
./get-appliances.ps1 -vcenters allvcs

#>
param(
	[string[]] $vCenters = @("vcenter1","allvs")
	)
	
function ErrorHandler($error) 
{
   Send-MailMessage -BodyAsHtml "$error" `
	-From "scriptinghost" `
	-To "visupport@upmc.edu" `
	-Smtpserver "smtpserver" `
    -Subject "Linux Appliance Changes Failure"
}

trap { ErrorHandler $_; break }


connect-viserver $vCenters
$unmanaged = get-folder "unmanaged"
$LinuxAppliances = $unmanaged|?{$_.parent.name -eq "Linux"}|get-vm|sort name

$output = @()
$tgtEvents = 'VmBeingDeployedEvent','VmRegisteredEvent','VmClonedEvent','VmBeingCreatedEvent'
foreach ($vm in $LinuxAppliances)
{
	$event = Get-VIEvent -Entity $vm -MaxSamples ([int]::MaxValue) | Where {$tgtEvents -contains $_.GetType().Name}|select -last 1
	if($event){$eventTime = $event.CreatedTime.tostring()}
	else{$eventTime = "NA"}
		
	$output += $vm | select name, @{n="OS";e={$_.Guest.OSFullName}}, PowerState, @{n="vCenter";e={$_.uid.split("@")[1].split(":")[0]}}, @{n="CreationDate";e={$eventTime}}
}


$app=Get-ChildItem "\\\app_appliance*" -File | Where name -ne "app_appliances-$(get-date -f yyy.MM.dd).csv" | select -first 1
$in = import-csv -Path "\\\$($app.name)"
$output|export-csv -notypeinformation "\\\app_appliances-$(get-date -f yyy.MM.dd).csv"




####removed
$x="";$y="";
Compare-Object -ReferenceObject $in.Name  -DifferenceObject $output.Name | 
    Where-Object { $_.SideIndicator -eq '=>' } | 
    ForEach-Object  { $x+=$_.InputObject+","}
    $new=$x.Trim(","," ")

####new
Compare-Object -ReferenceObject $in.Name  -DifferenceObject $output.Name | 
    Where-Object { $_.SideIndicator -eq '<=' } | 
    ForEach-Object  { $y+=$_.InputObject+"," }
    $removed=$y.Trim(","," ")

if($new -and $removed) {
$htmloutput="<html><p>A new appliance list has been generated here: \\app_appliances-$(get-date -f yyy.MM.dd).csv</p><h3> New Appliances </H3> $new <br> <H3> Removed Appliances</H3> $removed</html>"
Get-ChildItem "\\\app_appliance*" -File | Where name -ne "app_appliances-$(get-date -f yyy.MM.dd).csv"  | Remove-Item 
Send-MailMessage -BodyAsHtml "$htmloutput" `
	-From "scriptinghost" `
	-To "x","y" `
	-Smtpserver "smtpserver" `
    -Subject "Linux Appliance Changes" 
}
if(!$new -and $removed) {
$htmloutput="<html><p>A new appliance list has been generated here: \\app_appliances-$(get-date -f yyy.MM.dd).csv</p><H3> Removed Appliances</H3> $removed</html>"
Get-ChildItem "\\\app_appliance*" -File | Where name -ne "app_appliances-$(get-date -f yyy.MM.dd).csv"  | Remove-Item 
Send-MailMessage -BodyAsHtml "$htmloutput" `
	-From "scriptinghost" `
	-To "x","y" `
	-Smtpserver "smtpserver" `
    -Subject "Linux Appliance Changes"
}
if($new -and !$removed) {
$htmloutput="<html><p>A new appliance list has been generated here: \\app_appliances-$(get-date -f yyy.MM.dd).csv</p><h3> New Appliances </H3> $new</html>"
Get-ChildItem "\\\app_appliance*" -File | Where name -ne "app_appliances-$(get-date -f yyy.MM.dd).csv"  | Remove-Item 
Send-MailMessage -BodyAsHtml "$htmloutput" `
	-From "scriptinghost" `
	-To "x","y" `
	-Smtpserver "smtpserver" `
    -Subject "Linux Appliance Changes"
}
if(!$new -and !$removed) {
Get-ChildItem "\\backups\app_appliance*" -File | Where name -ne "app_appliances-$(get-date -f yyy.MM.dd).csv"  | Remove-Item 
}

if($error)
{
ErrorHandler($error)
}

disconnect-viserver * -force -confirm:$false