function HyperVGenerator () {
    
[CmdletBinding()]
    param(
        [Parameter(
        Position=0,
        Mandatory=$true,
        HelpMessage="Provide the name of the new virtual machine.")]
        [ValidateNotNullOrEmpty()] 
        [ValidateLength(1,15)]
        [String]$VMName,

        [Parameter(
        Position=1,
        HelpMessage="Provide the virtual switch to attach for the virtual machine.")]
        [ValidateNotNullOrEmpty()]
        [String]$NetSwitch = "Default Switch",
    
        [Parameter(
        Position=2,
        Mandatory=$true,
        HelpMessage="Provide the amount of memory allowed for the virtual machine (in GB).")]
        [ValidateNotNullOrEmpty()] 
        [String]$Memory,
        
        [Parameter(
        Position=3,
        Mandatory=$true,
        HelpMessage="Provide the amount of storage for the new virtual disk (in GB).")]
        [String]$StorageSize,

        [Parameter(
        Position=4,
        HelpMessage="Provide the filesystem path for the new virtual disk.")]
        [ValidateNotNullOrEmpty()]
        [String]$StoragePath = "$($env:SystemDrive)\Hyper-V",

        [Parameter(
        Position=5,
        HelpMessage="Provide the generation for the virtual machine.")]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1,2)] 
        [Int32]$Generation = 2,

        [Parameter(
        Position=6,
        HelpMessage="Provide the amount of logical processors for the virtual machine.")]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1,4)] 
        [Int32]$LogicalProcessors = 2
    )

    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $WorkingDirectory = "$($StoragePath)"+"\"+"$($VMName)"

    if (!($CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
        Write-Warning -Message "Not enough privileges to run this function."
        break
    }
    
    else {
        New-Item -ItemType Directory "$($WorkingDirectory)" -Force
    }
        
    try {
        #Divide to convert the strings from the parameters to Uint64. (https://stackoverflow.com/questions/41088561/how-to-convert-to-uint64-from-a-string-in-powershell-string-to-number-conversio)
        $MemoryInteger = ($Memory / 1GB * 1GB)
        $StorageSizeInteger = ($StorageSize /1GB *1GB)

        $Folders = @("Snapshots", "SmartPaging")
        foreach ($Folder in $Folders) {
            New-Item -ItemType Directory "$($WorkingDirectory)\$Folder" -Force
        }

        New-VM -Name $VMName `
        -SwitchName $NetSwitch `
        -MemoryStartupBytes $MemoryInteger `
        -NewVHDSizeBytes $StorageSizeInteger `
        -NewVHDPath "$($WorkingDirectory)\VirtualDisk.vhdx" `
        -Generation $Generation

        Set-VM -Name $VMName `
        -SnapshotFileLocation "$($WorkingDirectory)\Snapshots" `
        -SmartPagingFilePath "$($WorkingDirectory)\SmartPaging" `
        -ProcessorCount $LogicalProcessors `
        -AutomaticCheckpointsEnabled $true `
        -CheckpointType Production `
        -AutomaticStopAction TurnOff

        Set-VMMemory -VMName $VMName `
        -DynamicMemoryEnabled $true `
        -MinimumBytes 1GB `
        -MaximumBytes 6GB `
    }

    catch {
        Write-Warning -Message "Could not execute the following request."
        break
    }
}
