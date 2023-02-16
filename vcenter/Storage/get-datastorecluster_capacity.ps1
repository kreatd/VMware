Connect-VIServer vcenter2

$report = foreach ($vc in $global:DefaultVIServers) {
   Get-DatastoreCluster -Server $vc |
   where {$_.CapacityGB -ne 0 -and ($_.FreeSpaceGB / $_.CapacityGB) -gt 0.3} |
   
  Select @{N = 'vCenter'; E = {$vc.Name}},
   @{N = 'Datacenter'; E = {(Get-Datastore -RelatedObject $_ | select -First 1).Datacenter.Name}},
   @{N = 'DSC'; E = {$_.Name}},
   @{N = 'CapacityTB'; E = {[math]::Round($_.CapacityGB / 1KB, 2)}},
   @{N = 'FreespaceTB'; E = {[math]::Round($_.FreespaceGB / 1KB, 2)}},
   @{N = 'Freespace%'; E = {[math]::Round($_.FreespaceGB / $_.CapacityGB * 100, 1)}},
   @{N = 'ProvisionedSpaceTB'; E = {
   [math]::Round(($_.ExtensionData.Summary.Capacity - $_.Extensiondata.Summary.FreeSpace + $_.ExtensionData.Summary.Uncommitted) / 1TB, 2)}
   }
}

$report | Export-Csv DSC_2_Capacity.csv -NoTypeInformation -UseCulture

Disconnect-VIServer vcenter-shy -Confirm:$false