param(
    [string[]] $vcenters=@("vcenter1")
    )

Add-PSSnapin vmware.*

Connect-VIServer $vcenters
$views = get-vmhost|Get-View -Property Name,Config.StorageDevice
$result = @()

foreach ($view in $views | Sort-Object -Property Name) {
    #Write-Host "Checking" $view.Name
 
    $view.Config.StorageDevice.ScsiTopology.Adapter |?{ $_.Adapter -like "*FibreChannelHba*" } | %{
        $hba = $_.Adapter.Split("-")[2]
        $active = 0
        $standby = 0
        $dead = 0
        
		[array] $multipathInfo = $view.Config.StorageDevice.MultipathInfo.Lun 
		foreach ($disk in $multipathInfo){
            $a = [ARRAY]($disk.Path | ?{ ($_.PathState -like "active") -and ($_.adapter -like "*$hba") })
            $s = [ARRAY]($disk.Path | ?{ ($_.PathState -like "standby") -and ($_.adapter -like "*$hba") })
            $d = [ARRAY]($disk.Path | ?{ ($_.PathState -like "dead") -and ($_.adapter -like "*$hba") })
            $active += $a.Count
            $standby += $s.Count
            $dead += $d.Count
            }
        	$result += "{0},{1},{2},{3},{4}" -f $view.Name.Split(".")[0], $hba, $active, $dead, $standby
		}
	write-host 	$result[-1]
}
$datestamp=Get-Date -Format yyyy.MM.dd.HH.mm

ConvertFrom-Csv -Header "VMHost", "HBA", "Active", "Dead", "Standby" -InputObject $result | export-csv "esx_hostpaths_$datestamp.csv" -NoTypeInformation
disconnect-viserver * -confirm:$false -force
