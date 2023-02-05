param (
    [Parameter(Mandatory=$true)]$vmtoclone,
    [Parameter(Mandatory=$true)]$newname
)

function cloner($vmtoclone, $newname){
    try {
    	$vm=get-vm -name $vmtoclone
        $snapshot=get-snapshot -VM $vm -name "base"
        $vmhost=get-vmhost -name "192.168.7.19"
        $ds=Get-Datastore -name datastore2-super9

        $linkedName = "{0}.linked" -f $vm.name
        $linkedVM = New-VM -LinkedClone -Name $linkedName -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds

    	$newVM = New-VM -name "$newname.base" -VM $linkedvm -VMHost $vmhost -Datastore $ds
    	$newVM | New-Snapshot -Name "Base"

	Remove-VM $linkedName
    } catch {
        Write-Host "An error occurred:"
        Write-Host $_
        exit
    }
}

try {
    Connect-VIServer -Server vcenter.sam.local
    cloner $vmtoclone $newname
} catch {
    Write-Host "An error occurred:"
    Write-Host $_
    exit
}
