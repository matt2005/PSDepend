function Get-InstalledTerraformVersion {
    param(
        [string] $VersionRegex = "(?<version>\d+\.\d+.\d+)(-(?<prereleasetag>.+)){0,1}$"
    )
    end {
        # We don't check the whole fs for TF, either its on the path at the version we want already
        # or we put the version we want where the build wants it

        # We add current location to the path as the first entry to search for the terraform command. To not do this would
        # result in an output message that can't be avoided which we don't want or care about
        # We assume that if the client installs tf into the current directory (i.e. doesn't specify a target dir)
        # then they are happy to cater for the ./<cmd> requirement for pwsh to run the binary properly
        $PATH_BACKUP = $env:PATH
        Add-ToItemCollection -Reference Env:\Path -Item (Get-Location)
        $IsInstalled = (Get-Command terraform -ErrorAction SilentlyContinue)
        if ($IsInstalled) {
            $g = ((terraform --version)[0] | Select-String -Pattern $VersionRegex).Matches.Groups
            $env:PATH = $PATH_BACKUP
            $VersionCore = ($g | Where-Object Name -EQ "Version").Value
            $PreRelease = ($g | Where-Object Name -EQ "PreReleaseTag").Value
            return ([psobject]@{
                    IsInstalled  = $true
                    Version      = "{0}{1}" -f $VersionCore, $PreReleaseTag
                    VersionCore  = $VersionCore
                    PreRelease   = $PreRelease
                    IsPreRelease = ($null -ne $PreRelease ? $true : $false)
                })
        }
        else {
            $env:PATH = $PATH_BACKUP
            return ([psobject]@{
                    IsInstalled  = $false
                    IsPreRelease = $false
                })
        }
    }
}