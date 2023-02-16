param(
	[string[]] $vCenters = @("vcenter1","vcenter2","vcenter3"),
	[string] $location="."
	)

connect-viserver $vCenters

$output=@()
ForEach ($Datacenter in (Get-Datacenter -Server $vcenters| Sort-Object -Property Name)) {
  ForEach ($Cluster in ($Datacenter | Get-Cluster -name "*clustertype1","*clustertype2","*clustertype3"| Sort-Object -Property Name)) {
    ForEach ($VM in ($Cluster | Get-VM | Sort-Object -Property Name)) {
      ForEach ($HardDisk in ($VM | Get-HardDisk | Sort-Object -Property Name | where {$_.StorageFormat -eq "Thin"})) {
        $output+="" | Select-Object -Property @{N="VM";E={$HardDisk.FileName.Split("/")[0].split("] ")[1]}},
          @{N="Datacenter";E={$Datacenter.name}},
          @{N="Cluster";E={$Cluster.Name}},
          @{N="Hard Disk";E={$HardDisk.Name}},
          @{N="Capacity";E={$HardDisk.CapacityGB}},
          @{N="Datastore";E={$HardDisk.FileName.Split("]")[0].trimstart("[")}},
          @{N="Storage Format";E={$HardDisk.StorageFormat}},
          @{N="VMDKpath";E={$HardDisk.FileName}}
      }
    }
  }
}
$output = $output | sort-object -property Capacity -Descending
$htmloutput= $output | convertto-html -as table -fragment

if($output){
Send-MailMessage -BodyAsHtml "$htmloutput" `
	-From "scriptinghost" `
	-To "teamemail" `
	-Smtpserver "smtpserver" `
    -Subject "Thin Provisioned VMDKs in General Clusters" 
}else{
Send-MailMessage -BodyAsHtml "No thin provisioned disks in the environment" `
	-From "scriptinghost" `
	-To "teamemail" `
	-Smtpserver "smtpserver" `
    -Subject "No Thin Provisioned VMDKs" 

}


disconnect-viserver * -force -confirm:$false
