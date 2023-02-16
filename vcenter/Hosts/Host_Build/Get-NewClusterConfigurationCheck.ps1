<#
.SYNOPSIS
  Takes parameters and generates an oracle data report

.NOTES
  Version:        1.0
  Author(s):         Daniel Kreatsoulas
  Creation Date:  08/04/2020
  Purpose/Change: Initial script development

.EXAMPLE
./Get-NewClusterConfigurationCheck.ps1  -cluster C01 vcenter vcenter1
#>


<#
check everything line by line / write-output if the setting isn't setup correctly

mclag or no mclag?
vsan?
SDN?

check if vswitch was deleted

if mclag

----------------
vsan cluster:

boss card name and if it's the correct standard

vsan license at cluster level
disable vsan health checks
host profile related:
check is storage configuration is unchecked, but vsan settings are checked - who knows how to do this!
IF SDN -> check agent vm settings
-------------------------



#>




param(  
[Parameter(Mandatory=$true)] 
[string] $cluster = $(throw "cluster is required"),
[Parameter(Mandatory=$true)] 
[string] $vcenter = $(throw "vCenter is required."),
[Parameter(Mandatory=$true)] 
[string] $mclag = $(throw "mclag?"),
[Parameter(Mandatory=$true)] 
[string] $storage = $(throw "VSAN?"),
[Parameter(Mandatory=$true)] 
[string] $sdn = $(throw "SDN?")
)



function get-CTX(){
$cluster = get-cluster $cluster
$vmhost = get-vmhost $vmhost | select -first 1

#check for vswitch
$vswitch = $vmhost| get-virtualswitch -Standard
if($vswitch)
{write-output "vSwitch ${vswitch} needs removed!"}

#vsan cluster/storage settings checks
$firewallexception = Get-VMHostFirewallException -host $vmhost|?{$_.Name -eq 'syslog'}
if($firewallexception.enabled -eq "False")
{write-output "${firewallexception} needs enabled, please run the hostprofilesettings_cluster script!"}

$syslogging = Get-AdvancedSetting -Entity $vmhost -Name Syslog.global.logHost
if($syslogging.value -ne $sysloginfo)
{write-output "${syslogging} needs set, please run the hostprofilesettings_cluster script!"}

$ntpserver = $vmhost | get-vmhostntpserver
if($ntpserver -ne "x.x.x.x")
{write-output "ntpserver needs set, please run the hostprofilesettings_cluster script!"}

$ntpdpolicy = get-vmhostservice -vmhost $vmhost | ?{$_.key -eq "ntpd"}
if($ntpdpolicy.policy -eq "off")
{write-output "ntp policy needs to be turned on, please run the hostprofilesettings_cluster script!"}

if($ntpdpolicy.running -eq "False")
{write-output "ntpd service should be running, please run the hostprofilesettings_cluster script!"}

$LargePageSetting = Get-AdvancedSetting -Entity $vmhost -Name Mem.AllocGuestLargePage
if($LargePageSetting.value -ne 0)
{write-output "mem.allocguestlargepage needs to be set, please run the hostprofilesettings_cluster script!"}

$ShareForceSalting = Get-AdvancedSetting -Entity $vmhost -Name Mem.ShareForceSalting
if($ShareForceSalting.value -ne 0)
{write-output "mem.ShareForceSalting needs to be set, please run the hostprofilesettings_cluster script!"}

$vSANSwapThick = Get-AdvancedSetting -Entity $vmhost -Name VSAN.SwapThickProvisionDisabled
if($vSANSwapThick.value -ne 1)
{write-output "VSAN.SwapThickProvisionDisabled needs to be set, please run the hostprofilesettings_cluster script!"}

$suppressHyper = Get-AdvancedSetting -Entity $vmhost -Name UserVars.SuppressHyperthreadWarning
if($suppressHyper.value -ne 1)
{write-output "UserVars.SuppressHyperthreadWarning needs to be set, please run the hostprofilesettings_cluster script!"}

$vSANClusterConfig = $cluster | get-VsanClusterConfiguration
if($vSANClusterConfig.PerformanceStatsStoragePolicy -notlike "*CTX*")
{write-output "Storage policy is missing from Performance settings."}

if($vSANClusterConfig.PerformanceServiceEnabled -ne "True")
{write-output "Performance service needs to be enabled."}


$vSANDatastore = $vmhost | get-datastore | ?{$_.name -like "*VSAN*"}
if(!$vSANDatastore)
{write-output "vSAN Datastore needs to be renamed to match our standard."}

#trying to figure out how to get the currently vsan-attached storage policy :()


Try {
    
   get-CTX

}

Catch {

    write-output $_.Exception.Message`n

}
#$server = connect-viserver $vcenter

