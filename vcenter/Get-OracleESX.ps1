
<#
.SYNOPSIS
  Takes parameters and generates an oracle data report

.NOTES
  Version:        1.0
  Author(s):      Daniel Kreatsoulas 
  Creation Date:  07/31/2020
  Purpose/Change: Initial script development

.EXAMPLE
./Get-OracleESX.ps1  -vcenter vcenter1,vcenter2,vcenter3
#>
param(  
[Parameter(Mandatory=$true)] 
$vcenter = $(throw "vCenter(s) is required.")
)  

$server = connect-viserver $vcenter

$OracleHostGroups = Get-DrsClusterGroup -name "Oracle Hosts" -server $server
$OracleMembers=Get-DrsClusterGroup -name "Oracle_VMs" -server $server 
$OraclePartitionMembers=Get-DrsClusterGroup -name "Oracle Partitioning VMs" -server $server
$a=@()
$x=0
foreach($OracleHostGroup in $OracleHostGroups)
    {
        $o = new-object PSObject 
        $o | add-member NoteProperty -name "Cluster" $OracleHostGroups[$x].cluster.name
        $hostnames = $OracleHostGroups[$x].member.name -join '; '
        $o | add-member NoteProperty -name "Hostnames" $hostnames
        $o | add-member NoteProperty -name "Host Count" $OracleHostGroups[$x].member.count    
        $hostCoreCount = $OracleHostGroups[$x].member | measure-object -property numcpu -sum
        $o | add-member NoteProperty -name "Core Count" $hostCoreCount.sum
        $hostMemoryCount = $OracleHostGroups[$x].member | measure-object -property MemoryTotalGB -sum
        $o | add-member NoteProperty -name "Host Memory Count" $hostMemoryCount.sum
        $OracleMemory=Get-VM $OracleMembers[$x].Member -server $server | measure-object -property memorygb -sum
        $o | add-member NoteProperty -name "VM Memory" $OracleMemory.sum
        if($OraclePartitionMembers[$x].member)
        {
            
            $OraclePartMemory=Get-VM $OraclePartitionMembers[$x].Member -server $server | measure-object -property memorygb -sum
            $o | add-member NoteProperty -name "Partition VM Memory" $OraclePartMemory.sum
        }else{
            $o | add-member NoteProperty -name "Partition VM Memory" -value 0
        }
        $a +=$o
        $x++
    }
disconnect-viserver $server -Confirm:$False
$a | export-csv "Oracle_ESX.csv"