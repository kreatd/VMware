<#
.SYNOPSIS
Reports back if the SFCBD watchdog service is running on hosts
 
.DESCRIPTION


.EXAMPLE

#>
param(
    [string[]] $vcenters=@("vcenter1")
    )

$emailoutput=@()

Connect-VIServer $vcenters

$hosts = get-vmhost -server $vcenters | where {$_.name -like "esxc*" -and $_.ConnectionState -like "Connected" -or $_.ConnectionState -like "Maintenance" -and $_.version -notlike "7*" -and $_.build -notlike "17700523"} | sort-object -property name

$runninghosts=$hosts| Get-VMHostService | where {$_.Key -like "sfcbd-watchdog" -and $_.running -like "true"}|Select-Object -Property VMHost,running  

foreach($vmhost in $runninghosts)
{
    $vmhost.vmhost | get-vmhostservice -refresh
    start-sleep 1
}

$runninghosts=$hosts| Get-VMHostService | where {$_.Key -like "sfcbd-watchdog" -and $_.running -like "true"}|Select-Object -Property VMHost,running  

foreach($vmhost in $runninghosts)
{ 
    $emailoutput+=$vmhost.vmhost.name +"<br>"
}

if($emailoutput.count -eq 1){

    Send-MailMessage -BodyAsHtml "One host requires Set-DisableSFCB remediation: <br> $emailoutput" `
        -From "scriptinghostemail" `
        -To "teamemail" `
        -Smtpserver "smtpserver" `
        -Subject "[Alert] Hosts with SFCB service running"

}
if($emailoutput.count -gt 1){

    Send-MailMessage -BodyAsHtml "There are $($runninghosts.count) hosts that require Set-DisableSFCB remediation: <br> $emailoutput" `
        -From "scriptinghostemail" `
        -To "teamemail" `
        -Smtpserver "smtpserver" `
        -Subject "[Alert] Hosts with SFCB service running"
}

disconnect-viserver * -confirm:$false
