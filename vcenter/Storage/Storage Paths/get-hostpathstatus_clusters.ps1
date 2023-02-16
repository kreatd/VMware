param(
    $cluster = @("C10","C27"),
	$vCenter = @("vcenter2")
)

Add-PSSnapin vmware.*
$vCenters = Connect-VIServer $vcenter

if ($cluster)
{
    $HostObjects = get-cluster -server $vcenters -name $cluster|get-vmhost
}
else
{
    $hostObjects = get-vmhost -server $vcenters
}
$views = $HostObjects|Get-View -Property Name,Config.StorageDevice
$result = @()

foreach ($view in $views | Sort-Object -Property Name) {
    #Write-Host "Checking" $view.Name
 
    $view.Config.StorageDevice.ScsiTopology.Adapter |?{ $_.Adapter -like "*FibreChannelHba*" } | %{
        $line = ""|select VMHost, HBA, Active, Standby, Dead
	$line.hba = $_.Adapter.Split("-")[2]
        $line.active = 0
        $line.standby = 0
        $line.dead = 0
        $line.vmhost = $view.Name.Split(".")[0]
		[array] $multipathInfo = $view.Config.StorageDevice.MultipathInfo.Lun 
		foreach ($disk in $multipathInfo){
            $a = [ARRAY]($disk.Path | ?{ ($_.PathState -like "active") -and ($_.adapter -like "*$($line.hba)") })
            $s = [ARRAY]($disk.Path | ?{ ($_.PathState -like "standby") -and ($_.adapter -like "*$($line.hba)") })
            $d = [ARRAY]($disk.Path | ?{ ($_.PathState -like "dead") -and ($_.adapter -like "*$($line.hba)") })
            $line.active += $a.Count
            $line.standby += $s.Count
            $line.dead += $d.Count
            }
        $result += $line
	}
	
	write-host $result[-2]
	write-host $result[-1]
}
$datestamp=Get-Date -Format yyyy.MM.dd.HH.mm
write-host "Sum of Paths: Active:$(($result|measure-object -property Active -sum).sum), Standby:$(($result|measure-object -property Standby -sum).sum), Dead:$(($result|measure-object -property Dead -sum).sum)"
$result | export-csv "esx_hostpaths_cluster$datestamp.csv" -NoTypeInformation
disconnect-viserver * -confirm:$false -force
