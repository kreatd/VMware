 <#
.SYNOPSIS
  Convert VMDKs from Thin to Thick
 
.DESCRIPTION
 This script will convert vmdks from thick to thin
 
.PARAMETER <Parameter_Name>
	$vcenter, string array listing the vCenter that you'd like to run the script on.
   $path, path of csv containing VMs that you want to convert from thin to thick.
   
.INPUTS
  vCenter input from user along with path to CSV containing VMs
 
.OUTPUTS
 writes out output per change to the terminal
 
.NOTES
  Version:        1.0
  Author:         Daniel Kreatsoulas
  Creation Date:  12/22/2020
  Purpose/Change: Initial script development
  Version:        1.1
  Author:         Daniel Kreatsoulas
  Creation Date:  2/10/2021
  Purpose/Change: Added the ability to run this script on more than one vcenter at a time.  Also corrected a bug where
  it would not convert a vmdk from thin to thick.


.EXAMPLE
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!DO NOT EXECUTE THIS SCRIPT ON DISKS GREATER THAN 500GB!  You should do those ones manually!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ./Move-ThintoThick.ps1  -vcenters "vcenter1","vcenter2" -path "C:\path\to\csv.csv"

#>

#####

param(
    [Parameter(Mandatory=$true)]$vcenters,
    [Parameter(Mandatory=$true)]$path
	
    )
  
$vcenter=Connect-VIServer $vcenters

$inputvms = import-csv $path -header "name"


$VMDKs=Get-VM $inputvms.name -server $vcenter | Get-HardDisk | Where {$_.storageformat -eq "Thin" } | Select Parent, Name, CapacityGB, storageformat



foreach ($vmdk in $VMDKs)
{
        write-output "vm" $vmdk.Parent

        write-output "HARDDISK" $vmdk.name $vmdk.storageformat $vmdk.provisionedspacegb

        $currentds=get-vm $vmdk.Parent -server $vcenter |get-harddisk -name $vmdk.name | get-datastore

        write-output "CURRENT DS" $currentds

        $dscluster = get-datastore -name $currentds -server $vcenter| get-datastorecluster

        write-output "CURRENT DS Cluster" $dscluster

        

        $finalds=Get-DatastoreCluster $dscluster -server $vcenter |get-datastore|sort freespacegb -Descending|select -Index ((get-random)%2)

        while($currentds -eq $finalds)
        {
          $finalds=Get-DatastoreCluster $dscluster -server $vcenter |get-datastore|sort freespacegb -Descending|select -Index ((get-random)%2)
          write-output "DS swapped due to current location of thin disk."
        }
       
        write-output "FINAL DESTINATION DS" $finalds

        $y=get-vm $vmdk.Parent -server $vcenter | get-harddisk -name $vmdk.name | move-harddisk -datastore $finalds -StorageFormat Thick -confirm:$false

        write-output $y

}

Disconnect-VIServer * -Confirm:$false -force

	
