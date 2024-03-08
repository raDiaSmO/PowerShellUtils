function BeatsInstaller {

[CmdletBinding()]
    param (
        [Parameter(
        Position=0,
        HelpMessage="Provide a path containing the packages to install.")]
        [ValidateScript({
            if (!(Test-Path $_)) {
                Write-Warning -Message "The provided path $($_) does not exist."
                break
            }
            if (!(Test-Path $_ -PathType Container)) {
                Write-Warning -Message "The provided path $($_) needs to be a folder."
                break
            }
            return $true
        })]
        [ValidateNotNullOrEmpty()] 
        [System.IO.FileInfo]$Path = "$($env:SystemDrive)\Elk\Beats",

        [Parameter(
        Position=1,
        HelpMessage="Provide the desired beats agents to be installed.")]
        [ValidateScript({
            $ExistingBeats = @("auditbeat","filebeat","metricbeat","packetbeat","winlogbeat","heartbeat","functionbeat")
            if (!($ExistingBeats.Contains($_))) {
                Write-Warning -Message "The provided beat $($_) does not exist."
                break
            }
            return $true
        })]
        [ValidateNotNullOrEmpty()] 
        [Array]$Beats = @("auditbeat","filebeat","metricbeat","packetbeat","winlogbeat"),

        [Parameter(
        Position=2,
        Mandatory=$true,
        HelpMessage="Provide the installation version with the following format (x.y.z).")]
        [ValidateNotNullOrEmpty()] 
        [String]$Version = "8.2.2"
    )

    foreach ($Beat in $Beats) {
        $WorkDir = "$($Path)\$($Beat)-$($Version)-windows-x86_64"
        $Folders = @("$env:ProgramData\$($Beat)","$env:ProgramData\$($Beat)\logs")

        if (!(Test-Path -Path $WorkDir)) {
            Write-Warning -Message "The following Beats packages are not found $($WorkDir)."
            break
        }

        if (Get-ChildItem -Path "$($Path)" -ErrorAction SilentlyContinue | ? {$_.Extension -eq ".ZIP"}) {
            Expand-Archive -Path "$($WorkDir).zip" -DestinationPath $Path
            Remove-Item -Path "$($WorkDir).zip" -Force
        }
 
        if (Get-Service -DisplayName $($Beat) -ErrorAction SilentlyContinue) {
            $service = Get-WmiObject -Class Win32_Service -Filter "name='$($Beat)'"
            Start-Job -ScriptBlock {$service.StopService()} | Wait-Job
            $service.delete()
        }

        foreach ($Folder in $Folders) {
            if (!(Test-Path -Path $Folder)) {
                New-Item -ItemType Directory $Folder
            }
        }

        New-Service -name $($Beat) `
        -displayName $($Beat) `
        -binaryPathName "`"$WorkDir\$($Beat).exe`" `
        -c `"$WorkDir\$($Beat).yml`" `
        -path.home `"$WorkDir`" `
        -path.data `"$env:ProgramData\$($Beat)`" `
        -path.logs `"$env:ProgramData\$($Beat)\logs`""

        try {
            Start-Process -FilePath sc.exe -ArgumentList "config $($Beat) start=delayed-auto" -Wait -Verbose
        }
        
        catch { 
            Write-Warning -Message "Could not execute the following request."
            break
        }
    }
}
