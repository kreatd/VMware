<#
.SYNOPSIS
  Lease report for VMware Farms at UPMC
 
.DESCRIPTION
  This report sends an email based on lease dates from the past and a defined future
  date range.
 
.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>
 
.INPUTS
  None, reads latest host_details report from Inventory.
 
.OUTPUTS
  Sends email only
 
.NOTES
  Version:        1.0
  Author:         Dave P
  Creation Date:  11/5/2014
  Purpose/Change: Initial script development
    Version:        2.0
  Author:         Dan Kreatsoulas
  Creation Date:  1/22/2019
  Purpose/Change: Added a note for if we don't have any servers up for lease

  Update: on 2/22/2019 by Dan Kreatsoulas, setup new Task on scripting host and changed the TO address to scripting host.
  
.EXAMPLE
  .\get-hostleasedates.ps1
#>
Import-Module EnhancedHTML2

$file = get-item "\\Inventory\VMware_host_details*"|sort name|select -last 1

$hostdata = import-csv $file

$hostdates = @()

foreach ($vmhost in $hostdata)
{
  if($vmhost.lease_end -and $vmhost.lease_end -ne "No Data Found" -and $vmhost.lease_end -ne "No Warranty"){
	$HostDate = ""|select Name,Lease
	$HostDate.name = $vmhost.name
	$hostdate.lease = get-date ($vmhost.lease_end)
	$hostdates += $hostdate}
}

$a = @"
<style>
TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;text-align: center}
TH{border-width: 1px;padding: 5px;border-style: solid;border-color: black;}
TD{border-width: 1px;padding: 5px 10px;border-style: solid;border-color: black;}
.red {
    color:red;
    font-weight:bold;
} 
</style>
"@

$report = $hostdates|?{$_.lease -ne $NULL}|sort lease|?{$_.lease -lt (get-date).adddays(90)}
$month = get-date -format MMMM
if ($report -eq $NULL)
{
  $report= "There are no servers due for a lease refresh."
  Send-MailMessage -Subject "Host Lease Dates: $month" -From "scriptinghostemail" -To "teamemail" -Smtpserver "smtpserver" -Bodyashtml "${report}"
}else{
  $params = @{'As'='Table';
  'Properties'='Name', @{n='Lease';e={$_.lease};css={if ($_.lease -lt (get-date)){'red'}}}}
$htmlLease = $report | convertto-EnhancedHTMLFragment @params

$params = @{'CssStyleSheet' = $a;
  'HTMLFragments' = @($htmlLease)}
  Send-MailMessage -Subject "Host Lease Dates: $month" -From "scriptinghostemail" -To "teamemail" -Smtpserver "smtpserver" -Bodyashtml "$(convertto-enhancedHTML @params)"
}
