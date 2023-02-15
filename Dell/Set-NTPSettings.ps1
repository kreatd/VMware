param(
    $admin,
    [Parameter(Mandatory=$true)] [string] $path = $(Read-Host -prompt "Enter path of csv for input (C:\path\to\file.csv)"),
    $dnsip
	)

    $idracs = import-csv $path -header "name"

foreach($idrac in $idracs)
{

racadm -r $idrac.name -u ADMIN -p $admin set idrac.NTPConfigGroup.ntp1 $dnsip
racadm -r $idrac.name -u ADMIN -p $admin set idrac.NTPConfigGroup.NTPEnable Enabled
racadm -r $idrac.name -u ADMIN -p $admin set idrac.time.timezone US/Eastern

}