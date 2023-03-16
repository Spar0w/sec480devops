import-module -Name .\480-sam.psm1 -Force

$vars = read-config ".\config.json"
connect-vcenter $vars["vcenter"]
#create 3 rocky vms on the blue network:
for ($x=0;$x -lt 3;$x++){
    $name = linkedcloner $vars
    set-network -VMName $name -Network "blue-lan2-pg"
    sstart-vm -Name $name
}
