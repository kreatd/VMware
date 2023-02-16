<#
.EXAMPLE
  .\ping-loop_fast_cluster.ps1 -vcenter "" -cluster ""
#>

param(
	[string[]] $vcenter,
    [string] $cluster,
	$loop = 1000,
	[switch]$log
)

Connect-VIServer $vcenter

function fastping{
  [CmdletBinding()]
  param(
  [String]$computername = "127.0.0.1",
  [int]$delay = 5
  )

  $ping = new-object System.Net.NetworkInformation.Ping
  # see http://msdn.microsoft.com/en-us/library/system.net.networkinformation.ipstatus%28v=vs.110%29.aspx
  try {
    if ($ping.send($computername,$delay).status -ne "Success") {
      return $false;
    }
    else {
      return $true;
    }
  } catch {
    return $false;
  }
}

if($log)
{
	$date = get-date -f yyyy.MM.dd
	$logfile = "ping-loop-log.$date.txt"
	get-date |out-file -append $logfile
}
$i = 0
$names = get-cluster $cluster| get-vm | where {$_.name -notlike "*xxx*" -and $_.powerstate -eq "PoweredOn"} | select @{N="name";E={@($_.name + "domain.xxx.xxx")}},@{N="vmhost";E={@($_.vmhost)}},@{N="IP";E={@($_.guest.IPAddress[0])}} | sort-object -property name

Do
{
$output = @()
foreach ($name in $names)
{

$output += $name.name + "," + $(fastping -computername $name.name) + "," + $name.vmhost.name + "," + $name.IP

}

$output|%{if($_.split(",")[1].trim() -eq "False"){write-host $_ -foregroundcolor "red"}}

$numfail = ($output|?{$_.split(",")[1].trim() -eq "False"}).count
$numsuccess = $output.count - $numfail
write-host "Number of successes: $numsuccess"
write-host "Number of failures: $numfail"
if($log)
{
	$Fails = $output|%{if($_.split(",")[1].trim() -eq "False"){$_}}
	$Fails|out-file -append $logfile
	"Number of successes: $numsuccess"|out-file -append $logfile
	"Number of failures: $numfail"|out-file -append $logfile
}

start-sleep -s 5
$i++
} while($i -lt $loop)

if($log){get-date |out-file -append $logfile}