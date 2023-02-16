param(
	$report_path="\\reports\vCenter Security Reports",
	[string[]] $vcenters = @("vcenter1","vcenter2","vcenter3","vcenter4", "vcenter5", "vcenter6", "vcenter7","vcenter8")
	)

$vcs = Connect-VIServer $vcenters
foreach ($vc in $vcs)
{
# Roles
	$roles = get-VIRole -server $vc|?{$_.IsSystem -eq $False}
	$RoleObjs = @()
	foreach ($role in $roles)
	{
		$roleobj = ""|select Name,Description,Server,Privileges
		$roleobj.Name = $role.name
		$roleobj.Server = $role.server.name
		$roleobj.Privileges = $role.privilegelist
		$roleobj.Description = $role.Description
		$RoleObjs += $roleobj
	}
	$datestamp=Get-Date -Format yyyy-MM-dd.HH.mm
	$RoleObjs |export-clixml "$report_path\$($vc.name)-Roles_$datestamp.xml"
		
# Permissions
	$perms = get-VIPermission -server $vc|select Entity, EntityID, IsGroup, Principal, Propagate, Role
	$datestamp=Get-Date -Format yyyy-MM-dd.HH.mm
	$perms|export-csv "$report_path\$($vc.name)-perms_$datestamp.csv" -force -NoTypeInformation
	$ADGroupMembers = $perms|?{$_.isgroup -eq $True}|%{$_.principal}|sort |Get-Unique |%{
		$perm = $_
		get-adgroupmember ($perm.split("\")[1])|select @{n="Group";e={$perm.split("\")[1]}},SamAccountName, name | `
		sort SamAccountName} 
	$ADGroupMembers | export-csv "$report_path\$($vc.name)-groupmembers_$datestamp.csv" -notypeinformation
}
disconnect-viserver * -confirm:$false -force