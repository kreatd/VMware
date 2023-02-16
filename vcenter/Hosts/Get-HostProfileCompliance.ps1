#############################################
#Checks host profile compliance on all hosts#
param(
    [string[]] $vcenters
    )

connect-viserver $vcenters

get-vmhost -server $vcenters | Test-VMHostProfileCompliance -ErrorAction SilentlyContinue

disconnect-viserver * -confirm:$false