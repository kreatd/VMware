# Check VMs for HA Protection
param(
	[string[]] $vcenters = @("vcenter-2","vcenter1")
	)
$vcenters=Connect-VIServer $vcenters
$report=@()

foreach ($vcenter in $vcenters)
{
$report = Get-Cluster |
where {$_.HAEnabled} |
Get-VM | 
where {$_.PowerState -ne "PoweredOff"} | 
where {$_.ExtensionData.Runtime.DasVmProtection.DasProtected -ne "True"} |
Select Name,@{N="Protected";E={$_.ExtensionData.Runtime.DasVmProtection.DasProtected}},VMHost
}

$smtpServer = "smtp"
$smtpFrom = "serveremail"
$smtpTo = "teamemail"
$messageSubject = "Virtual Machine HA Protection Status"

$message = New-Object System.Net.Mail.MailMessage $smtpfrom, $smtpto
$message.Subject = $messageSubject
$message.IsBodyHTML = $true

$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"

$value1 = @{Expression='Name';Ascending=$true}

$message.Body = $report|sort-object $value1| ConvertTo-Html -Head $style

$colorTagTable = @{False = ' bgcolor="#ff0000">False<';
					True = ' bgcolor="#00ff00">True<'}
$colorTagTable.Keys | foreach { $message.Body = $message.Body -replace ">$_<",($colorTagTable.$_) }

$smtp = New-Object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($message)

Disconnect-VIServer * -Confirm:$false -force