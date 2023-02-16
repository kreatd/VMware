param(
	[string[]] $vCenters = @("vcenter1","vcenter2"),
	[string] $location="."
	)

connect-viserver $vCenters


$output=@()
ForEach ($Datacenter in (Get-Datacenter | Sort-Object -Property Name)) {
  ForEach ($Cluster in ($Datacenter | Get-Cluster | where {$_.name -ne "C16" -and $_.name -ne "C07"}|Sort-Object -Property Name)) { 
    ForEach ($VM in ($Cluster | Get-VM | Sort-Object -Property Name)) {
      ForEach ($HardDisk in ($VM | Get-HardDisk -name "Hard disk 1" | Sort-Object -Property Name | where {$_.FileName.Split("]")[0].trimstart("[") -match "PREMIUM" -or $_.FileName.Split("]")[0].trimstart("[") -match "NONP" -and $_.CapacityGB -lt 200})) {
        $output+="" | Select-Object -Property @{N="VM";E={$HardDisk.FileName.Split("/")[0].split("] ")[2]}},
          @{N="Datacenter";E={$Datacenter.name}},
          @{N="Cluster";E={$Cluster.Name}},
          @{N="Hard Disk";E={$HardDisk.Name}},
          @{N="Capacity";E={$HardDisk.CapacityGB}},
          @{N="Datastore";E={$HardDisk.FileName.Split("]")[0].trimstart("[")}},
          @{N="VMDKpath";E={$HardDisk.FileName}}
      }
    }
  }
}       
$output = $output | sort-object -property Capacity -Descending
$htmloutput= $output | convertto-html -as table -fragment

Send-MailMessage -BodyAsHtml "$htmloutput" `
	-From "scriptinghost" `
	-To "teamemail" `
	-Smtpserver "smtpserver" `
    -Subject "OS Disks in Data Pools" 





disconnect-viserver * -force -confirm:$false