
$vms= get-vm | where { $_.GuestId -like "windows*"}
$output=@()
ForEach($vm in $vms) {
        $setting = Get-AdvancedSetting -Entity $vm -Name nge.enterprise

        if($setting){

            if($setting.Value -eq "XXXX"){
                
                Write-Output "$($vm.name)'s Setting $($_.Name) present and set correctly"
            }
            else{

                Write-Output "$($vm.name)'s Setting $($_.Name) present but not set correctly"
                $output+=[pscustomobject]@{
                    VM = $vm.name
                    Host = $vm.vmhost
                }
            }
        }
        else{
            Write-Output "$($vm.name)'s Setting $($_.Name) not present."
            $output+=[pscustomobject]@{
                VM = $vm.name
                Host = $vm.vmhost
            }
        }
    }

$output | export-csv temp.csv