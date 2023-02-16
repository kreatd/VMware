<#
.SYNOPSIS

 
.DESCRIPTION


.INPUTS

 
.OUTPUTS

 
.NOTES
  Version:        1.0
  Author:         Daniel Kreatsoulas
  Creation Date:  11/12/2020
  Purpose/Change: Initial script development
.EXAMPLE
  .\get-SSLCerts.ps1

    

#>
param(
    [string[]] $vcenters=@("vcenter1","vcenter2"),
    [string] $location = "."
    )
Import-Module Posh-SSH

$Secure = Get-Content "creds.txt" | ConvertTo-SecureString
#write-output "Enter in vcsa root password."
#$Secure = Read-Host -AsSecureString

$cred = New-Object System.Management.Automation.PSCredential("root",$secure)
$emailoutput=@()

$date = (get-date).year
$date=$date.toString()
$date = $date + " GMT"


foreach ($vc in $vcenters) {
    write-output "Connecting to $vc"


$ssh = New-SSHSession -ComputerName $vc -Credential $cred -AcceptKey -KeepAliveInterval 5
write-output "Executing Command on $vc"
$output=@()
$outputObject=@()


$output+=Invoke-SSHCommand -SessionId $ssh.SessionId -Command "/usr/lib/vmware-vmafd/bin/vecs-cli entry list --store TRUSTED_ROOTS --text" -TimeOut 30 | select -ExpandProperty Output

$output+=Invoke-SSHCommand -SessionId $ssh.SessionId -Command "/usr/lib/vmware-vmafd/bin/vecs-cli entry list --store MACHINE_SSL_CERT --text" -TimeOut 30 | select -ExpandProperty Output

$output+=Invoke-SSHCommand -SessionId $ssh.SessionId -Command "/usr/lib/vmware-vmafd/bin/vecs-cli entry list --store machine --text" -TimeOut 30 | select -ExpandProperty Output

$output+=Invoke-SSHCommand -SessionId $ssh.SessionId -Command "/usr/lib/vmware-vmafd/bin/vecs-cli entry list --store vpxd --text" -TimeOut 30 | select -ExpandProperty Output

$output+=Invoke-SSHCommand -SessionId $ssh.SessionId -Command "/usr/lib/vmware-vmafd/bin/vecs-cli entry list --store vpxd-extension --text" -TimeOut 30 | select -ExpandProperty Output

$output+=Invoke-SSHCommand -SessionId $ssh.SessionId -Command "/usr/lib/vmware-vmafd/bin/vecs-cli entry list --store vsphere-webclient --text" -TimeOut 30 | select -ExpandProperty Output

$output+=Invoke-SSHCommand -SessionId $ssh.SessionId -Command "/usr/lib/vmware-vmafd/bin/vecs-cli entry list --store SMS --text" -TimeOut 30 | select -ExpandProperty Output

$output+=Invoke-SSHCommand -SessionId $ssh.SessionId -Command "/usr/lib/vmware-vmafd/bin/vecs-cli entry list --store TRUSTED_ROOT_CRLS --text" -TimeOut 30 | select -ExpandProperty Output
$outputObject =$output| where {$_ -match "Not After" -or $_ -match "Alias"}
write-output "Ending SSH Session on $vc"
Remove-SSHSession -SessionId $ssh.SessionId | Out-Null

$newoutputobject=$outputobject -match $date
$newoutputobject=$newoutputobject|select -first 1
if($newoutputobject){
$newoutputobject=$newoutputobject -replace "            "
$newoutputobject=$newoutputobject -replace "Not After : "
$newoutputobject=$newoutputobject -replace " GMT"
$dateout=[datetime]::parseexact($newoutputobject, "MMM d HH:mm:ss yyyy", $null)
}


if($dateout -and (get-date).addmonths(6) -gt $dateout){
  $expired="Expiring cert for site " + $vc+"`n"
  $expired| out-file -filepath "$location\vCenter-SSL-Report-new-$(get-date -f yyy.MM.dd).txt" -append -width 1000
  $outputObject| out-file -filepath "$location\vCenter-SSL-Report-new-$(get-date -f yyy.MM.dd).txt" -append -width 1000
  $emailoutput+= "Expiring cert for site " + $($vc) +"<br>"
  $dateout=$null
}else{
  $notexpired="Cert for site " + $vc+"`n"
  $notexpired| out-file -filepath "$location\vCenter-SSL-Report-new-$(get-date -f yyy.MM.dd).txt" -append -width 1000
  $outputObject| out-file -filepath "$location\vCenter-SSL-Report-new-$(get-date -f yyy.MM.dd).txt" -append -width 1000
}




} 

if($emailoutput){

Send-MailMessage -BodyAsHtml "$emailoutput <br> check the following report:$location\vCenter-SSL-Report-new-$(get-date -f yyy.MM.dd).txt" `
	-From "" `
	-To "" `
	-Smtpserver "" `
    -Subject "[Alert] vCenter SSL Cert Expiring Soon"
}else{
  
Send-MailMessage -BodyAsHtml "no output" `
-From "" `
-To "" `
-Smtpserver "" `
  -Subject "vCenter SSL Certs are GREEN"
}
