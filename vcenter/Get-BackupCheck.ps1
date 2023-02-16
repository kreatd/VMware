$backupdate=get-date -format 'yyyy.MM.dd'
$backupdate=(get-date).adddays(-1)
$backups=get-childitem "\\servername\e$\VCSA_Backups*" -recurse | where-object {$_.name -like "S_6.7*" -or $_.name -like "S_7*"} | sort-object creationtime | where-object {$_.creationtime -gt $backupdate} 
$folders=get-childitem "\\servername\e$\VCSA_Backups\*" -directory
$date=(get-date).adddays(-14)
$date=get-date $date -format 'yyyy.MM.dd'
$backupfolders=get-childitem "\\servername\e$\VCSA_Backups*" -recurse | where-object {$_.name -like "S_6.7*" -or $_.name -like "S_7*"}
$backupfolders|where{$_.creationtime -lt $date} | sort-object creationtime -Descending | remove-item -recurse -confirm:$false


$backups = $backups | select  @{Name = "VPSC/VCSA"; Expression = {$_.parent}},@{Name = "Last Write Time"; Expression = {$_.LastWriteTime}}
if($backups.count -ne ($folders.count-2))
{

$output ="A backup is missing!  Please review."

}
Send-MailMessage -BodyAsHtml -Body "<table><tr><td>$($backups | ConvertTo-Html)</tr><tr><h1>$output</h1></tr></td></table>" `
	-From "" `
	-To "" `
	-Smtpserver "" `
	-Subject "VPSC/VCSA Backups Check"