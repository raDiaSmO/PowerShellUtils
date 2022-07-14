#Function to deploy a fresh Active Directory forest.

function ADDS () {
    
[CmdletBinding()]
    param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            HelpMessage="Provide the desired domain name for the forest.")]
        [ValidateLength(1,15)]
        [ValidatePattern('[a-z][A-Z][.]')]
        [ValidateNotNullOrEmpty()] 
        [String]$DomainName,
    
        [Parameter(
            Position=1,
            Mandatory=$true,
            HelpMessage="Enter the corresponding index for the network interface that will be used with AD. (Get-WmiObject -Class win32_networkadapterconfiguration)")]
        [ValidatePattern('[0-9]')]
        [ValidateScript({
            if ($Index.DHCPEnabled -eq "True") {
                Write-Warning -Message "The IP address of the interface is not set to static. Disable DHCP before installing this feature."
                break
            }
            return $true
        })]
        [ValidateNotNullOrEmpty()] 
        [Int32]$Index
    )
    
    $OsInfo = Get-CimInstance -ClassName "Win32_OperatingSystem"

    switch ($OsInfo.ProductType) {
        "1" {Write-Warning -Message "The current OS is a workstation. Unable to install ADDS."; break}
        "2" {Write-Warning -Message "The current OS is a domain controller. Unable to install ADDS."; break}
        "3" {
            Write-Host -ForegroundColor Cyan "The current OS is a server. Proceeding to ADDS installation."
            $features = @("AD-Domain-Services","DNS")
            foreach ($feature in $features) {
                Install-WindowsFeature -Name "$($feature)" -IncludeManagementTools
            }

            try {
                Install-ADDSForest `
                -SkipPreChecks `
                -CreateDnsDelegation:$false `
                -DatabasePath "C:\Windows\NTDS" `
                -DomainMode "WinThreshold" `
                -DomainName "$DomainName"`
                -ForestMode "WinThreshold" `
                -InstallDns:$true `
                -LogPath "C:\Windows\NTDS" `
                -NoRebootOnCompletion:$false `
                -SysvolPath "C:\Windows\SYSVOL" `
                -Force:$true
            }

            catch {
                Write-Warning -Message "Could not complete the forest installation."
                break
            }
        }
        default {"This value is not supported."; break}
    }
}
