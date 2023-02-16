#Get-VMs based off SQL-VMs DRS Group in all production vCenters
param(
	[string[]] $vCenters = @("vcenter1","vcenter2","vcenter3")
	)

function ErrorHandler($error) 
{
   Send-MailMessage -BodyAsHtml "$error" `
	-From "" `
	-To "" `
	-Smtpserver "" `
    -Subject "SQL VM Report Failure"
}



trap { ErrorHandler $_; break }

connect-viserver $vCenters

$SQLMembers=Get-DrsClusterGroup -name "SQL-VMs" | select member

$VMs=$SQLMembers.Member | select name,vmhost | sort -property vmhost

$VMs|export-csv -notypeinformation "\\dump\location\SQL-VMs-$(get-date -f yyy.MM.dd).csv"

if($error)
{
ErrorHandler($error)
}