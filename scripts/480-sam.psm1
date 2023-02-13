#Samuel Barrows 480-module

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
    if (!$global:DefaultVIServers.Count -gt 0){
        try {
            Connect-VIServer -Server $vcenter
        } catch {
            Write-Host "An error occurred connecting to Vcenter:"
            Write-Host $_
            exit
        }
    }

}

function get-vms($folder){
    $vmsInFolder = @()
    Get-Folder $folder | Get-VM | Select-Object -Property Name | `
    ForEach-Object{
        #add the names of each vm to an array
        $vmsInFolder += $_
    }
    return $vmsInFolder
}

function select-vm($folder){
    #Provide user input to select an available VM

    #Get our list of VMs
    $vmList = get-vms $folder

    $vmtoclone = $null
    while ($True){
        #List base vms
        $x=0
        $vmList | ForEach-Object{
            $name = $_.Name
            Write-Host "[$x] $name"
            $x+=1
        }
        $vmnum = Read-Host "Enter the number associated with the VM you would like to operate on"

        #validate input
        try {
            if ([int]$vmnum -gt $vmList.Length - 1 || [int]$vmnum -lt 1){
                Write-Error "Invalid option, please try again"
            } else {
                $vmtoclone = $vmList[[int]$vmnum].Name
                break
            }
        } catch {
            Write-Error "Invalid option, please try again"
        }
    }

    if([string]::IsNullOrWhiteSpace($vmtoclone)) {
        Write-Error "An Error Occured: VM not found"
        exit
    }
    return $vmtoclone
}

function cloner($vars){
    #creates a full clone from a base snapshot

    $vmtoclone = select-vm "basevm"

    $newname = Read-Host "Enter the name of the new clone"

    Write-Host "Cloning $vmtoclone to $newname"

    try {
    	$vm=get-vm -name $vmtoclone
        $snapshot=get-snapshot -VM $vm -name "base"
        $vmhost=get-vmhost -name $vars["esxiIP"]
        $ds=Get-Datastore -name $vars["datastore"]

        $linkedName = "{0}.linked" -f $vm.name
        $linkedVM = New-VM -LinkedClone -Name $linkedName -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds

    	$newVM = New-VM -name "$newname" -VM $linkedvm -VMHost $vmhost -Datastore $ds
    	$newVM | New-Snapshot -Name "Base"

	    Remove-VM $linkedName
    } catch {
        Write-Host "An error occurred:"
        Write-Error $_
        return
    }
}

function linkedcloner($vars){
    #creates a linked clone from a base snapshot
    $vmtoclone = select-vm("basevm")

    $newname = Read-Host "Enter the name of the new linked clone"

    Write-Host "Cloning $vmtoclone to the linked clone $newname"

    try {
    	$vm=get-vm -name $vmtoclone
        $snapshot=get-snapshot -VM $vm -name "base"
        $vmhost=get-vmhost -name $vars["esxiIP"]
        $ds=Get-Datastore -name $vars["datastore"]

        $linkedName = $newname 
        $linkedVM = New-VM -LinkedClone -Name $linkedName -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds

        #set network adapter
        $linkedVM | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $vars["newnetadap"]

    } catch {
        Write-Host "An error occurred creating the linked clone:"
        Write-Error $_
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