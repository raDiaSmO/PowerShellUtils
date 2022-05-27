#Function to scan ports onto a given IP.

function PortScan () {

[CmdletBinding()]
    param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            HelpMessage="Enter the target IP adress.")]
        [ValidatePattern('[0-9]')]
        [ValidateNotNullOrEmpty()] 
        [String]$IP,

        [Parameter(
            Position=1,
            Mandatory=$true,
            HelpMessage='Enter the first port to scan.')]
        [ValidateRange(1,65535)]
        [ValidateNotNullOrEmpty()] 
        [Int32]$StartPort,

        [Parameter(
            Position=2,
            Mandatory=$true,
            HelpMessage='Enter the last port to scan.')]
        [ValidateRange(1,65535)]
        [ValidateScript({
            if($_ -lt $StartPort){
                Write-Warning -Message "Incorrect range provided."
                break
            }
            return $true
        })]
        [ValidateNotNullOrEmpty()] 
        [Int32]$EndPort,

        [Parameter(
            Position=3,
            Mandatory=$true,
            HelpMessage="Provide a path to output the resulting data.")]
        [ValidateScript({
        if (!(Test-Path $_)) {
            Write-Warning -message "The output path $($_) does not exist."
            break
        }
        return $true
        })]
        [ValidatePattern('[a-z][A-Z]')]
        [ValidateNotNullOrEmpty()] 
        [System.IO.FileInfo]$OutputPath
    )

    if (!(Test-Connection -ComputerName $($IP) -BufferSize 32 -Count 1 -Quiet)) {
        Write-Warning -Message "$($IP) is not reachable."
        break
    }

    $ErrorActionPreference = "SilentlyContinue"
    $Ports = @($($StartPort)..$($EndPort))
    foreach ($port in $ports) {
    
        if (Test-Connection -BufferSize 32 -Count 1 -Quiet -ComputerName "$($ip)") {
            $socket = New-Object System.Net.Sockets.TcpClient("$($ip)", "$($port)") 
            
            if ($socket.Connected) {
                Write-Host -ForegroundColor Cyan "Port $($port) is open on $($ip)."
                Write-Output "Port $($port) is open on $($ip)." >> "$($OutputPath)\PortScanResults.txt"
                $socket.Close()
            }
            
            else {
                Write-Warning -Message "Port $($port) is not open on $($ip)."
            }
        }
    }
}
