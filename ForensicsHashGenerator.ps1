function GetHash {

[CmdletBinding()]
    param (
        [Parameter(
        Position=0,
        Mandatory=$true,
        HelpMessage="Provide a path containing files to analyze.")]
        [ValidateScript({
            if (!(Test-Path $_)) {
                Write-Warning -message "The provided path $($_) does not exist."
                break
            }
            if (!(Test-Path $_ -PathType Container)) {
                Write-Warning -message "The provided path $($_) needs to be a container (Folder or registry)."
                break
            }
            return $true
        })]
        [ValidateNotNullOrEmpty()] 
        [System.IO.FileInfo]$Path,
        
        [Parameter(
        Position=1,
        Mandatory=$true,
        HelpMessage="Provide a path to output the resulting data.")]
        [ValidateScript({
            if (!(Test-Path $_)) {
                Write-Warning -message "The output path $($_) does not exist."
                break
            }
            if (Test-Path $Path) {
                Write-Warning -message "The output path needs to be different from the working directory ($($path))."
                break
            }
            return $true
        })]
        [ValidateNotNullOrEmpty()] 
        [System.IO.FileInfo]$OutputPath
    )

    try {
        Start-Transcript -Path "$($OutputPath)/HashValues.txt"
        Set-Location -Path $Path
        $Hashs = Get-ChildItem -Path ./
        $Algorithms = @("MD5","SHA1")
        $date = date
        foreach ($Hash in $Hashs) {
            foreach ($Algorithm in $Algorithms) {
                $HashValue = Get-FileHash -Path $Hash.Name -Algorithm $Algorithm
                $Data = Write-Host " `b `b File = $($Hash.name) `n `b `b Hash = $($HashValue.Hash) `n `b `b Algorithm = $($HashValue.algorithm) `n `b `b Date = $($date) ==============================================================="
            }
        }
        Stop-Transcript
    }
    
    catch {
        Write-Warning -Message "Could not execute the following request."
        break
    }
    return $Data
}
