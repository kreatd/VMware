 <#
.SYNOPSIS
  get vcenter's SSL certification expiration
 
.DESCRIPTION
  This report sends an email if our SSL certs are set to expire.  Report gets dumped to \\vCSA SSL Reports monthly.
 
.PARAMETER <Parameter_Name>
	$vcenters, string array listing the names of all vCenters for the report to run against
   $location, path to output report will be stored
   
.INPUTS
  takes in vCenters from the user
 
.OUTPUTS
  Sends email if necssary and
 
.NOTES
  Version:        1.0
  Author:         Daniel Kreatsoulas
  Creation Date:  1/1/2018
  Purpose/Change: Initial script development
  Version:        2.0
  Author:         Daniel Kreatsoulas
  Creation Date:  2/22/2019
  Purpose/Change: added parameters and added script 
.EXAMPLE
  .\get-vCenter-SSLCertReport.ps1 -location "\\vCSA SSL Reports" -vcenters "vcenter1"
#>
 param(
    [string[]] $vcenters,
    [string] $location = "."
	
    )

 $minimumCertAgeDays = 120
 $timeoutMilliseconds = 10000
 $urls = $vcenters.split(",")

#disabling the cert validation check. This is what makes this whole thing work with invalid certs...
 [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
foreach ($url in $urls)
 {
 #Write-Host Checking $url -f Green
 $req = [Net.HttpWebRequest]::Create("https://"+$url)
 $req.Timeout = $timeoutMilliseconds
try {$req.GetResponse() |Out-Null} catch {Write-Host Exception while checking URL $url`: $_ -f Red}
[datetime]$expiration = $req.ServicePoint.Certificate.GetExpirationDateString()
 [int]$certExpiresIn = ($expiration - $(get-date)).Days
$certName = $req.ServicePoint.Certificate.GetName()
 $certPublicKeyString = $req.ServicePoint.Certificate.GetPublicKeyString()
 $certSerialNumber = $req.ServicePoint.Certificate.GetSerialNumberString()
 $certThumbprint = $req.ServicePoint.Certificate.GetCertHashString()
 $certEffectiveDate = $req.ServicePoint.Certificate.GetEffectiveDateString()
 $certIssuer = $req.ServicePoint.Certificate.GetIssuerName()

if ($certExpiresIn -gt $minimumCertAgeDays)
 {
 
 $notexpired="Cert for site " + $url + " expires in " + $certExpiresIn + " days on " + $expiration +"`n"
 $notexpired| out-file -filepath "$location\vCenter-SSL-Report-$(get-date -f yyy.MM.dd).txt" -append -width 1000
 # $notexpired| out-file -filepath "vCenter-SSL-Report-$(get-date -f yyy.MM.dd).txt" -append -width 1000
 }
     else
 {
 
 $expired="Cert for site " + $url +" expires in " + $certExpiresIn + " days [on "+$expiration+"] Threshold is "+$minimumCertAgeDays+" days. Check details:`n`nCert name: "+$certName+"`nCert public key: "+$certPublicKeyString+"`nCert serial number: "+$certSerialNumber+"`nCert thumbprint: "+$certThumbprint+"`nCert effective date: "+$certEffectiveDate+"`nCert issuer: "+$certIssuer + "<br>"
 $expired| out-file -filepath "$location\vCenter-SSL-Report-$(get-date -f yyy.MM.dd).txt" -append -width 1000
 #$expired| out-file -filepath "vCenter-SSL-Report-$(get-date -f yyy.MM.dd).txt" -append -width 1000
 }
 
 $output+=$expired

 rv req
 rv expiration
 rv certExpiresIn
 }

 
if ($output)
{

Send-MailMessage -BodyAsHtml "$output " `
	-From "" `
	-To "" `
	-Smtpserver "" `
    -Subject ""
}

 $expired=""
 $notexpired=""
 $x=""
 $output=""