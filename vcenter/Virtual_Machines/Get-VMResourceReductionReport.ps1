

$rightSizeReportList = get-childitem "\\RightSize_Reports\*"
$rightSizeReport = $rightSizeReportList | sort-object creationtime | select-object -first 1
$ImportedVMs = import-csv $rightSizeReport

$i=0;
foreach($vm in $ImportedVMs)
{
    $ImportedVMs[$i]."CPU Reclaimable" = [Math]::Truncate($ImportedVMs[$i]."CPU Reclaimable")
    $ImportedVMs[$i]."Memory Reclaimable" = [Math]::Truncate($ImportedVMs[$i]."Memory Reclaimable")
    $i++;
}
#Include exclusions maintained by teams x y and z
$ExcludedVMs = get-content "\\exclusions.txt"

$VmsToReduce = $ImportedVMs | where {$ExcludedVMs -notcontains $_.name}

#<90dayinventory
$date=(get-date).adddays(-90)
$date=get-date $date -format 'yyyy.MM.dd'
$vmDetailsReportList=get-childitem "\\VMware_vmdet*"
$vmDetailsReport=$vmDetailsReportList|where{$_.creationtime -lt $date} | sort-object creationtime -Descending |select-object -first 1
$90dayinventory = import-csv $vmDetailsReport|foreach-object{$_.vmname}|sort-object
$VmsToReduce = $VmsToReduce | where {$90dayinventory -contains $_.name}
#####
#remove 2cpu 4gb ram VMs  (-le 2 / 4 doesn't work so I had to create the horrible filter you see below.)
$removeMinSpeccedVMs = $VmsToReduce| where {(($_."CPU Provisioned" -eq 2 -and $_."Memory Provisioned" -eq 4) -or ($_."CPU Provisioned" -eq 2 -and $_."Memory Provisioned" -eq 3) -or ($_."CPU Provisioned" -eq 2 -and $_."Memory Provisioned" -eq 2) -or ($_."CPU Provisioned" -eq 1 -and $_."Memory Provisioned" -eq 4) -or ($_."CPU Provisioned" -eq 1 -and $_."Memory Provisioned" -eq 3))}
#$removeMinSpeccedVMs = $VmsToReduce| where {($_."CPU Provisioned" -eq 2 -and $_."Memory Provisioned" -eq 4)}
#$selectedVMs = $VmsToReduce | where { -contains $_}
$selectedVMs = $VmsToReduce| where {$removeMinSpeccedVMs -notcontains $_}
#export "before" report to resource_reduction folder for OS teams.
$selectedVMs | export-csv "\\VM-Resource-Reduction-Before-$(get-date -f yyy.MM.dd).csv"
