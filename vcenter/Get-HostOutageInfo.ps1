<#
.SYNOPSIS

 
.DESCRIPTION
This script will generate the list of HA'd vms along with the necessary emails we have to send out for communication during a host failure.

.INPUTS
vcenter
 
.OUTPUTS
HA list email
IOC Email
Leadership Email
.NOTES
  Version:        1.0
  Author:         Daniel Kreatsoulas
  Creation Date:  8 / 10 / 2021
  Purpose/Change: Initial script development
.EXAMPLE
  ./Get-HostOutageInfo -vcenter "enter vcenter name"

    

#>



param(
[string[]] $vCenter = @("vcenter1"),
[string[]] $hostname
)
$vcenter = connect-viserver $vCenter

$Date=Get-Date
$monthday=get-date -UFormat "%B %d"
$PastHours=1
$Events = Get-VIEvent -maxsamples 100000 -Start ($Date).AddHours(-$PastHours) -type warning | Where {$_.FullFormattedMessage -match "restarted" -and $_.FullFormattedMessage -notlike "*Nuage-VRS*"} |sort CreatedTime -Descending
$HAvms = $events|select ObjectName,CreatedTime|sort CreatedTime
#$firstevent = $havms[0].CreatedTime
$lastevent = $havms[-1].CreatedTime
$hostevents = Get-VIEvent -Start ($Date).AddHours(-1)| where {$_.FullFormattedMessage -match "vSphere HA detected a possible host failure of host"}

if($hostevents){

	if(!$hostname){
		$hostname=$hostevents[0].FullFormattedMessage.Split("host").Split("in")[2]
	}

$firsthostevent = $hostevents[0].CreatedTime
}else{
	$hostevents = Get-VIEvent -server $vcenter -maxsamples 100000 -Start ($Date).AddHours(-$PastHours) -type Error | Where {$_.FullFormattedMessage -match "not responding"} |sort CreatedTime -Descending
	if(!$hostname){
	$hostname=$hostevents[0].FullFormattedMessage.Split("Host").Split("in")[1]
	}
	$firsthostevent = $hostevents[0].CreatedTime.addminutes(-2)
}

#$hostevents = Get-VIEvent -maxsamples 100000 -Start ($Date).AddHours(-$PastHours) -type Error | Where {$_.FullFormattedMessage -match "vSphere HA detected a possible host failure of host"} |sort CreatedTime -Descending |select -last 1
#$NotRespondingHosts = $hostevents|select ObjectName,CreatedTime|sort CreatedTime

#$firstevent = $havms[0].CreatedTime
#$hostname=$hostevents[0].FullFormattedMessage.Split("Host").Split("in")[1]

$hostname=$hostname.Trim()
#write-output "Host Not Responding at "  $firsthostevent
#write-output "Last HA event at " $lastevent
$HAvms = $HAvms | select ObjectName|sort ObjectName 
#$output=$HAvms | ForEach-Object {'{0}' -f $_.ObjectName}
#$output=$output.Split([Environment]::NewLine)
$vmcount=$HAvms.count
<#
$time1 = $firsthostevent.tostring("h:mm tt")
$lastevent
$lastevent = $lastevent.AddMinutes(3)
$haexactlastevent = $lastevent.tostring("h:mm tt")
$time2 = $lastevent.tostring("h:mm tt")
$time2
#>
$time1 = $firsthostevent.tostring("h:mm tt")
write-host "host event" $time1
$haexactlastevent = $lastevent
$haexactlastevent = $haexactlastevent.tostring("h:mm tt")
write-host "exact time2" $haexactlastevent
$lastevent = $lastevent.AddMinutes(3)
$time2 = $lastevent.tostring("h:mm tt")
write-host "ha" $time2




if ( $hostname -like "*zzzz*" ) { $location = "zzz"      }
elseif ( $hostname -like "*xxxx*" ) { $location = "xxx"    }
elseif ( $hostname -like "*cccc*" ) { $location = "ccc"   }
elseif ( $hostname -like "*vvvv*" ) { $location = "vvv" }
elseif ( $hostname -like "*bbbb*" ) { $location = "bbb"  }
elseif ( $hostname -like "*nnnn*" ) { $location = "nnn"    }



$hostcluster = get-vmhost $hostname | select parent,@{N="dc";E={Get-Datacenter -VMHost $_}}



