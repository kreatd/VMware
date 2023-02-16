#### You have to modify the following variables in the script prior to executing: 
#### $scratchDS, $hostname, and $vCenter 
###### Be sure to run this one liner in your powershell window as well. 
######  
 
  
#$scratchDS = "datastore1" 

param(  
[Parameter(Mandatory=$true)] 
[string] $cluster = $(throw "cluster is required"),
[Parameter(Mandatory=$true)] 
[string] $vCenter = $(throw "vCenter is required."),
#[ValidateSet()]
#[parameter(mandatory=$true)]
#[string] $serverType = $(throw "specify the type of server you are working with"), 
[ValidateSet("VSAN","HybridLegacy","Extreme", "HybridFull")]
[parameter(mandatory=$true)]
[string] $storageType = $(throw "specify what type of storage configuration you are working with")
)  

Function Set-VSANSilentHealthChecks {
  param(
      [Parameter(Mandatory=$true)][String]$cluster,
      [Parameter(Mandatory=$true)][String[]]$Test,
      $ntpserver,
      $sysloghostinfo,
      [Switch]$Enabled,
      [Switch]$Disabled
  )
  $vchs = Get-VSANView -Id "VsanVcClusterHealthSystem-vsan-cluster-health-system"
  $cluster_view = (Get-Cluster -Name $cluster).ExtensionData.MoRef

  if($Enabled) {
      $vchs.VsanHealthSetVsanClusterSilentChecks($cluster_view,$null,$Test)
  } else {
      $vchs.VsanHealthSetVsanClusterSilentChecks($cluster_view,$Test,$null)
  }
}
Connect-viserver $vCenter

$hostList = get-vmhost -Location $cluster

if($storageType -eq "VSAN") {
  Set-VSANSilentHealthChecks -Cluster $cluster vumconfig,vsancloudhealthceipexception,hcldbuptodate -Disable
}

