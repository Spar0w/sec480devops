param (
    [Parameter(Mandatory=$true)]$vmtoclone,
    [Parameter(Mandatory=$true)]$newname
)

#file with variables to reuse
$global:linkedvars = Get-Content -Raw .\linkedvars.json | ConvertFrom-Json -AsHashtable

function linkedcloner($vmtoclone, $newname){
    try {
    	$vm=get-vm -name $vmtoclone
        $snapshot=get-snapshot -VM $vm -name "base"
        $vmhost=get-vmhost -name $linkedvars["esxiIP"]
        $ds=Get-Datastore -name $linkedvars["datastore"]

        $linkedName = $newname 
        $linkedVM = New-VM -LinkedClone -Name $linkedName -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds

        #set network adapter
        $linkedVM | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $linkedvars["newnetadap"]

    } catch {
        Write-Host "An error occurred creating the linked clone:"
        Write-Host $_
        exit
    }
}

try {
    Connect-VIServer -Server $linkedvars["vcenter"]
    linkedcloner $vmtoclone $newname
} catch {
    Write-Host "An error occurred connecting to Vcenter:"
    Write-Host $_
    exit
}
