param(
$infile,
$vcenter
)

# Example: .\set-tag.ps1 -vcenter vcenter1 -infile .\sandbox.csv

$csv = Import-Csv $infile
$creds = Get-Credential

connect-viserver $vcenter -credential $creds

foreach ($item in $csv)
{
$vm = get-vm -name $item.vm
$tag = $item.info
New-TagAssignment -Tag $tag -Entity $vm
}

<#
$csv| foreach {
$vm = $_.vm
$tag = $_.info
New-TagAssignment -Tag $tag -Entity $vm
}
#>