function Expand-PSDependArchive {
    [CmdletBinding()]
    param (
        [String]
        $Path,

        [String]
        $DestinationPath,

        [Switch]
        $Force
    )

    end {
        # Use Windows unzip method as otherwise Expand-Archive exists and that runs on all platforms
        if ($null -eq $(Get-Command -Name Expand-Archive -ErrorAction SilentlyContinue)) {
            Write-Verbose "Extracting using legacy unzip method"
            $ZipFile = (New-Object -com shell.application).NameSpace($Path)
            $ZipDestination = (New-Object -com shell.application).NameSpace($DestinationPath)
            $ZipDestination.CopyHere($ZipFile.Items())
        }
        else {
            Write-Verbose "Extracting using current Expand-Archive function"
            Expand-Archive -Path $Path -DestinationPath $DestinationPath -Force:$Force
        }
    }
}