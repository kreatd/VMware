param(
[string[]] $vCenter = @("vcenter1")
)
$vcenter = connect-viserver $vCenter

$Date=Get-Date
$PastHours=6
$Events = Get-VIEvent -maxsamples 100000 -Start ($Date).AddHours(-$PastHours) -type warning | Where {$_.FullFormattedMessage -match "restarted"} |sort CreatedTime -Descending
$HAvms = $events|select ObjectName,CreatedTime|sort CreatedTime
#$firstevent = $havms[0].CreatedTime
$lastevent = $havms[-1].CreatedTime
$hostevents = Get-VIEvent -maxsamples 100000 -Start ($Date).AddHours(-$PastHours) -type Error | Where {$_.FullFormattedMessage -match "not responding"} |sort CreatedTime -Descending
$NotRespondingHosts = $hostevents|select ObjectName,CreatedTime|sort CreatedTime
$firsthostevent = $hostevents[0].CreatedTime
$firstevent = $havms[0].CreatedTime

write-output "Host Not Responding at "  $firsthostevent
write-output "Last HA event at " $lastevent
$HAvms = $HAvms | select ObjectName|sort ObjectName 
#$output=$HAvms | ForEach-Object {'{0}' -f $_.ObjectName}
#$output=$output.Split([Environment]::NewLine)

foreach ($vm in $HAvms.objectname) 
	{ 
		$output+=$vm + "<br>"
	}

Send-MailMessage -BodyasHtml "Datacenter: $($vCenter) <br> Host Not Responding at $($firsthostevent) <br> Last HA event at $($lastevent) <br> VM List: <br> $($output)"  `
	-From "host" `
	-To "teamemail" `
	-Smtpserver "smtpserver" `
    -Subject "[Alert] HA'd VMs"

disconnect-viserver * -Confirm:$false -force

