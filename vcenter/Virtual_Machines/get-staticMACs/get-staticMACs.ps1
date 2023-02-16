param(
	[string[]] $vCenters = @("vcenter1"),
	[string] $location="."
	)
$output=@()
$vcs=connect-viserver $vCenters
foreach ($vc in $vcs)
{
	write-host "Getting MACs for $($vc.name)..."
	$vms = get-vm -server $vc|sort name
	$output+=$vms|sort name|?{$_|get-networkadapter|%{if($_.extensiondata.addresstype -eq "manual"){$vmnic=$_;$_}}}|select @{n="vCenter";e={($vc.name)}}, name, powerstate, `
		@{n="MAC";e={$vmnic.extensiondata.Macaddress}}, `
		@{n="VMNIC";e={$vmnic.name}}, `
		@{n="PortGroup";e={$vmnic.NetworkName}}, `
		@{n="Type";e={$vmnic.type}}
	
#	$output|export-csv -notypeinformation "$location\VMware_Static_MACs.csv"
}
$a = "<style>"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;text-align: center}"
$a = $a + "TH{border-width: 1px;padding: 5px;border-style: solid;border-color: black;}"
$a = $a + "TD{border-width: 1px;padding: 5px;border-style: solid;border-color: black;}"
$a = $a + "</style>"

write-output $output|sort MAC|ConvertTo-Html -Head $a -Body "<H2> Static MAC Addresses, range: 00:50:56:00-3F:YY:ZZ</H2>" |out-file "$location\VMware_Static_MACs.html"
disconnect-viserver * -confirm:$false -force