foreach ($vmhost in $hostList) {
 


 #VSAN#
  if($storageType -eq "VSAN") {
  
  
        Get-VMHostFirewallException -host $vmhost|?{$_.Name -eq 'syslog'} | Set-VMHostFirewallException -Enabled:$true 
  
        Get-AdvancedSetting -Entity $vmhost -Name Syslog.global.logHost | set-advancedsetting -Value $sysloghostinfo -confirm:$false 
  
        Add-VMhostNTPServer -vmhost $vmhost -ntpserver $ntpserver -confirm:$false 
  
        Get-VmHostService -VMHost $vmhost | Where-Object {$_.key -eq "ntpd"}| set-vmhostservice -policy "On" 
  
        Get-VmHostService -VMHost $vmhost | Where-Object {$_.key -eq "ntpd"} | Start-VMHostService 
  
        Get-AdvancedSetting -Entity $vmhost -Name Mem.AllocGuestLargePage | set-advancedsetting -Value 0 -confirm:$false 
  
        Get-AdvancedSetting -Entity $vmhost -Name Mem.ShareForceSalting | set-advancedsetting -Value 0 -confirm:$false 

        Get-AdvancedSetting -Entity $vmhost -Name VSAN.SwapThickProvisionDisabled | set-advancedsetting -Value 1 -confirm:$false 
		
		    Get-AdvancedSetting -Entity $vmhost -Name "UserVars.SuppressHyperthreadWarning" | Set-AdvancedSetting -Value 1 -confirm:$false

        
    }

  #Legacy (IBM SVC, A9000r)#
  elseif ($storageType -eq "HybridLegacy") {

        Get-VMHostFirewallException -host $vmhost|?{$_.Name -eq 'syslog'} | Set-VMHostFirewallException -Enabled:$true 
  
        Get-AdvancedSetting -Entity $vmhost -Name Syslog.global.logHost | set-advancedsetting -Value $sysloghostinfo -confirm:$false 
  
        Add-VMhostNTPServer -vmhost $vmhost -ntpserver $ntpserver -confirm:$false 
  
        Get-VmHostService -VMHost $vmhost | Where-Object {$_.key -eq "ntpd"}| set-vmhostservice -policy "On" 
  
        Get-VmHostService -VMHost $vmhost | Where-Object {$_.key -eq "ntpd"} | Start-VMHostService 
  
        Get-AdvancedSetting -Entity $vmhost -Name Mem.AllocGuestLargePage | set-advancedsetting -Value 0 -confirm:$false 
  
        Get-AdvancedSetting -Entity $vmhost -Name Mem.ShareForceSalting | set-advancedsetting -Value 0 -confirm:$false

        #Legacy Specific Settings#

        Get-AdvancedSetting -Entity $vmhost -Name DataMover.HardwareAcceleratedMove | set-advancedsetting -Value 0 -confirm:$false
    
        Get-AdvancedSetting -Entity $vmhost -Name DataMover.HardwareAcceleratedInit | set-advancedsetting -Value 0 -confirm:$false

        Get-AdvancedSetting -Entity $vmhost -Name VMFS3.UseATSForHBOnVMFS5| set-advancedsetting -Value 0 -confirm:$false
		
		Get-AdvancedSetting -Entity $vmhost -Name "UserVars.SuppressHyperthreadWarning" | Set-AdvancedSetting -Value 1 -confirm:$false
    }

    #ExtremeIO only#
    Elseif ($storageType -eq "Extreme") {

        Get-VMHostFirewallException -host $vmhost|?{$_.Name -eq 'syslog'} | Set-VMHostFirewallException -Enabled:$true 
  
        Get-AdvancedSetting -Entity $vmhost -Name Syslog.global.logHost | set-advancedsetting -Value $sysloghostinfo -confirm:$false 
  
        Add-VMhostNTPServer -vmhost $vmhost -ntpserver $ntpserver -confirm:$false 
  
        Get-VmHostService -VMHost $vmhost | Where-Object {$_.key -eq "ntpd"}| set-vmhostservice -policy "On" 
  
        Get-VmHostService -VMHost $vmhost | Where-Object {$_.key -eq "ntpd"} | Start-VMHostService 
  
        Get-AdvancedSetting -Entity $vmhost -Name Mem.AllocGuestLargePage | set-advancedsetting -Value 0 -confirm:$false 
  
        Get-AdvancedSetting -Entity $vmhost -Name Mem.ShareForceSalting | set-advancedsetting -Value 0 -confirm:$false

        #ExtremeIO Specific Settings#

        Get-AdvancedSetting -Entity $vmhost -Name Disk.DiskMaxIOSize | Set-AdvancedSetting -value 4096 -Confirm:$false

        #This setting is only for clusters that have 10TB disks for OS/Data
		    Get-AdvancedSetting -Entity $vmhost -Name Disk.SchedQuantum | Set-AdvancedSetting -value 64 -Confirm:$false
		
	    	Get-AdvancedSetting -Entity $vmhost -Name "UserVars.SuppressHyperthreadWarning" | Set-AdvancedSetting -Value 1 -confirm:$false

    }

    #Hybrid (ExtremeIO, SVC, A9000r)#
    Elseif ($storageType -eq "HybridFull") {

        Get-VMHostFirewallException -host $vmhost|?{$_.Name -eq 'syslog'} | Set-VMHostFirewallException -Enabled:$true 
  
        Get-AdvancedSetting -Entity $vmhost -Name Syslog.global.logHost | set-advancedsetting -Value $sysloghostinfo -confirm:$false 
  
        Add-VMhostNTPServer -vmhost $vmhost -ntpserver $ntpserver -confirm:$false 
  
        Get-VmHostService -VMHost $vmhost | Where-Object {$_.key -eq "ntpd"}| set-vmhostservice -policy "On" 
  
        Get-VmHostService -VMHost $vmhost | Where-Object {$_.key -eq "ntpd"} | Start-VMHostService 
  
        Get-AdvancedSetting -Entity $vmhost -Name Mem.AllocGuestLargePage | set-advancedsetting -Value 0 -confirm:$false 
  
        Get-AdvancedSetting -Entity $vmhost -Name Mem.ShareForceSalting | set-advancedsetting -Value 0 -confirm:$false

        #HybridFull Specific Settings# 

        Get-AdvancedSetting -Entity $vmhost -Name Disk.DiskMaxIOSize | Set-AdvancedSetting -value 4096 -Confirm:$false

        Get-AdvancedSetting -Entity $vmhost -Name VMFS3.UseATSForHBOnVMFS5| set-advancedsetting -Value 0 -confirm:$false
        
        Get-AdvancedSetting -Entity $vmhost -Name DataMover.HardwareAcceleratedMove | Set-AdvancedSetting -Value 1 -Confirm:$false

        Get-AdvancedSetting -Entity $vmhost -Name DataMover.HardwareAcceleratedInit | Set-AdvancedSetting -value 1 -Confirm:$false

        Get-AdvancedSetting -Entity $vmhost -Name VMFS3.HardwareAcceleratedLocking | Set-AdvancedSetting -Value 1 -Confirm:$false

        Get-AdvancedSetting -Entity $vmhost -Name "UserVars.SuppressHyperthreadWarning" | Set-AdvancedSetting -Value 1 -confirm:$false
    }
  }
