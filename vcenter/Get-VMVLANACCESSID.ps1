
param(
    [string[]] $vcenter,
    [string[]] $dvs
    )

$output=@()

connect-viserver $vcenter -credential $usercreds

$macs=get-vdswitch -name $dvs -server $vcenter | get-vdport | where {$_.Portgroup -like "portgroup" -and $_.vlanconfiguration -like "VLAN 1" -and $_.ConnectedEntity -notlike "" -and $_.macaddress -notlike ""}

foreach($mac in $macs){
    $output+=get-vm -server $vcenter| Get-NetworkAdapter | Where {$_.MacAddress -eq $mac.macaddress} | select parent,name,networkname,macaddress
} 
    disconnect-viserver * -confirm:$false

$output | export-csv "$($vcenter).csv"
