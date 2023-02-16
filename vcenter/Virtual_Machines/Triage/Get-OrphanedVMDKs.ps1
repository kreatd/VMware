<#
  .SYNOPSIS   Report on orphaned VMDKs on our staging hosts
  .DESCRIPTION   This script uses Luc D's old function that lists all orphaned VMDKs.  This was created to allow us to be
  proactive with the garbage that gets left behind during an OVA deployment failure in our staging environment.
  
  .NOTES   Author:  Daniel Kreatsoulas
           Creation Date: 11/3/2020

  #>
#param(
#  [string[]] $vcenter = @("vcenter1","vcenter2")
#)

function Remove-OrphanedData {
  <#
  .SYNOPSIS   Remove orphaned folders and VMDK files
  .DESCRIPTION   The function searches orphaned folders and VMDK files
  on one or more datastores and reports its findings.
  Optionally the function removes  the orphaned folders   and VMDK files
  .NOTES   Author:  Luc Dekens
  .PARAMETER Datastore
  One or more datastores.
  The default is to investigate all shared VMFS datastores
  .PARAMETER Delete
  A switch that indicates if you want to remove the folders
  and VMDK files
  .EXAMPLE
  PS> Remove-OrphanedData -Datastore ds1
  .EXAMPLE
  PS> Get-Datastore ds* | Remove-OrphanedData
  .EXAMPLE
  PS> Remove-OrphanedData -Datastore $ds -Delete
  #>
  [CmdletBinding(SupportsShouldProcess=$true)]
  param(
  [parameter(Mandatory=$true,ValueFromPipeline=$true)]
  [PSObject[]]$Datastore,
  [switch]$Delete
  )
  begin{
  $fldList = @{}
  $hdList = @{}
  $fileMgr = Get-View FileManager
  }
  process{
  foreach($ds in $Datastore){
  if($ds.GetType().Name -eq "String"){
  $ds = Get-Datastore -Name $ds
  }
  if($ds.Type -eq "VMFS"){#(modified by Dan to resolve an issue with our staging environment)-and $ds.ExtensionData.Summary.MultipleHostAccess){
  Get-VM -Datastore $ds | %{
  $_.Extensiondata.LayoutEx.File | where{"diskDescriptor","diskExtent" -contains $_.Type} | %{
  $fldList[$_.Name.Split('/')[0]] = $_.Name
  $hdList[$_.Name] = $_.Name
  }
  }
  Get-Template -Datastore $ds| where {$_.DatastoreIdList -contains $ds.Id} | %{
  $_.Extensiondata.LayoutEx.File | where{"diskDescriptor","diskExtent" -contains $_.Type} | %{
  $fldList[$_.Name.Split('/')[0]] = $_.Name
  $hdList[$_.Name] = $_.Name
  }
  }
  $dc = $ds.Datacenter.Extensiondata
  $flags = New-Object VMware.Vim.FileQueryFlags
  $flags.FileSize = $true
  $flags.FileType = $true
  $disk = New-Object VMware.Vim.VmDiskFileQuery
  $disk.details = New-Object VMware.Vim.VmDiskFileQueryFlags
  $disk.details.capacityKb = $true
  $disk.details.diskExtents = $true
  $disk.details.diskType = $true
  $disk.details.thin = $true
  $searchSpec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
  $searchSpec.details = $flags
  $searchSpec.Query += $disk
  $searchSpec.sortFoldersFirst = $true
  $dsBrowser = Get-View $ds.ExtensionData.browser
  $rootPath = "[" + $ds.Name + "]"
  $searchResult = $dsBrowser.SearchDatastoreSubFolders($rootPath, $searchSpec)
  foreach($folder in $searchResult){
  if($fldList.ContainsKey($folder.FolderPath.TrimEnd('/'))){
  foreach ($file in $folder.File){
  if(!$hdList.ContainsKey($folder.FolderPath + $file.Path)){
  New-Object PSObject -Property @{
  Folder = $folder.FolderPath
  Name = $file.Path
  Size = $file.FileSize
  CapacityKB = $file.CapacityKb
  Thin = $file.Thin
  Extents = [string]::Join(',',($file.DiskExtents))
  }
  if($Delete){
  If ($PSCmdlet.ShouldProcess(($folder.FolderPath + " " + $file.Path),"Remove VMDK")){
  #$dsBrowser.DeleteFile($folder.FolderPath + $file.Path)
  }
  }
  }
  }
  }
  elseif($folder.File | where {"cos.vmdk","esxconsole.vmdk" -notcontains $_.Path}){
  $folder.File | %{
  New-Object PSObject -Property @{
  Folder = $folder.FolderPath
  Name = $_.Path
  Size = $_.FileSize
  CapacityKB = $_.CapacityKB
  Thin = $_.Thin
  Extents = [String]::Join(',',($_.DiskExtents))
  }
  }
  
  if($Delete){
  if($folder.FolderPath -eq $rootPath){
  $folder.File | %{
  If ($PSCmdlet.ShouldProcess(($folder.FolderPath + " " + $_.Path),"Remove VMDK")){
  #$dsBrowser.DeleteFile($folder.FolderPath + $_.Path)
  }
  }
  }
  else{
  If ($PSCmdlet.ShouldProcess($folder.FolderPath,"Remove Folder")){
  #$fileMgr.DeleteDatastoreFile($folder.FolderPath,$dc.MoRef)
  }
  }
  }
  }
  }
  }
  }
  }
  }
  $output=@()
 
#temporary until I resolve the issue with looping through vCenters with the Luc D function.

  $vcenter = connect-viserver vcenter2
  $datastores = get-cluster *xxx -Server $vcenter| get-vmhost | get-datastore | where {$_.name -notlike "xxx*"}
  $output += Remove-OrphanedData -datastore $datastores
  disconnect-viserver $vcenter -confirm:$false
  $vcenter = connect-viserver vcenter1
  $datastores = get-cluster *xxx -Server $vcenter| get-vmhost | get-datastore | where {$_.name -notlike "xxx*"}
  $output += Remove-OrphanedData -datastore $datastores
  disconnect-viserver $vcenter -confirm:$false


  


 
  

  if($output){
    Send-MailMessage -BodyAsHtml -Body "<table><tr><td>$($output | ConvertTo-Html)</tr></td></table>" `
	-From "scripthost" `
	-To "teamname" `
	-Smtpserver "smtprelayserver" `
  -Subject "Staging Area Orphaned VMDKs"
  }
  else{
    Send-MailMessage -BodyAsHtml -Body "<table><tr><td>no output</tr></td></table>" `
    -From "scripthost" `
    -To "teamname" `
    -Smtpserver "smtprelayserver" `
    -Subject "Staging Area Orphaned VMDKs"
  }
  
