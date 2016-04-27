. (Join-Path $PSScriptRoot '../TestCommon.ps1')

$exportedCommands = (Get-Command -Module $Script:ModuleName)
$expectedCommands = Import-Csv -Path (Join-Path $PSScriptRoot 'expected_commands.csv')

Describe "$($Script:ModuleName) Module" {
    It "ModuleName Should be set" {
        $Script:ModuleName | Should Not BeNullOrEmpty
    }

    It "Should be loaded" {
        Get-Module $Script:ModuleName | Should Not BeNullOrEmpty
    }
}

Describe 'Exported commands' {
    # Test if the exported command is expected
    Foreach ($command in $exportedCommands)
    {
        Context $command {
            It 'Should be an expected command' {
                $expectedCommands.Name -contains $command.Name | Should Be $true
            }

            It 'Should have proper help' {
                $help = Get-Help $command.Name
                $help.description | Should Not BeNullOrEmpty
                $help.Synopsis | Should Not BeNullOrEmpty
                $help.examples | Should Not BeNullOrEmpty
            }
        }
    }
}

Describe 'Expected commands' {
    # Test if the expected command is exported
    Foreach ($command in $expectedCommands)
    {
        Context $command.Name {
            It 'Should be an exported command' {
                $exportedCommands.Name -contains $command.Name | Should Be $true
            }
        }
    }
}
