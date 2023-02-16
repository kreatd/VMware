<#
.SYNOPSIS
This script will update all host passwords within the entered vcenter.  It will also update the host and vcsa creds encrypted files

.DESCRIPTION

.PARAMETER NONE

.NOTES
  Version:        1.0
  Author:         Daniel Kreatsoulas
  Creation Date:  11/12/2021
  Purpose/Change: Initial script development

.EXAMPLE
  ./change-hostpasswords.ps1 -vcenter vcenter1

#>

Param (	[String] $vCenter 					= (Read-Host "Enter Virtual Center"),
		[System.Security.SecureString] $RootPassword 		= (Read-Host "Enter current root password" -AsSecureString),
		[System.Security.SecureString] $NewPassword 		= (Read-Host "Enter new root password" -AsSecureString),
		[System.Security.SecureString] $NewPasswordVerify 	= (Read-Host "Re-enter new root password" -AsSecureString)
)


$RootCredential = new-object -typename System.Management.Automation.PSCredential -argumentlist "root",$RootPassword
$NewRootCredential = new-object -typename System.Management.Automation.PSCredential -argumentlist "root",$NewPassword
$NewRootCredentialVerify = new-object -typename System.Management.Automation.PSCredential -argumentlist "root",$NewPasswordVerify

if(($NewRootCredential.GetNetworkCredential().Password) -ne ($NewRootCredentialVerify.GetNetworkCredential().Password)) {
	throw "Passwords do not match!!!"
}


$LogFile = "\\logs\Change-HostPasswords-$(get-date -f yyy.MM.dd).csv"


Add-Content $Logfile "Date,Host,Result"

# These are used for various scripts including some of the daily reports.
$NewRootCredential.Password | ConvertFrom-SecureString | Out-File "E:\local\creds.txt"
# This is used for get-ssl cert script.
$NewRootCredential.Password | ConvertFrom-SecureString | Out-File "E:\local\vcsacreds.txt"

Connect-VIServer -server $vCenter | Out-Null

$VMHosts = Get-VMHost -server $vcenter


$VMHosts | % {
Disconnect-VIServer * -Confirm:$false
Write-Debug ($_.Name + " - attempting to connect")
$hostconnection = Connect-viserver -server $_.name -Credential ($RootCredential) -ErrorAction SilentlyContinue
if($hostconnection.IsConnected -eq $True) {
    Write-Debug ($_.Name + " - connected")
    $VMHost = $_
    try {
    
    Set-VMHostAccount -server $_.name -UserAccount root -Password $NewRootCredential.GetNetworkCredential().Password
    disconnect-viserver $_.name -confirm:$false
    Write-Debug ($VMHost.Name + " - password changed")
	Add-Content $Logfile ((get-date -Format "dd/MM/yy HH:mm")+","+$VMHost.Name+",Success")

}catch {
    Write-Debug ($VMHost.Name + " - password change failed")
    Write-Debug $_
    Add-Content $Logfile ((get-date -Format "dd/MM/yy HH:mm")+","+$VMHost.Name+",Failed (Password Change)")
}

#Disconnect-VIServer -Server $vmhost.Name -Confirm:$false -ErrorAction SilentlyContinue 
Write-Debug ($vmhost.Name + " - disconnected")
} else {
Write-Debug ($_.Name+" - unable to connect")
Add-Content $Logfile ((get-date -Format "dd/MM/yy HH:mm")+","+$_.Name+",Failed (Connection)")
}
}
