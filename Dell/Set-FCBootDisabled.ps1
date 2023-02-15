


param(
    $admin,
    [Parameter(Mandatory=$true)] [string] $path = $(Read-Host -prompt "Enter path of csv for input (C:\path\to\file.csv)")
	)

    $idracs = import-csv $path -header "name"
    $output=@()

foreach($idrac in $idracs)
{
$FC1Output=""
$FC2Output=""
$idracname=""
$FC1Output=racadm.exe -r $idrac.name -u USER -p $admin get FC.FCTarget.1.BootScanSelection 
$FC2Output=racadm.exe -r $idrac.name -u USER -p $admin get FC.FCTarget.2.BootScanSelection 
$idracname=$idrac.name
if ($FC1Output -like "*Disabled*") {
    
    
    #$output += "$idracname's FC1 setting is disabled"
    $output += New-Object PsObject -property @{
        'idrac' = $idracname
        'status' = "Disabled"
        }

}else{
    $output += New-Object PsObject -property @{
        'idrac' = $idracname
        'status' = "Not Disabled"
        }
    #$output += "$idracname's FC1 setting is not disabled"
    ##set setting and create job for next reboot
    ##set FC.FCTarget.2.BootScanSelection Disabled
    ##-u USER -p password jobqueue create FC.Slot.1-1 -r none
}

if ($FC2Output -like "*Disabled*") {
    
    $output += New-Object PsObject -property @{
        'idrac' = $idracname
        'status' = "Disabled"
        }

}else{
    $output += New-Object PsObject -property @{
        'idrac' = $idracname
        'status' = "Not Disabled"
        }
    ##set setting and create job for next reboot
}
}
$output | export-csv output.csv
$output
