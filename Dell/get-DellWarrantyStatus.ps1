<#
.SYNOPSIS
    This code is a function library to access Dell's website for retrieving warranty information.

.DESCRIPTION
    This code is meant to be called either via console or sourced from another piece of code as a library
    to look up Dell warranty information. Script is called by update-hostLeaseDates.

.PARAMETER ServiceTag
    The ServiceTag parameter accepts invividual Dell server tags or multiple separated by commas

.PARAMETER Apikey
    The ApiKey is provided by Dell and must be passed as a form of authentication to Dell warranty API

.INPUTS
  <Inputs if any, otherwise state None>

.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>

.NOTES
  Version:        1.0
  Author:         David Burton
  Creation Date:  2018.11.09
  Purpose/Change: Initial script development
  Version:        2.0
  Author:         Daniel Kreatsoulas
  Creation Date:  1/22/2020
  Purpose/Change: Complete rewrite for new Dell API v5

.EXAMPLE
    get-DellWarantyStatus -ServiceTag <tag>,<tag>,...<tag> -Apikey <apikey> -Client_Secret <client-secret>   
#>

Function Invoke-DellAPILookup
{
    param([string[]] $ServiceTags)
    $headers = @{
        Accept = "application/json"
        Authorization = "Bearer $script:token"
    }
    
    $params = @{ servicetags = $ServiceTags -join ','}
    $result = Invoke-RestMethod -Uri $DellAPIURL -Headers $headers -Body $params -Method Get -ContentType "application/json"

    $script:result = $result
    #write-output $result
}


function get-EndDate
{
$output = @()
#for($i=0;$i -lt $ServiceTag.count;$i++)
#{

Invoke-DellAPILookup($ServiceTag)
#$result.entitlements[1].EndDate
    foreach ($warranty in $result)
    {
        $output +=$warranty|select-object @{n="ServiceTag";e={$_.ServiceTag}},
        @{n="EndDate";e={$_.entitlements.EndDate}}
        #@{n="ProSupport Plus";e={$_.entitlements.itemNumber}}
        #$output += $warranty|select-object @{n="ServiceTag";e={$_.ServiceTag}},
        #    @{n="EndDate";e={$_.EndDate}},
        #    @{n="SLA";e={$_.ServiceLevelDescription}}
    }
#}
# Read first entry if available
write-output $output
}
function get-DellWarrantyStatus{
Param(
[Parameter(Mandatory=$true)]
$ServiceTag,
[Parameter(Mandatory=$true)]
[String]$ApiKey,
[Parameter(Mandatory=$true)]
[String]$Client_Secret
#[String]$ServiceTagString = $ServiceTag[($i*80)..($i*80+79)] -join (",")
)
write-output $ServiceTag
$script:DellAPIURL = "https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/asset-entitlements"
$output = @()
$AuthURI      = "https://apigtwb2c.us.dell.com/auth/oauth/v2/token"
$OAuth        = "$Apikey`:$Client_Secret"
$Bytes        = [System.Text.Encoding]::ASCII.GetBytes($OAuth)
$EncodedOAuth = [Convert]::ToBase64String($Bytes)

$Headers = @{ }
$Headers.Add("authorization", "Basic $EncodedOAuth")
$Authbody = 'grant_type=client_credentials'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Try {
    $AuthResult = Invoke-RESTMethod -Method Post -Uri $AuthURI -Body $AuthBody -Headers $Headers
    $script:token = $AuthResult.access_token
}
Catch {
    $ErrorMessage = $Error[0]
    Write-Error $ErrorMessage
    BREAK        
}
Write-Verbose "Access Token is: $script:token"
get-EndDate($ServiceTag)
}