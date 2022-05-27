#Function to maximize the resolution of Linux virtual machines on Hyper-V.

function HyperVFullScreen () {
    
[CmdletBinding()]
    param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            HelpMessage="Provide the name of the virtual machine.")]
        [ValidateNotNullOrEmpty()] 
        [ValidateLength(1,15)]
        [ValidatePattern('[a-z][A-Z]')]
        [String]$VMName,
    
        [Parameter(
            Position=1,
            Mandatory=$true,
            HelpMessage="Provide the horizontal resolution for the host.")]
        [ValidateNotNullOrEmpty()] 
        [ValidatePattern('[0-9]')]
        [Int32]$Horizontal,

        [Parameter(
            Position=2,
            Mandatory=$true,
            HelpMessage="Provide the vertical resolution for the host.")]
        [ValidateNotNullOrEmpty()] 
        [ValidatePattern('[0-9]')]
        [Int32]$Vertical
    )
    
$Status = Get-VM -Name $VMName
    if ($Status.State -eq "Running") {
        Write-Warning -Message "Unable to change settings while $($VMName) is running".
        break
    }

    try {
        Set-VMVideo -VMName $VMName -horizontalresolution:$Horizontal -verticalresolution:$Vertical -resolutiontype single
    }
    
    catch {
        Write-Warning -Message "Unable to set the resolution".
        break
    }
}
