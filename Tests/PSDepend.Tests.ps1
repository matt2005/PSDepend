
BeforeAll {

    if(-not $ENV:BHProjectPath)
    {
        Set-BuildEnvironment -Path $PSScriptRoot\..
    }
    Remove-Module $ENV:BHProjectName -ErrorAction SilentlyContinue
    Import-Module (Join-Path $ENV:BHProjectPath $ENV:BHProjectName) -Force

    $PSVersion = $PSVersionTable.PSVersion.Major

    # Verbose output for non-master builds on appveyor
    # Handy for troubleshooting.
    # Splat @Verbose against commands as needed (here or in pester tests)
        $Verbose = @{}
        if($ENV:BHBranchName -notlike "master" -or $env:BHCommitMessage -match "!verbose")
        {
            $Verbose.add("Verbose",$True)
        }

    $TestDepends = Join-Path $ENV:BHProjectPath Tests\DependFiles
}

Describe "$ENV:BHProjectName PS$PSVersion" {
    Context 'Strict mode' {
        BeforeAll {
            Set-StrictMode -Version latest
        }

        It 'Should load' {
            $Module = Get-Module $ENV:BHProjectName
            $Module.Name | Should -Be $ENV:BHProjectName
            $Module.ExportedFunctions.Keys -contains 'Get-Dependency' | Should -Be $True
        }
    }
}

Describe "Get-Dependency PS$PSVersion" {
    Context 'Strict mode' {
        BeforeAll {
            Set-StrictMode -Version latest
        }

        It 'Should read ModuleName=Version syntax' {
            $Dependencies = Get-Dependency -Path $TestDepends\simple.depend.psd1
            $Dependencies.Count | Should -Be 4
            @( $Dependencies.DependencyType -like 'PSGalleryModule' ).count | Should -Be 4
            @( $Dependencies | Where {$_.Name -like $_.DependencyName} ).count | Should -Be 4
        }

        It 'Should read DependencyType::DependencyName=Version syntax' {
            $Dependencies = Get-Dependency -Path $TestDepends\simple.helpers.depend.psd1
            $Dependencies.Count | Should -Be 2
            @( $Dependencies.DependencyType -like 'PSGalleryModule' ).count | Should -Be 1
            @( $Dependencies.DependencyType -like 'GitHub' ).count | Should -Be 1
            @( $Dependencies | Where {$_.Name -like $_.DependencyName} ).count | Should -Be 2
        }

        It 'Should read each property correctly' {
            $Dependencies = Get-Dependency -Path $TestDepends\allprops.depend.psd1
            @( $Dependencies ).count | Should -Be 1
            $Dependencies.DependencyName | Should -Be 'DependencyName'
            $Dependencies.Name | Should -Be 'Name'
            $Dependencies.Version | Should -Be 'Version'
            $Dependencies.DependencyType | Should -Be 'noop'
            $Dependencies.Parameters.ContainsKey('Random') | Should -Be $True
            $Dependencies.Parameters['Random'] | Should -Be 'Value'
            $Dependencies.Source | Should -Be 'Source'
            $Dependencies.Target | Should -Be 'Target'
            $Dependencies.AddToPath | Should -Be $True
            $Dependencies.Tags.Count | Should -Be 2
            $Dependencies.Tags -contains 'tags' | Should -Be $True
            $Dependencies.DependsOn | Should -Be 'DependsOn'
            $Dependencies.PreScripts | Should -Be 'C:\PreScripts.ps1'
            $Dependencies.PostScripts | Should -Be 'C:\PostScripts.ps1'
            $Dependencies.Raw.ContainsKey('ExtendedSchema') | Should -Be $True
            $Dependencies.Raw.ExtendedSchema['IsTotally'] | Should -Be 'Captured'
        }

        It 'Should handle DependsOn' {
            $Dependencies = Get-Dependency -Path $TestDepends\dependson.depend.psd1
            @( $Dependencies ).count | Should -Be 3
            $Dependencies[0].DependencyName | Should -Be 'One'
            $Dependencies[1].DependencyName | Should -Be 'Two'
            $Dependencies[2].DependencyName | Should -Be 'THree'
        }

        It 'Should inject variables' {
            $Dependencies = Get-Dependency -Path $TestDepends\inject.variables.depend.psd1
            $DependencyFolder = Split-Path $Dependencies.DependencyFile -Parent
            $Dependencies.Source | Should -Be "PWD=$($PWD.Path)"
            $Dependencies.Target | Should -Be "$($PWD.Path)\Dependencies;$DependencyFolder"
        }

        It 'Should not mangle dependencies if multiple PSGallery modules specified' {
            $Dependencies = Get-Dependency -Path $TestDepends\multiplepsgallerymodule.depend.psd1
            $Dependencies.Count | Should -Be 3
            $Dependencies[0].Version | Should -BeNullOrEmpty
            $Dependencies[1].Version | Should -BeNullOrEmpty
            $Dependencies[2].Version | Should -BeNullOrEmpty
            @($Dependencies[0].Tags) -contains 'prd' | Should -Be $True
            @($Dependencies[1].Tags) -contains 'prd' | Should -Be $True
            @($Dependencies[2].Tags) -contains 'prd' | Should -Be $True
        }
    }
}