#
#Quick script written by Dan Kreatsoulas - 4/25/19
#Example
#./Reset-VasaProviders.ps1 -vcenters vcenter1 -clusters C15,C01
#Keep in mind that you still have to reset the triggered alarms in vCenter back to GREEN and you have to resynchronize the providers by navigating to`
#vcenter -> storage providers -> synchronize storage providers

param(
	[array] $vcenters,
    [array] $clusters
	)
    connect-viserver $vcenters
$hosts = get-cluster $clusters | get-vmhost

foreach($vasahost in $hosts)
    { 
    Remove-VasaProvider -Provider "IOFILTER Provider $($vasahost.name)" -Confirm:$False
    }

    disconnect-viserver $vcenters -Confirm:$False