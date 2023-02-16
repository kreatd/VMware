param(
    [string] $location=".",
    [array] $vcenters
    )
$vcenters=Connect-VIServer $vcenters

$datestamp=Get-Date -Format yyyy.MM.dd.HH.mm

$rows=@()
get-view -ViewType HostSystem -Property Name, ConfigManager.DateTimeSystem | %{    
    #get host datetime system
    $dts = get-view $_.ConfigManager.DateTimeSystem
    
    #get host time
    $t = $dts.QueryDateTime()
    
    #calculate time difference in seconds
    $s = ( $t - [DateTime]::UtcNow).TotalSeconds
    
    #print host and time difference in seconds
    $row = "" | select HostName, Seconds
    $row.HostName = $_.Name
    $row.Seconds = [MATH]::abs($s)
    $rows+=$row
}

$a = "<style>"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;text-align: center}"
$a = $a + "TH{border-width: 1px;padding: 5px;border-style: solid;border-color: black;}"
$a = $a + "TD{border-width: 1px;padding: 5px;border-style: solid;border-color: black;}"
$a = $a + "</style>"

write-output $rows|Sort-Object -Descending Seconds|ConvertTo-Html -Head $a -Body "<H2> ESXi Host Time Drift Values as of: $(get-date) </H2>"|out-file "$location\Host_Time_Drift.$datestamp.html"
Disconnect-VIServer * -Confirm:$false -force