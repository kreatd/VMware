 <#
.DESCRIPTION
 Generates a list of SQL/Oracle Host Groups and lists the number of hosts per group along with their hostnames

 An email will be submitted if the group/numbers change based off the input CSV that we maintain in github.
 
   
.INPUTS
  takes in input csv and compares it with our production vcenters
 
.OUTPUTS
  Sends report via email if anything is different from the CSV
 
.NOTES
  Version:        1.0
  Author:         Daniel Kreatsoulas
  Creation Date:  12/9/2020
  Purpose/Change: Initial script development

.EXAMPLE
  .\Get-VMHostGroupReport.ps1
#>
param(
    [array] $vcenters,
    [Parameter(Mandatory=$true)]$path
    )

connect-viserver $vcenters
$csvgroup=import-csv $path
$prodgroup=get-cluster -server $vcenters| get-drsclustergroup |where {$_.grouptype -eq "VMHostGroup" -and $_.cluster -notlike "*C14*"} | select name, cluster, member, uid | sort-object -property uid


#check if host group count has changed
if($prodgroup.count -eq $csvgroup.count){
  $prodgroup.count
  $csvgroup.count

}else{

Compare-Object -ReferenceObject $csvgroup.name -DifferenceObject $prodgroup.name | 
    Where-Object { $_.SideIndicator -eq '=>' } | 
    ForEach-Object  { $x+=$_.InputObject+","}
    $new=$x.Trim(","," ")
    $groupname=$new.split(",")
$output+= "Host group count has changed, please review or update host group csv file.  $($groupname) is missing. `n"
}
########

if(!$output){
$i=0;
$output=@()
while($i -lt $prodgroup.count){
if($prodgroup[$i].name -eq $csvgroup[$i].name)
{
  write-output "group name matches"

}else{

  $output+= "<br><b> $($prodgroup[$i].cluster)'s $($prodgroup[$i].name) host group name has a mismatch. </b><br> "
  $output+= "Before"
  $output+=$csvgroup[$i].name
  $output+= "After"
  $output+=$prodgroup[$i].name -join (",")
  
}
$i++;
}


#######

$i=0;
while($i -lt $prodgroup.count){
if($prodgroup[$i].member.name -join (",") -eq $csvgroup[$i].member)
{
  #$output+="group count is good"
  write-output "group count is good"

}else{

  $output+= "<br><b> $($prodgroup[$i].cluster)'s $($prodgroup[$i].name) host group has changed. </b><br>"
  $output+= "Before <br>"
  $output+= $csvgroup[$i].member
  $output+=  "<br>After<br>"
  $output+= $prodgroup[$i].member.name -join (",")
  
}
$i++;
}
}
$output

if($output){
Send-MailMessage -BodyAsHtml "$output " `
	-From "" `
	-To "" `
	-Smtpserver "" `
    -Subject "SQL/Oracle Host Group Report"
}

Disconnect-VIServer * -Confirm:$false -force