foreach ($vm in $HAvms.objectname) 
	{ 
		$vmlist+=$vm + "<br>"
	}

$totaltime=new-timespan -start $firsthostevent -end $lastevent
$totalseconds=[math]::Round($totaltime.seconds,0)
$totalminutes=[math]::Round($totaltime.minutes,0)

Send-MailMessage -BodyasHtml "Datacenter: $($location) <br> HA Failure at $($time1) <br> Last HA event at $($haexactlastevent) <br> Host: $($hostname) <br> VM List: <br> $($vmlist)"  `
	-From "" `
	-To "" `
	-Smtpserver "" `
    -Subject "[Alert] HA'd VMs"


disconnect-viserver * -Confirm:$false -force


$output+="<style>"
$output+="p{ font-size: 13pt; }"
$output+="</style>"
$output+="<p>Please send out the following service informational</p>"

$output+="<p><span style=' color: red;'>$($monthday)/ $($time2) / Service Informational:&nbsp;</span>Virtual Infrastructure Issue at $($location) Data Center</p>"
if($hostcluster.dc -like "DC04" -or $hostcluster.dc -like "DC01" -and $hostcluster.parent -notlike "*MGT*")
{
$output+="<p><span style=' color: red;'>Description:&nbsp;</span>The Virtual Infrastructure Support team is reporting an ESXi host ($($hostname)) failed at $($time1) affecting $($vmcount) servers at the $($location) data center.  This ESXi host has redundancy by design, allowing for the VMs on the host to remain down but have no impact to production. Attached is the list of affected systems. The incident was caused by a hardware failure and the server has been taken out of production use for maintenance.</p>"

}else{

$output+="<p><span style=' color: red;'>Description:&nbsp;</span>The Virtual Infrastructure Support team is reporting an ESXi host ($($hostname)) failed at $($time1) affecting $($vmcount) servers at the $($location) data center.The High Availability (HA) service functioned as expected and all systems were rebooted and are back up as of $($time2). Attached is the list of affected systems. The incident was caused by a hardware failure and the server has been taken out of production use for maintenance.</p>"

}
$output+="<p><span style=' color: red;'>Impact:&nbsp;</span>Dept/Multiple Users</p>"

$output+="<p><span style=' color: red;'>Business Impact:&nbsp;</span>Unknown number of users were impacted</p>"

$output+="<p><span style=' color: red;'>Patient Care Impact:&nbsp;</span>Unknown</span></p>"

if($totaltime.TotalSeconds -lt 60){
    $output+="<p><span style=' color: red;'>Elapsed Time:&nbsp;</span>0 Hours 0 Minutes $($totalseconds) Seconds ($($time1) &ndash;$($time2))</p>"
}else{
    $output+="<p><span style=' color: red;'>Elapsed Time:&nbsp;</span>0 Hours $($totalminutes) Minutes $($totalseconds) Seconds ($($time1) &ndash;$($time2))</p>"
}

$output+="<p><span style=' color: red;'>ETR:&nbsp;</span>Unknown at this time.</p>"

$output+="<p><span style=' color: red;'>Support Team(s):&nbsp;</span>Virtual Infrastructure Support-*</p>"

$output+="<p><span style=' color: red;'>Vendor(s) Engaged:&nbsp;</span>NA</p>"

$output+="<p><span style=' color: red;'>Cherwell Incident Number:&nbsp;</span><strong><span style='color: #000000;'><span style='background-color: #ffff00;'>MANUALLY SET THIS VALUE</span></span></strong></span></p>"



Send-MailMessage -BodyAsHtml -Body "$($output)" `
	-From ""  `
	-To "" `
	-Smtpserver "" `
	-Subject "[TEST] Email to IOC"

$output2+="<style>"
$output2+="p{ font-size: 13pt; }"
$output2+="</style>"
$output2+="<p>We lost an ESXi host at $($location) due to a hardware failure.  All $($vmcount) VMs have HA'd and are available.</p>"
$output2+="<p>List of affected servers:</p>"
$output2+="<p>$($vmlist)</p>"

Send-MailMessage -BodyAsHtml -Body "$($output2)" `
	-From ""  `
	-To "" `
	-Smtpserver "" `
	-Subject "[TEST] mail to leadership"
