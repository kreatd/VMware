#./Get-BalloonedVMs.ps1  hostname

param(
[Parameter(Mandatory=$true)] [string] $vmhost = $(Read-Host -prompt "host name is needed")
)

$balvms = get-vm -Location $vmhost | Get-View | Where-Object {$_.Summary.QuickStats.BalloonedMemory -ne "0"} | Select Name,@{Name="Swapped";Expression={$_.summary.quickstats.swappedmemory}},@{Name="Ballooned";Expression={$_.summary.quickstats.balloonedmemory}}
$balvms | ft -AutoSize Name,Swapped,Ballooned
