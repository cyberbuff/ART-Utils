function Install-CTIFolder {

    <#
        #TODO: Have to integrate this into Install-Atomics Folder
    .SYNOPSIS
        This is a simple script to download the atttack definitions in the "CTI" folder of the MITRE.
    .PARAMETER DownloadPath
        Specifies the desired path to download CTI zip archive to.
    .PARAMETER InstallPath
        Specifies the desired path for where to unzip the CTI folder.
    .PARAMETER Force
        Delete the existing CTI folder before installation if it exists.
    .EXAMPLE
        Install CTI folder
        PS> Install-CTIFolder.ps1
    .NOTES
        Use the '-Verbose' option to print detailed information.
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False, Position = 0)]
        [string]$InstallPath = $( if ($IsLinux -or $IsMacOS) { $Env:HOME + "/AtomicRedTeam" } else { $env:HOMEDRIVE + "\AtomicRedTeam" }),

        [Parameter(Mandatory = $False, Position = 1)]
        [string]$DownloadPath = $InstallPath,

        [Parameter(Mandatory = $False, Position = 2)]
        [string]$RepoOwner = "mitre",

        [Parameter(Mandatory = $False, Position = 3)]
        [string]$Branch = "master",

        [Parameter(Mandatory = $False)]
        [switch]$Force = $False # delete the existing install directory and reinstall
    )
    Try {
        $InstallPathwCTI = Join-Path $InstallPath "cti"
        if ($Force -or -Not (Test-Path -Path $InstallPathwCTI )) {
            write-verbose "Directory Creation"
            if ($Force) {
                Try {
                    if (Test-Path $InstallPathwCTI) { Remove-Item -Path $InstallPathwCTI -Recurse -Force -ErrorAction Stop | Out-Null }
                }
                Catch {
                    Write-Host -ForegroundColor Red $_.Exception.Message
                    return
                }
            }
            if (-not (Test-Path $InstallPath)) { New-Item -ItemType directory -Path $InstallPath | Out-Null }

            $url = "https://github.com/$RepoOwner/cti/archive/$Branch.zip"
            $path = Join-Path $DownloadPath "$Branch.zip"
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            write-verbose "Beginning download of CTI folder from Github"
            Invoke-WebRequest $url -OutFile $path

            write-verbose "Extracting ART to $InstallPath"
            $zipDest = Join-Path "$DownloadPath" "tmp"
            expand-archive -LiteralPath $path -DestinationPath "$zipDest" -Force:$Force
            $ctiFolderUnzipped = Join-Path (Join-Path $zipDest "cti-$Branch") "*"
            Move-Item -Path $ctiFolderUnzipped -Destination (Join-Path $InstallPath "cti")
            Remove-Item $zipDest -Recurse -Force
            Remove-Item $path

        }
        else {
            Write-Host -ForegroundColor Yellow "An CTI folder already exists at $InstallPathwCTI. No changes were made."
            Write-Host -ForegroundColor Cyan "Try the install again with the '-Force' parameter if you want to delete the existing installion and re-install."
            Write-Host -ForegroundColor Red "Warning: All files within the atomics folder ($InstallPathwCTI) will be deleted when using the '-Force' parameter."
        }
    }
    Catch {
        Write-Host -ForegroundColor Red "CTI Download Failed."
        Write-Host $_.Exception.Message`n
    }
}
