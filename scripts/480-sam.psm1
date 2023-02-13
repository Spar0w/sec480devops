#file with variables to reuse

function read-config($configfile){
    
    #read user input or assign default values for the rest of the module
    $linkedvars = Get-Content -Raw $configfile | ConvertFrom-Json -AsHashtable

    $vcenterString = "Enter the IP/URL: for vcenter [$($linkedvars['vcenter'])]"
    $vcenter = Read-Host $vcenterString
    # if $x has input, assign the var in the hash table to that
    if (![string]::IsNullOrWhiteSpace($vcenter)){ $linkedvars["vcenter"] = $vcenter }
    # repeat
    $esxiString = "Enter the IP/URL: for esxi [$($linkedvars['esxiIP'])]"
    $esxi = Read-Host $esxiString
    # if $x has input, assign the var in the hash table to that
    if (![string]::IsNullOrWhiteSpace($esxi)){ $linkedvars["esxiIP"] = $esxi }
    
    $dataString = "Enter the datastore you would like to use [$($linkedvars['datastore'])]"
    $datastore = Read-Host $dataString
    # if $x has input, assign the var in the hash table to that
    if (![string]::IsNullOrWhiteSpace($datastore)){ $linkedvars["datastore"] = $datastore }

    return $linkedvars
}

function connect-vcenter($vcenter){
    #try to connect to vcenter with our hash table options
    try {
        Connect-VIServer -Server $vcenter
        #linkedcloner $vmtoclone $newname
    } catch {
        Write-Host "An error occurred connecting to Vcenter:"
        Write-Host $_
        exit
    }

}

function get-vms($folder){
    Get-Folder $folder
}

function cloner([hashtable]$vars){
    #creates a full clone from a base snapshot

    #read input from the user
    get-vms "BASEVM"
    $vmtoclone = Read-Host "Enter the number associated with the VM you would like to clone: "

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
        return
    }
}

function linkedcloner($vmtoclone, $newname){
    #creates a linked clone from a base snapshot
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

# initialize the module with cool ascii art
Clear-Host

$coolAscii = @"  
  _________                  _____   ______ _______   
 /   _____/ ____   ____     /  |  | /  __  \\   _  \  
 \_____  \_/ __ \_/ ___\   /   |  |_>      </  /_\  \ 
 /        \  ___/\  \___  /    ^   /   --   \  \_/   \
/_______  /\___  >\___  > \____   |\______  /\_____  /
        \/     \/     \/       |__|       \/       \/ 
"@


Write-Host $coolAscii
Export-ModuleMember -Function * 
#Export-ModuleMember -Function connect-vcenter
