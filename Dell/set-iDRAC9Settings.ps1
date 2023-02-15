<#

.DESCRIPTION
This script will take in what you set within idracs.csv and run a bunch racadm commands to go through the admin/additional user add process
BE SURE TO FOLLOW THE FORMAT OF THE CSV!

.PARAMETER <Parameter_Name>
 $Location = A or B (datacenter location of hosts) Keep in mind that if you're working in a new datacenter... to use an appropriate name.
 $NewPassword = Our default iDRAC password.

.NOTES
  Version:        1.0
  Author:         Daniel Kreatsoulas
  Creation Date:  2019.12.18
  Purpose/Change: Initial script development
.EXAMPLE
#Modify the idracs.csv file in \Dell\ prior to running this script (be sure to save it and blank it out when you're done.)
BE SURE TO FOLLOW THE FORMAT OF THE CSV!
./set-iDRAC9Settings.ps1 -Location "B" -NewPassword "enter idrac password" -saeDefaultPass "enter sae default password" -path "path to csv"
#>

param(
	[Parameter(Mandatory=$true)]
	[string] $Location = $(throw "Location is required, either A or B."),
	[Parameter(Mandatory=$true)]
	[string] $newPassword = $(throw "New IDRAC Password is required."),
	[string] $idracDefaultUser = "root",
    [string] $idracDefaultPass = "calvin",
    [string] $saeDefaultUser = "DefUser",
    [Parameter(Mandatory=$true)]
	[string] $saeDefaultPass = $(throw "Sae Default User Password required"),
    [string] $idracUser = "USER",
    [string] $racadm = "C:\Program Files (x86)\WindowsPowerShell\Modules\racadm.exe",
    [string] $path = $path,
    [string] $dnsip,
    [string] $DatacenterAcode,
    [string] $DatacenterBcode
)
. "E:\DellPEWSManTools\Public\PEDRAC\New-PEDRACSession.ps1"
. "E:\DellPEWSManTools\Public\PEDRAC\Set-PEDRACUser.ps1"
. "E:\DellPEWSManTools\Public\PESERVER\Get-PESystemInformation.ps1"

$vmhost = import-csv $path
if($Location -eq "A" -or $Location -eq "B")
{
$DataCenter = @{"A" = $DatacenterAcode;"B" = $DatacenterBcode}
}else{
$Datacenter = @{$Location = "$($Location)000001"}
}


$idracSecureStringPwd = $newPassword | ConvertTo-SecureString -AsPlainText -Force
$DefaultSecureStringPwd = $idracDefaultPass | ConvertTo-SecureString -AsPlainText -Force
$saeSecureStringPwd = $saeDefaultPass | ConvertTo-SecureString -AsPlainText -Force

$DefaultCreds = New-Object System.Management.Automation.PSCredential -ArgumentList $idracDefaultUser, $DefaultSecureStringPwd
$saeCreds = New-Object System.Management.Automation.PSCredential -ArgumentList $saeDefaultUser, $saeSecureStringPwd
$idracCreds = New-Object System.Management.Automation.PSCredential -ArgumentList $idracUser, $idracSecureStringPwd


for($i=0;$i -lt $vmhost.length;)
{

$DataCenterRack = ($datacenter[$Location]) + "-" + $vmhost[$i].rack

#create sae account
$saeiDRACSession = New-PEDRACSession -IPAddress $vmhost[$i].ip -Credential $DefaultCreds
Set-PEDRACUser -idracsession $saeiDRACSession -userNumber 16 -Credential $saeCreds

#set sae specific permissions (read only account)
#####old commands that worked prior to idrac version 4.40.40.x.x
####& $racadm -r $vmhost[$i].host -u $idracDefaultUser -p $idracDefaultPass config -g cfgUserAdmin -i 16 -o cfgUserAdminPrivilege 0x1
####& $racadm -r $vmhost[$i].host -u $idracDefaultUser -p $idracDefaultPass config -g cfgUserAdmin -i 16 -o cfgUserAdminIpmiLanPrivilege 15
####& $racadm -r $vmhost[$i].host -u $idracDefaultUser -p $idracDefaultPass config -g cfgUserAdmin -i 16 -o cfgUserAdminIpmiSerialPrivilege 15
####& $racadm -r $vmhost[$i].host -u $idracDefaultUser -p $idracDefaultPass config -g cfgUserAdmin -i 16 -o cfgUserAdminSolEnable 0
####& $racadm -r $vmhost[$i].host -u $idracDefaultUser -p $idracDefaultPass config -g cfgUserAdmin -i 16 -o cfgUserAdminEnable 1  
& $racadm -r $vmhost[$i].host -u $idracDefaultUser -p $idracDefaultPass set idrac.users.16.Privilege 0x1
& $racadm -r $vmhost[$i].host -u $idracDefaultUser -p $idracDefaultPass set idrac.users.16.IpmiLanPrivilege 15
& $racadm -r $vmhost[$i].host -u $idracDefaultUser -p $idracDefaultPass set idrac.users.16.IpmiSerialPrivilege 15
& $racadm -r $vmhost[$i].host -u $idracDefaultUser -p $idracDefaultPass set idrac.users.16.SolEnable disabled
& $racadm -r $vmhost[$i].host -u $idracDefaultUser -p $idracDefaultPass set idrac.users.16.Enable enabled
#set iDrac settings
& $racadm -r $vmhost[$i].host -u $idracDefaultUser -p $idracDefaultPass set System.Location.DataCenter $DataCenterRack
& $racadm -r $vmhost[$i].host -u $idracDefaultUser -p $idracDefaultPass set System.Location.Rack.Name $vmhost[$i].rack
& $racadm -r $vmhost[$i].host -u $idracDefaultUser -p $idracDefaultPass set System.Location.Rack.Slot $vmhost[$i].u
& $racadm -r $vmhost[$i].host -u $idracDefaultUser -p $idracDefaultPass set System.ServerOS.HostName $vmhost[$i].host
& $racadm -r $vmhost[$i].host -u $idracDefaultUser -p $idracDefaultPass set idrac.NTPConfigGroup.ntp1 $dnsip
& $racadm -r $vmhost[$i].host -u $idracDefaultUser -p $idracDefaultPass set idrac.NTPConfigGroup.NTPEnable Enabled
& $racadm -r $vmhost[$i].host -u $idracDefaultUser -p $idracDefaultPass set idrac.time.timezone US/Eastern

#Rename iDRAC Root Account
$iDRACSession = New-PEDRACSession -IPAddress $vmhost[$i].ip -Credential $DefaultCreds
Set-PEDRACUser -idracsession $iDRACSession -userNumber 2 -Credential $idracCreds

    $i++;
}   