import-module -Name .\480-sam.psm1 -Force

$vars = read-config ".\config.json"
Write-Host
$vars
Write-Host
connect-vcenter $vars["vcenter"]
get-vms "BASEVM"