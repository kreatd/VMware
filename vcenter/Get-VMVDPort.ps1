
 <#
 
.DESCRIPTION
 This script will pull the list of all the vms/nics per vdport
 
.PARAMETER <Parameter_Name>
	$vcenter, input vcenter name (one at a time)
   $path, path of csv containing vdport list (do not include a header)
   
.INPUTS
  inputcsv should list all vdports with no header - just have the full list of vdports.  be sure that those vdports are associated with the defined DVswitch or
  else the script won't run correctly.
  If you're unsure on how to do that, try to run the script and review the output.  You should be able to see where the script breaks which will point you in the right direction
 
.OUTPUTS
 output the list of vms,vdports,macaddresses,vmhosts,etc
 
.NOTES
  Version:        1.0
  Author:         Daniel Kreatsoulas
  Creation Date:  7/6/2021



.EXAMPLE
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!If you receive blank data/macaddresses, that's because some of the vdports that you used as input aren't in use by the DVS!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ./Get-VMVDPort.ps1 -vcenter "vcenter" -dvswitch "DVS1" -path "path/to/vdportslist.csv"

#>

#####

param(
    $vcenter,
    $dvswitch,
    $path
	
    )
  
$vc=Connect-VIServer $vcenter

$vdports = import-csv $path -header "portid"

$macs=@()
$VMs=@()
$output=@()
$i=0;
#write-output $vdports

foreach($vdport in $vdports)
    {
        #Get-VDSwitch -Name $dvswitch -server $vc | get-vdport | where {$_.key -like $vdport.portid}| select macaddress,proxyhost,portgroup,key
       # Get-VDSwitch -Name $dvswitch -server $vc | get-vdport | where {$_.key -like $vdport.portid}| select macaddress,proxyhost,portgroup,key
        $macs+=Get-VDSwitch -Name $dvswitch -server $vc | get-vdport | where {$_.key -like $vdport.portid}| select macaddress,proxyhost,portgroup,key
      #  if($macs[$i].macaddress -like ""){
       #     $VMs[$i].Parent = "null"
      #      $VMs[$i].macaddress = "null"
      #      $VMs[$i].name = "null"
      #      $VMs[$i].network = "null"
      #  }
        $VMs+=get-vmhost $macs[$i].proxyhost.name -server $vc |get-vm | get-networkadapter|where{$_.macaddress -like $macs[$i].macaddress}|select Parent,macaddress,name,networkname
      # $VMs+=get-vmhost $macs[$i].proxyhost.name -server $vc |get-vm | get-networkadapter|% {
           <# if($_.macaddress -like $macs[$i].macaddress){
                $_|select Parent,macaddress,name,networkname}
                else{
                    $VMs[$i].parent -eq "null";
                    $VMs[$i].macaddress -eq "null"; 
                    $VMs[$i].name -eq "null";
                    $VMs[$i].networkname -eq "null";}
                }
#>

        #if( $_.macaddress -notlike $macs[$i].macaddress){$macs[$i].parent -eq "null";$macs[$i].macaddress -eq "null"; $macs.name -eq "null";$macs.networkname -eq "null";}
       <# if($macs[$i].macaddress -like ""){
            $macs[$i]
            $VMs[$i].Parent = "null"
            $VMs[$i].macaddress = "null"
            $VMs[$i].name = "null"
            $VMs[$i].network = "null"
        }#>
        $i=$i+1;
    }

#$macs=$macs|sort-object -property macaddress
#$VMs=$VMs|sort-object -property macaddress



$output = for ( $i = 0; $i -lt $vdports.length; $i++)
    {
        Write-Verbose "$($macs[$i]),$($VMs[$i])"
        [PSCustomObject]@{
            VMName = $VMs[$i].parent
            networkname = $VMs[$i].networkname
            networkadapter = $VMs[$i].name
            VMNicMac = $VMs[$i].macaddress
            macaddress = $macs[$i].macaddress
            VMHost = $macs[$i].proxyhost.name
            portgroup = $macs[$i].portgroup
            vdport = $macs[$i].key
     
        }
    }
$output
<#
foreach($nic in $macs)
    {
        $nic.proxyhost |Get-VM | Get-NetworkAdapter | where{$_.macaddress -like $nic.macaddress} | select Parent,macaddress,name,networkname
        #$nic.proxyhost |Get-VM | Get-NetworkAdapter | where{$_.macaddress -like $nic.macaddress} | select Parent,macaddress,name,networkname
        $VMs+=$nic.proxyhost |Get-VM | Get-NetworkAdapter | where{$_.macaddress -like $nic.macaddress} | select Parent,macaddress,name,networkname
    }
    #>
#$macs|export-csv macs.csv

#$VMs | export-csv vms.csv
#write-output $macs| sort-object -property macaddress
#write-output $VMs | sort-object -property macaddress
