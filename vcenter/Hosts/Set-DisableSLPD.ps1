<#
.SYNOPSIS
Disable CIM service on ESXi
 
.DESCRIPTION
 This corrects a security vulnerability 

.INPUTS
 takes in vCenter and cluster
 
.OUTPUTS
 outputs commands that are being executed
 
.NOTES
  Version:        1.0
  Author:         Daniel Kreatsoulas
  Creation Date:  11/9/2020
  Purpose/Change: Initial script development

Posh-SSH needs to be installed to run this script.  Also, you should run this from powershell 5.... currently, there's an issue in powershell 6 / 7.

If you receieve the following error: New-SSHSession : Key exchange negotiation failed.
Try the following from your powershell terminal: Get-SSHTrustedHost | Remove-SSHTrustedHost then rerun the script.
.EXAMPLE
  .\Set-DisableCIM.ps1 -vcenter "" -cluster ""
    or full vcenter: .\Set-DisableCIM.ps1 -vcenter ""
#>
param(
    [string[]] $vcenter,
    [string] $cluster
    )

write-output "Enter in esxi root password."
$Secure = Read-Host -AsSecureString
$cred = New-Object System.Management.Automation.PSCredential("root",$Secure)


$credential = get-credential

Connect-VIServer $vcenter -Credential $credential

if($cluster)
{
    $hosts = get-cluster $cluster | get-vmhost
###}else{
###    $hosts = get-vmhost
}
#$hosts = get-vmhost -name $cluster

foreach ($esx in $hosts) {
    write-output "starting ssh services on $esx"
$sshstatus= Get-VMHostService  -VMHost $esx| where {$psitem.key -eq "tsm-ssh"}
if ($sshstatus.Running -eq $False) {
    Get-VMHostService -vmhost $esx | where {$psitem.key -eq "tsm-ssh"} | Start-VMHostService -confirm:$false
}
$ssh = New-SSHSession -ComputerName $esx -Credential $cred -AcceptKey -KeepAliveInterval 5
write-output "Executing Command on $esx"
Invoke-SSHCommand -SessionId $ssh.SessionId -Command "/etc/init.d/slpd stop" -TimeOut 30 | select -ExpandProperty Output
Invoke-SSHCommand -SessionId $ssh.SessionId -Command "esxcli network firewall ruleset set -r CIMSLP -e 0" -TimeOut 30 | select -ExpandProperty Output
Invoke-SSHCommand -SessionId $ssh.SessionId -Command "chkconfig slpd off" -TimeOut 30 | select -ExpandProperty Output
write-output "Ending SSH Session on $esx"
Remove-SSHSession -SessionId $ssh.SessionId | Out-Null
write-output "stopping ssh services on $esx"
$sshstatus= Get-VMHostService  -VMHost $esx| where {$psitem.key -eq "tsm-ssh"}
if ($sshstatus.Running -eq $True) {
    Get-VMHostService -vmhost $esx | where {$psitem.key -eq "tsm-ssh"} | Stop-VMHostService -confirm:$false
}
}

disconnect-viserver * -confirm:$false

