<#
.SYNOPSIS
Reports back if the SLPD service is running on all hosts
 
.DESCRIPTION


.EXAMPLE

#>
param(
    [string[]] $vcenter=@("vcenter1"),
    [string] $location = "."
    )

$emailoutput=@()
$output=@{}
$outputObject=@()

#$Secure = Read-Host -AsSecureString
$Secure = Get-Content "E:\vcreds.txt" | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential("root",$Secure)

Connect-VIServer $vcenter

$hosts = get-vmhost -server $vcenter | sort-object -property name

foreach ($esx in $hosts) {
if($esx.name -like "esxhostname*")
{
    write-output "starting ssh services on $esx"
$sshstatus= Get-VMHostService  -VMHost $esx| where {$psitem.key -eq "tsm-ssh"}
if ($sshstatus.Running -eq $False) {
    Get-VMHostService -vmhost $esx | where {$psitem.key -eq "tsm-ssh"} | Start-VMHostService -confirm:$false
}
start-sleep 1
$ssh = New-SSHSession -ComputerName $esx -Credential $cred -AcceptKey -KeepAliveInterval 5
write-output "Executing Command on $esx"

$slpdstatus=Invoke-SSHCommand -SessionId $ssh.SessionId -Command "/etc/init.d/slpd status" -TimeOut 30 | select -ExpandProperty Output
$output.add($esx.name,$slpdstatus)

write-output "Ending SSH Session on $esx"
Remove-SSHSession -SessionId $ssh.SessionId | Out-Null
write-output "stopping ssh services on $esx"
$sshstatus= Get-VMHostService  -VMHost $esx| where {$psitem.key -eq "tsm-ssh"}
if ($sshstatus.Running -eq $True) {
    Get-VMHostService -vmhost $esx | where {$psitem.key -eq "tsm-ssh"} | Stop-VMHostService -confirm:$false
}
}
}
$output|%{$_}
$output.getenumerator()|select name,value | export-csv "$location\SLPD_Report_$(get-date -f yyy.MM.dd).csv" -NoTypeInformation

foreach($x in $output.keys){
    if($output[$x] -ne "slpd is not running"){
        $emailoutput+=$x + "<br>"
    }
}

$emailoutput
if($emailoutput){

    Send-MailMessage -BodyAsHtml "Host's that require Set-DisableCIM remediation: <br> $emailoutput" `
        -From "" `
        -To "" `
        -Smtpserver "" `
        -Subject "[Alert] Hosts with SLPD service running"
}else{
    Send-MailMessage -BodyAsHtml "$emailoutput" `
    -From "" `
    -To "" `
    -Smtpserver "" `
    -Subject "SLPD Script Ran Successfully - With Zero Output"


}
    
disconnect-viserver * -confirm:$false
