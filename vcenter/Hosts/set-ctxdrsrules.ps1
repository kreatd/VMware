param(
	$vcenters = @("vcenter1","vcenter2"),
	$location="."
)
$vcs=connect-viserver $vcenters
$clusters=get-cluster *citrixclustername
$log=@()
foreach ($cluster in $clusters)
{
	$rules=get-drsrule -cluster $cluster
	$rulenames=$rules|%{$_.name}
    #Added -and $_.name -notlike "nameofservertypex*" on 10/31/18 - Dan
	#added -and $_.name -notlike "nameofservertypey*" on 05/16/19 - Dan
	$vms=$cluster|get-vm|?{$_.name -like "C*" -and $_.name -notlike "nameofservertypex*" -and $_.name -notlike "nameofserverypey*"}|sort name
	$numhosts=$cluster.ExtensionData.host.count
	$rulesize=[int]($numhosts-$numhosts/4)
	$prefixes=$vms|%{$_.name.substring(0,6).tolower()}|get-unique
	foreach ($prefix in $prefixes)
	{	
		if ($rulenames -contains $prefix)
		{
			$rule=$rules|?{$_.name -match $prefix}
			$numVMsinRule=($rule|%{$_.vmids.count}|Measure-Object -sum).sum
			if(($vms|?{$_.name -match "$prefix"}).count -gt $numVMsinRule)
			{
				$rule|remove-drsrule -confirm:$false
				if (($vms|?{$_.name -match "$prefix"}).count -gt $rulesize)
				{
					$log+=new-drsrule -name $prefix -cluster $cluster -enabled $true -keeptogether $false -VM ($vms|?{$_.name -match "$prefix"}|select -first $rulesize)
					$i=1
					while (($vms|?{$_.name -match "$prefix"}|select -skip ($i*$rulesize)) -ne $NULL)
					{
						$log+=new-drsrule -name "$prefix$i" -cluster $cluster -enabled $true -keeptogether $false -VM ($vms|?{$_.name -match "$prefix"}|select -skip ($i*$rulesize) -first $rulesize)
						$i++
					}
				}
				else{$log+=new-drsrule -name $prefix -cluster $cluster -enabled $true -keeptogether $false -VM ($vms|?{$_.name -match "$prefix"}|select -first $rulesize)}
			}
		}
		elseif (($vms|?{$_.name -match "$prefix"}).count -gt 1) 
		{
			if (($vms|?{$_.name -match "$prefix"}).count -gt $rulesize)
			{
				$log+=new-drsrule -name $prefix -cluster $cluster -enabled $true -keeptogether $false -VM ($vms|?{$_.name -match "$prefix"}|select -first $rulesize)
				$i=1
				while (($vms|?{$_.name -match "$prefix"}|select -skip ($i*$rulesize)).count -gt 1)
				{
					$log+=new-drsrule -name "$prefix$i" -cluster $cluster -enabled $true -keeptogether $false -VM ($vms|?{$_.name -match "$prefix"}|select -skip ($i*$rulesize) -first $rulesize)
					$i++
				}
			}
			else{$log+=new-drsrule -name $prefix -cluster $cluster -enabled $true -keeptogether $false -VM ($vms|?{$_.name -match "$prefix"}|select -first $rulesize)}
		}
	}
}
$date=get-date -Format yyyy.MM.dd
If($log -ne $null){$log|export-csv "$location\set-ctxdrsrules_$date.csv" -notypeinformation}

disconnect-viserver * -confirm:$false -force
