import-module -Name .\480-sam.psm1 -Force

$vars = read-config ".\config.json"
Write-Host
$vars
Write-Host
connect-vcenter $vars["vcenter"]
set-network -VMName "blue1-fw" 
#sstart-vm "blue1-fw"