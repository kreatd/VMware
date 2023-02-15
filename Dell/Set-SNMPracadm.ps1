#How to run
#If you're working with an iDRAC9 or greater:
#./Set-SNMPracadm.ps1 useraccountofiDRAC passwordofiDRAC \\path\to\file.csv

#If you're working with an iDRAC8 or less remove the comments on the iDRAC8 racadm commands and comment out the Set-IdracLcSystemAttributesREDFISH line.
#I should look towards creating a check for iDrac8 or 9+ to make execution of this script a bit more straightfoward.

#Be sure to run this from the same location as your local install of racadm or else it won't run correctly.
#created by Dell - modified heavily by Daniel Kreatsoulas on 1/25/2019


param(
    [Parameter(Mandatory=$true)] [string] $idrac_user = $(Read-Host -prompt "User account is needed"),
    [Parameter(Mandatory=$true)] [string] $pass = $(Read-Host -prompt "password is needed"),
    [Parameter(Mandatory=$true)] [string] $path = $(Read-Host -prompt "path to your input.csv file is needed, be sure to list the filename")
    )

function Set-IdracLcSystemAttributesREDFISH {


param(
    [Parameter(Mandatory=$True)]
    [string]$idrac_ip,
    [Parameter(Mandatory=$True)]
    [string]$idrac_username,
    [Parameter(Mandatory=$True)]
    [string]$idrac_password,
    [Parameter(Mandatory=$True)]
    [string]$attribute_group,
    [Parameter(Mandatory=$False)]
					   
								 
    [string]$view_attribute_list_only

    )

# Function to ignore SSL certs

function Ignore-SSLCertificates
{
    $Provider = New-Object Microsoft.CSharp.CSharpCodeProvider
    $Compiler = $Provider.CreateCompiler()
    $Params = New-Object System.CodeDom.Compiler.CompilerParameters
    $Params.GenerateExecutable = $false
    $Params.GenerateInMemory = $true
    $Params.IncludeDebugInformation = $false
    $Params.ReferencedAssemblies.Add("System.DLL") > $null
    $TASource=@'
        namespace Local.ToolkitExtensions.Net.CertificatePolicy
        {
            public class TrustAll : System.Net.ICertificatePolicy
            {
                public bool CheckValidationResult(System.Net.ServicePoint sp,System.Security.Cryptography.X509Certificates.X509Certificate cert, System.Net.WebRequest req, int problem)
                {
                    return true;
                }
            }
        }
'@ 
    $TAResults=$Provider.CompileAssemblyFromSource($Params,$TASource)
    $TAAssembly=$TAResults.CompiledAssembly
    $TrustAll = $TAAssembly.CreateInstance("Local.ToolkitExtensions.Net.CertificatePolicy.TrustAll")
    [System.Net.ServicePointManager]::CertificatePolicy = $TrustAll
}



# Function to get Powershell version

$global:get_powershell_version = $null

function get_powershell_version 
{
$get_host_info = Get-Host
$major_number = $get_host_info.Version.Major
$global:get_powershell_version = $major_number
}

get_powershell_version									  
# Setting up iDRAC credentials 

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12
$user = $idrac_username
$pass= $idrac_password
$secpasswd = ConvertTo-SecureString $pass -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($user, $secpasswd)

# GET command to get all attributes and current values

if ($attribute_group -eq "idrac")
{
$uri = "https://$idrac_ip/redfish/v1/Managers/iDRAC.Embedded.1/Attributes"
}
<#elseif ($attribute_group -eq "lc")
{
$uri = "https://$idrac_ip/redfish/v1/Managers/LifecycleController.Embedded.1/Attributes"
}
elseif ($attribute_group -eq "system")
{
$uri = "https://$idrac_ip/redfish/v1/Managers/System.Embedded.1/Attributes"
} #>
try
    {
    if ($global:get_powershell_version -gt 5)
    {
    $result = Invoke-WebRequest -SkipCertificateCheck -SkipHeaderValidation -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    else
    {
    Ignore-SSLCertificates
    $result = Invoke-WebRequest -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    }
Write-Host

$get_all_attributes=$result.Content | ConvertFrom-Json | Select Attributes

# Check to see if return attributes only for cmdlet

if ($view_attribute_list_only -eq "y")
{
if ($result.StatusCode -eq 200)
{
    [String]::Format("- PASS, GET command passed, statuscode {0} returned successfully to get ""{1}"" attributes:",$result.StatusCode, $attribute_group.ToUpper())
    $get_all_attributes.Attributes
try 
{
    Remove-Item("attributes.txt") -ErrorAction Stop
    Write-Host "- WARNING, attributes.txt file detected, file deleted and will create new file with attributes and current values"
}
catch [System.Management.Automation.ActionPreferenceStopException] {
    Write-Host "- WARNING, attributes.txt file not detected, delete file not executed" 
}

Write-Host -ForegroundColor Yellow "`n- WARNING, Attributes also copied to ""attributes.txt"" file"
$final_all_attributes=$get_all_attributes.Attributes | ConvertTo-Json -Compress
foreach ($i in $final_all_attributes)
{
Add-Content attributes.txt $i
}
    return
}
else
{
    [String]::Format("- FAIL, statuscode {0} returned",$result.StatusCode)
    return
}
#$write_to_file=Add-Content "$file_path\multiple_idrac_lc_system_attributes.txt"
}

if ($view_attribute_list_only -eq "n")
{
return
}


# Create hashtable for attribute names and values from text file



																				  
$dict = @{}
$input_key_values.Split('|') |ForEach-Object {
    # Split each pair into key and value
    $key,$value = $_.Split(':')
    # Populate $Dictionary
    if ($value -match "^([\d]+[\.]?[\d]*|[\d]*[\.]?[\d]+)$")
    {
    $value=[int]$value
    }
    $dict[$key] = $value
    write-host $value
}


$dict_final=@{"Attributes"=""}
$dict_final.("Attributes")=$dict 
$JsonBody = $dict_final | ConvertTo-Json -Compress

# Create hashtable for setting attribute new values which will be used to compare against new values at the end of the script

$pending_dict=@{}

foreach ($i in $dict.GetEnumerator())
{
    $attribute_name = $i.Name
    $get_attribute_name=$get_all_attributes.Attributes | Select $attribute_name
    $get_attribute_value=$attribute_name
    #$attribute_value=$get_attribute_name.$get_attribute_value
    #$pending_value = $i.Value
    #Write-Host -ForegroundColor Yellow "- WARNING, attribute $attribute_name current value is: $attribute_value, setting pending value to: $pending_value"
    [String]::Format("- WARNING, attribute {0} current value is: {1}, setting new value to: {2}",$attribute_name,$get_attribute_name.$get_attribute_value,$i.Value)
    $pending_dict.Add($attribute_name,$i.Value)
}
Write-Host

#$u1 = "https://$idrac_ip/redfish/v1/Systems/System.Embedded.1/Bios/Settings"


# PATCH command to set attribute pending value

	
	 
											 
    
try
    {
    if ($global:get_powershell_version -gt 5)
    {
    
    $result1 = Invoke-WebRequest -UseBasicParsing -SkipHeaderValidation -SkipCertificateCheck -Uri $uri -Credential $credential -Method Patch -ContentType 'application/json' -Headers @{"Accept"="application/json"} -Body $JsonBody -ErrorVariable RespErr
    }
    else
    {
    Ignore-SSLCertificates
    $result1 = Invoke-WebRequest -UseBasicParsing -Uri $uri -Credential $credential -Method Patch -ContentType 'application/json' -Headers @{"Accept"="application/json"} -Body $JsonBody -ErrorVariable RespErr
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    } 


	
#$raw_content=$result1.RawContent | ConvertTo-Json -Compress
		
	 
	
																																												
if ($result1.StatusCode -eq 200)
{
    #$code=$result1.StatusCode
    #Write-Host -ForegroundColor Green "- PASS, statuscode $code returned to successfully set attributes pending value"
    [String]::Format("- PASS, statuscode {0} returned to successfully set ""{1}"" attributes",$result1.StatusCode, $attribute_group.ToUpper())
}
else
{
    [String]::Format("- FAIL, statuscode {0} returned",$result1.StatusCode)
    return
}


# GET command to verify new attribute values are set correctly 

try
    {
    if ($global:get_powershell_version -gt 5)
    {
    $result = Invoke-WebRequest -SkipCertificateCheck -SkipHeaderValidation -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    else
    {
    Ignore-SSLCertificates
    $result = Invoke-WebRequest -Uri $uri -Credential $credential -Method Get -UseBasicParsing -ErrorVariable RespErr -Headers @{"Accept"="application/json"}
    }
    }
    catch
    {
    Write-Host
    $RespErr
    return
    } 
Write-Host
if ($result.StatusCode -eq 200)
{
    [String]::Format("- PASS, statuscode {0} returned successfully to get ""{1}"" attributes",$result.StatusCode,$attribute_group.ToUpper())
}
else
{
    [String]::Format("- FAIL, statuscode {0} returned",$result.StatusCode)
}

$get_all_attributes=$result.Content | ConvertFrom-Json | Select Attributes
Write-Host
foreach ($i in $pending_dict.GetEnumerator())
{
$attribute_name = $i.Name
$get_attribute= $get_all_attributes.Attributes | Select $attribute_name
$get_attribute_value=$attribute_name
if ( $get_attribute.$get_attribute_value -eq $i.Value )
{
[String]::Format("- PASS, attribute {0} current value is successfully set to: {1}",$attribute_name,$get_attribute.$get_attribute_value)
}
else
{
[String]::Format("- FAIL, attribute {0} current value not successfully set to: {1}, current value is: {2}",$attribute_name,$i.Value,$get_attribute.$get_attribute_value)
}
}
}

#racadm -r $idrac -u $user -p $password --nocertwarn config -g cfgIpmiPet -o cfgIpmiPetAlertEnable -i 4 1
#racadm -r $idrac -u $user -p $password --nocertwarn set iDRAC.SNMP.TrapFormat 1
#racadm -r $idrac -u $user -p $password --nocertwarn set iDRAC.SNMP.AgentEnable enabled


$snmpdest1="x.x.x.x"
$snmpdest2="x.x.x.x"
$inputfile = import-csv $path -header 'name'
$x=0
$input_key_values="SNMPAlert.1.Destination:$snmpdest1|SNMPAlert.2.Destination:$snmpdest2|SNMPAlert.3.Destination:|SNMPAlert.4.Destination:|SNMPAlert.1.State:Enabled|SNMPAlert.2.State:Enabled|SNMPAlert.3.State:Disabled|SNMPAlert.4.State:Disabled"
#$smtp_ipaddress = ""

foreach ($idrac in $inputfile) {

#Set "Alert Configuration" Alerts -> equal to Enabled
racadm -r $inputfile[$x].name -u $idrac_user -p $pass --nocertwarn set idrac.IPMILan.AlertEnable Enabled

#Set "SMTP (Email) Configuration" -> SMTP (Email) Server Settings -> SMTP (Email) Server IP Address or FQDN / DNS Name to $snmp_ipaddress
#racadm -r $idrac -u $user -p $password --nocertwarn set iDRAC.RemoteHosts.SMTPServerIPAddress $smtp_ipaddress


racadm -r $inputfile[$x].name -u $idrac_user -p $pass --nocertwarn eventfilters set -c idrac.alert.all -a none -n snmp

racadm -r $inputfile[$x].name -u $idrac_user -p $pass set iDRAC.SNMP.TrapFormat SNMPv2
# Create hashtable for attribute names and values from text file

##if old gen dell server use this racadm command:
#racadm -r $inputfile[$x].name -u $idrac_user -p $pass set idrac.SNMP.Alert.1.DestAddr $snmpdest1
#racadm -r $inputfile[$x].name -u $idrac_user -p $pass set idrac.SNMP.Alert.2.DestAddr $snmpdest2


##if new gen dell server use:
Set-IdracLcSystemAttributesREDFISH -idrac_ip $inputfile[$x].name -idrac_username $idrac_user -idrac_password $pass -attribute_group idrac 
$x++
}
