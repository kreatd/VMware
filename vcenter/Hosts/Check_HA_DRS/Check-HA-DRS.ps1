 <#
.DESCRIPTION
 Generates the vCenter HA & DRS Status Report
 
 $report=* code is credited towards LucD.
 
 
.PARAMETER <Parameter_Name>
	$vcenters, string array listing the names of all vCenters for the report to run against
 
   
.INPUTS
  takes in vCenters
 
.OUTPUTS
  Sends report via email
 
.NOTES
  Version:        1.0
  Author:         unknown
  Creation Date:  ?
  Purpose/Change: Initial script development
  Version:        2.0
  Author:         Daniel Kreatsoulas
  Creation Date:  12/8/2020
  Purpose/Change: changed the core code/added DRS Migration Threshold. 
.EXAMPLE
  .\Check-HA-DRS -vcenters "vcenter1,vcenter2"
#>
param(
	[string[]] $vcenters = @("vcenter1","vcenter2")
	)

$vcenters=Connect-VIServer $vcenters

$report=@()

$report=Get-Cluster -server $vcenters| Select Name,
  HAEnabled,
  @{N="HAFailoverLevel";E={
    if($_.HAEnabled){$_.HAFailoverlevel}else{"na"}}},
  HAIsolationResponse,
  DrsEnabled,
  DrsAutomationLevel,
  @{N="DRS Migration Threshold";E={
    if($_.DrsEnabled){
    $x = $_.Extensiondata.ConfigurationEx.DrsConfig.VmotionRate
    $t = @()
    $fa = @()
    $priorities = 1..(6 - $x) | %{
      $t += $_
      if($_ -eq (6 - $x)){
        if($fa.Count -eq 0){
          $f = "{0}"
        }
        else{
          $f = "$([string]::Join(', ',$fa)) and {$($_ -1)}"
        }
      }
      else{
        $fa += "{$($_ -1)}"
      }
    }
    $f -f $t}
    else{"na"}}}




$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"

$value1 = @{Expression='HAEnabled';Ascending=$true}
$value2 = @{Expression='Name';Ascending=$true}

$message = $report|sort-object $value1,$value2| ConvertTo-Html -Head $style

$colorTagTable = @{False = ' bgcolor="#ff0000">False<';
					True = ' bgcolor="#00ff00">True<'}
$colorTagTable.Keys | foreach { $message = $message -replace ">$_<",($colorTagTable.$_) }



Send-MailMessage -BodyAsHtml "$message " `
	-From "" `
	-To "" `
	-Smtpserver "" `
    -Subject "vCenter HA & DRS Status"

Disconnect-VIServer * -Confirm:$false -force
