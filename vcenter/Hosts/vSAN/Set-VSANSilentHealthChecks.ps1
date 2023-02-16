#Set-VSANSilentHealthChecks Disables the 3 checks that we don't need
#Set-VSANSilentHealthChecks -Cluster C20 vumconfig,vsancloudhealthceipexception,hcldbuptodate -Disable

Function Set-VSANSilentHealthChecks {
    param(
        [Parameter(Mandatory=$true)][String]$Cluster,
        [Parameter(Mandatory=$true)][String[]]$Test,
        [Switch]$Enabled,
        [Switch]$Disabled
    )
    $vchs = Get-VSANView -Id "VsanVcClusterHealthSystem-vsan-cluster-health-system"
    $cluster_view = (Get-Cluster -Name $Cluster).ExtensionData.MoRef

    if($Enabled) {
        $vchs.VsanHealthSetVsanClusterSilentChecks($cluster_view,$null,$Test)
    } else {
        $vchs.VsanHealthSetVsanClusterSilentChecks($cluster_view,$Test,$null)
    }
}

#This function is great for generating the list of all the vsanhealthchecks
Function Get-VSANHealthChecks {
        $vchs = Get-VSANView -Id "VsanVcClusterHealthSystem-vsan-cluster-health-system"
        $vchs.VsanQueryAllSupportedHealthChecks() | Select TestId, TestName | Sort-Object -Property TestId
    }
