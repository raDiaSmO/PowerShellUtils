function ADDS () {

[CmdletBinding()]
    param(
        [Parameter(
        Position=0,
        Mandatory=$true,
        HelpMessage="Provide the desired domain name for the forest.")]
        [ValidateLength(1,15)]
        [ValidateNotNullOrEmpty()]
        [String]$DomainName,

        [Parameter(
        Position=1,
        Mandatory=$true,
        HelpMessage="Enter the corresponding index for the network interface that will be used with AD. (Get-WmiObject -Class win32_networkadapterconfiguration)")]
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
        default {"This value is not supported."; break}
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
                Write-Warning -Message "Could not execute the following request."
                break
            }
        }
    }
}

function DHCP () {

[CmdletBinding()]
    param(
        [Parameter(
        Position=0,
        HelpMessage="Provide the name for the DHCP pool.")]
        [ValidateNotNullOrEmpty()]
        [String]$DhcpPool="HomeLabAdPool",

        [Parameter(
        Position=1,
        HelpMessage="Provide the start range for the pool.")]
        [ValidateNotNullOrEmpty()]
        [String]$StartRange="172.16.0.2",

        [Parameter(
        Position=2,
        HelpMessage="Provide the end range for the pool.")]
        [ValidateNotNullOrEmpty()]
        [String]$EndRange="172.16.0.6",

        [Parameter(
        Position=3,
        HelpMessage="Provide the subnet mask for the pool.")]
        [ValidateNotNullOrEmpty()]
        [String]$Subnet="255.255.255.248",

        [Parameter(
        Position=4,
        HelpMessage="Provide the DNS server option for the pool.")]
        [ValidateNotNullOrEmpty()]
        [String]$DnsServer="172.16.0.1",

        [Parameter(
        Position=5,
        HelpMessage="Provide the domain name option for the pool.")]
        [ValidateNotNullOrEmpty()]
        [String]$DomainName="homelab.local"
    )

    try {
        $DcInfo = Get-ADDomainController
        Install-WindowsFeature -Name DHCP -IncludeManagementTools
        Import-Module DhcpServer
        Add-DhcpServerInDc -DnsName $DcInfo.HostName
        Add-DhcpServerv4Scope -Name $DhcpPool -StartRange $StartRange -EndRange $EndRange -SubnetMask $Subnet
        Set-DhcpServerv4OptionValue -DnsServer $DnsServer -DnsDomain $DomainName
    }

    catch {
        Write-Warning -Message "Could not execute the following request."
        break
    }
}
