param([string] $location=".")
$vcenter_names="vcenter-1"
$vcenters=Connect-VIServer $vcenter_names

$datestamp=Get-Date -Format yyyy.MM.dd.HH.mm

$rows=@()
foreach ($vcenter in $vcenters)
{
	$netviews = get-view -viewtype Network -server $vcenter
	get-view -server $vcenter -ViewType VirtualMachine -Property Name, config| %{    
		#Get Meta Data
		$vmview = $_
		$row = "" | select Name, Portgroup, MetaData
		$Metadata = $vmview.config.extraconfig|?{$_.key -like "nge*"}
		if ($nuageMetadata)
		{
			$metaData = [system.String]::Join(";",($nuageMetadata|%{"$($_.key)::$($_.value)"}))
			$row.metadata = $metadata
		}
		#get VM name time
		$name = $vmview.name
		$nics = $vmview.Config.Hardware.Device | Where {$_ -is [VMware.Vim.VirtualEthernetCard]}
		if($nics){$row.portgroup = [system.String]::Join(";",(($nics|%{$nic=$_;"$($nic.DeviceInfo.Label)" + "=" + "$(($netviews|?{$_.key -eq $nic.Backing.port.PortgroupKey}).name)"})))}
		$row.Name = $name
		$rows+=$row
	}
}
	
$a = "<style>"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;text-align: center}"
$a = $a + "TH{border-width: 1px;padding: 5px;border-style: solid;border-color: black;}"
$a = $a + "TD{border-width: 1px;padding: 5px;border-style: solid;border-color: black;}"
$a = $a + "</style>"

write-output $rows|Sort-Object Name|ConvertTo-Html -Head $a -Body "<H2> Meta Data as of: $(get-date) </H2>"|out-file "$location\metaData.$datestamp.html"
write-output $rows|Sort-Object Name|export-csv -notypeinformation NuageMetadata.csv
Disconnect-VIServer * -Confirm:$false -force