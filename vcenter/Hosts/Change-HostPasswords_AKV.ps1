<#
.SYNOPSIS
This script will update all host passwords within the entered vcenter. 
This version of the change host passwords script will update the key vault as well as use the key vault assigned password as the password that'll be applied to the hosts in vcenter.

.DESCRIPTION
Tenant ID - comes from Azure Active Directory
AppId - Derives from app registration
appid_pass - also derives from app registration 

.PARAMETER NONE

.NOTES
  Version:        1.0
  Author:         Daniel kreatsoulas
  Creation Date:  11/12/2021
  Purpose/Change: Initial script development

.EXAMPLE
  ./change-hostpasswords_AKV.ps1 -vcenter vcenter1

#>


Param (	[String] $vCenter 					= (Read-Host "Enter Virtual Center"),
[System.Security.SecureString] $RootPassword 		= (Read-Host "Enter current root password" -AsSecureString),
[System.Security.SecureString] $NewPassword 		= (Read-Host "Enter new root password" -AsSecureString),
[System.Security.SecureString] $NewPasswordVerify 	= (Read-Host "Re-enter new root password" -AsSecureString),
$update 	= (Read-Host "Update Key vault? Yes or No")
)

$NewRootCredential = new-object -typename System.Management.Automation.PSCredential -argumentlist "root",$NewPassword
$NewRootCredentialVerify = new-object -typename System.Management.Automation.PSCredential -argumentlist "root",$NewPasswordVerify

if(($NewRootCredential.GetNetworkCredential().Password) -ne ($NewRootCredentialVerify.GetNetworkCredential().Password)) {
throw "Passwords do not match!!!"
}

if($update -eq "Yes"){
  $appId = "idofapp"
  $appid_pass = Get-Content "E:\appidpass.txt" | ConvertTo-SecureString
  $tenant = "tenantid"
  
  $credential = New-Object System.Management.Automation.PSCredential -ArgumentList $appId,$appid_pass
  
  $azConnection = Connect-AzAccount -Credential $credential -Tenant $tenant -ServicePrincipal
  
  $secret = Get-AzKeyVaultSecret -VaultName "kvname" -Name "nameofsecret"
  
  $RootPassword = $secret.secretvalue
  
  $RootCredential = new-object -typename System.Management.Automation.PSCredential -argumentlist "root",$RootPassword

  #sets the root password within the production azure key vault
  Set-AzKeyVaultSecret -VaultName "kvname" -name "nameofsecret" -SecretValue $NewPassword

}else{
  $RootCredential = new-object -typename System.Management.Automation.PSCredential -argumentlist "root",$RootPassword
}

$LogFile = "\\logs\Change-HostPasswords-$(get-date -f yyy.MM.dd).csv"

Add-Content $Logfile "Date,Host,Result"

#sets the password locally on the scripting server (legacy and can be removed once all other scripts have been updated with the azure key vault in mind)
$NewRootCredential.Password | ConvertFrom-SecureString | Out-File "E:\hcreds.txt"
$NewRootCredential.Password | ConvertFrom-SecureString | Out-File "E:\vcreds.txt"

Connect-VIServer -server $vCenter | Out-Null

$VMHosts = Get-VMHost -server $vcenter

Disconnect-VIServer * -Confirm:$false

$VMHosts | % {

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

