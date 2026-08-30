<#
.SYNOPSIS
    Pester tests for os_information_cooperlane.ps1 and its module scripts.

.NOTES
    Author : Cooper Lane
    Run with: Invoke-Pester .\os_information_cooperlane.Tests.ps1

    Two things differ from the supplied template.

    1. The master script is dot-sourced twice on purpose. Pester 4 runs the file
       body and ignores a file-level BeforeAll, while Pester 5 requires the
       BeforeAll. Loading the script in both places lets this one file run under
       either version. Dot-sourcing also imports the modules.

    2. Mocks for commands called from inside a module script must name that module
       with -ModuleName. A mock created in the test session cannot be seen from
       inside a module's own scope. The menu functions live in the master script,
       so their mocks do not need it.
#>

. (Join-Path -Path $PSScriptRoot -ChildPath 'os_information_cooperlane.ps1')

BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'os_information_cooperlane.ps1')
}

Describe "Get-ClientComputerInformation" {

    BeforeAll {
        Mock Get-ComputerInfo -ModuleName 'Get-ClientComputerInformation' {
            return @{ OsName = 'Windows 11' }
        }
    }

    It "Returns computer property when valid parameter provided" {
        $result = Get-ClientComputerInformation -PropertyName 'OsName'
        $result | Should -Not -BeNullOrEmpty
    }

    It "Calls Get-ComputerInfo with correct property" {
        Get-ClientComputerInformation -PropertyName 'OsName'
        Assert-MockCalled Get-ComputerInfo -ModuleName 'Get-ClientComputerInformation' `
            -ParameterFilter { $Property -eq 'OsName' } -Times 1
    }

    It "Returns error when exception occurs" {
        Mock Get-ComputerInfo -ModuleName 'Get-ClientComputerInformation' { throw 'Failure' }
        $result = Get-ClientComputerInformation -PropertyName 'OsName'
        $result | Should -Match 'Error:'
    }

    Context "Out of scope input" {

        It "Throws when the property name is null" {
            { Get-ClientComputerInformation -PropertyName $null } | Should -Throw
        }

        It "Throws when the property name is an empty string" {
            { Get-ClientComputerInformation -PropertyName '' } | Should -Throw
        }

        It "Returns error text when the property does not exist" {
            Mock Get-ComputerInfo -ModuleName 'Get-ClientComputerInformation' { throw 'Invalid property' }
            $result = Get-ClientComputerInformation -PropertyName 'NotARealProperty'
            $result | Should -Match 'Error:'
        }
    }
}

Describe "Get-AllClientComputerInformation" {

    BeforeAll {
        Mock Get-ComputerInfo -ModuleName 'Get-AllClientComputerInformation' {
            return @{ OsName = 'Windows 11'; OsArchitecture = '64-bit' }
        }
        Mock Get-RemoteServiceStatus -ModuleName 'Get-AllClientComputerInformation' {
            return 'Running'
        }
        Mock Get-TrustedHost -ModuleName 'Get-AllClientComputerInformation' {
            return 'No trusted hosts are configured on this computer.'
        }
    }

    It "Returns formatted computer information" {
        $result = Get-AllClientComputerInformation
        $result | Should -Not -BeNullOrEmpty
    }

    It "Calls Get-ComputerInfo once" {
        Get-AllClientComputerInformation
        Assert-MockCalled Get-ComputerInfo -ModuleName 'Get-AllClientComputerInformation' -Times 1
    }

    It "Returns error string on failure" {
        Mock Get-ComputerInfo -ModuleName 'Get-AllClientComputerInformation' { throw 'Failure' }
        $result = Get-AllClientComputerInformation
        $result | Should -Match 'Error:'
    }
}

Describe "Get-RemoteServiceStatus" {

    It "Returns the service status when the service is found" {
        Mock Get-Service -ModuleName 'Get-RemoteServiceStatus' { return @{ Status = 'Running' } }
        $result = Get-RemoteServiceStatus
        $result | Should -Be 'Running'
    }

    It "Returns error string when the service is not found" {
        Mock Get-Service -ModuleName 'Get-RemoteServiceStatus' {
            throw 'Cannot find any service with service name WinRM'
        }
        $result = Get-RemoteServiceStatus
        $result | Should -Match 'Error:'
    }
}

Describe "Get-TrustedHost" {

    It "Returns the trusted hosts when they are configured" {
        Mock Get-Item -ModuleName 'Get-TrustedHost' { return @{ Value = 'host1,host2' } }
        $result = Get-TrustedHost
        $result | Should -Be 'host1,host2'
    }

    Context "Out of scope input" {

        It "Returns a message when the value is an empty string" {
            Mock Get-Item -ModuleName 'Get-TrustedHost' { return @{ Value = '' } }
            $result = Get-TrustedHost
            $result | Should -Match 'No trusted hosts'
        }

        It "Returns a message when the value is whitespace" {
            Mock Get-Item -ModuleName 'Get-TrustedHost' { return @{ Value = '   ' } }
            $result = Get-TrustedHost
            $result | Should -Match 'No trusted hosts'
        }

        It "Returns a message when the value is null" {
            Mock Get-Item -ModuleName 'Get-TrustedHost' { return @{ Value = $null } }
            $result = Get-TrustedHost
            $result | Should -Match 'No trusted hosts'
        }
    }

    It "Returns error string when WSMan cannot be read" {
        Mock Get-Item -ModuleName 'Get-TrustedHost' { throw 'Cannot find path' }
        $result = Get-TrustedHost
        $result | Should -Match 'Error:'
    }
}

Describe "Show-Menu" {

    It "Displays menu options" {
        Mock Write-Output {}
        Show-Menu
        Assert-MockCalled Write-Output -Times 10
    }
}

Describe "Invoke-OSInformationMenu" {

    BeforeEach {
        Mock Show-Menu {}
        Mock Write-Output {}
        Mock Write-Host {}
        Mock Get-ClientComputerInformation { return 'MockedValue' }
        Mock Get-AllClientComputerInformation { return 'AllInfo' }
        Mock Get-RemoteServiceStatus { return 'Running' }
        Mock Get-TrustedHost { return 'None' }
        $script:readHostCalls = 0
    }

    Context "Valid selections" {

        It "Handles option 1" {
            # The template mock returned '1' every time, which loops forever.
            # Returning '1' then '9' exercises the option and then exits.
            Mock Read-Host {
                $script:readHostCalls++
                if ($script:readHostCalls -eq 1) { return '1' } else { return '9' }
            }
            Invoke-OSInformationMenu
            Assert-MockCalled Get-ClientComputerInformation -Times 1
        }

        It "Handles option 8" {
            Mock Read-Host {
                $script:readHostCalls++
                if ($script:readHostCalls -eq 1) { return '8' } else { return '9' }
            }
            Invoke-OSInformationMenu
            Assert-MockCalled Get-AllClientComputerInformation -Times 1
        }

        It "Handles option 6 by calling the trusted host module" {
            Mock Read-Host {
                $script:readHostCalls++
                if ($script:readHostCalls -eq 1) { return '6' } else { return '9' }
            }
            Invoke-OSInformationMenu
            Assert-MockCalled Get-TrustedHost -Times 1
        }
    }

    Context "Invalid selections" {

        It "Prompts again on invalid high input" {
            Mock Read-Host {
                $script:readHostCalls++
                if ($script:readHostCalls -eq 1) { return '10' } else { return '9' }
            }
            Invoke-OSInformationMenu
            Assert-MockCalled Show-Menu -Times 2
        }

        It "Prompts again when a letter is entered" {
            Mock Read-Host {
                $script:readHostCalls++
                if ($script:readHostCalls -eq 1) { return 'abc' } else { return '9' }
            }
            Invoke-OSInformationMenu
            Assert-MockCalled Show-Menu -Times 2
        }

        It "Prompts again when nothing is entered" {
            Mock Read-Host {
                $script:readHostCalls++
                if ($script:readHostCalls -eq 1) { return '' } else { return '9' }
            }
            Invoke-OSInformationMenu
            Assert-MockCalled Show-Menu -Times 2
        }

        It "Prompts again when zero is entered" {
            Mock Read-Host {
                $script:readHostCalls++
                if ($script:readHostCalls -eq 1) { return '0' } else { return '9' }
            }
            Invoke-OSInformationMenu
            Assert-MockCalled Show-Menu -Times 2
        }

        It "Does not call a retrieval function on invalid input" {
            Mock Read-Host {
                $script:readHostCalls++
                if ($script:readHostCalls -eq 1) { return 'x' } else { return '9' }
            }
            Invoke-OSInformationMenu
            Assert-MockCalled Get-ClientComputerInformation -Times 0
        }
    }

    Context "Exit condition" {

        It "Exits when user selects 9" {
            Mock Read-Host { return '9' }
            { Invoke-OSInformationMenu } | Should -Not -Throw
        }
    }
}

Describe "Module structure" {

    It "Imports all four required module scripts" {
        $expectedModules = @(
            'Get-ClientComputerInformation',
            'Get-RemoteServiceStatus',
            'Get-TrustedHost',
            'Get-AllClientComputerInformation'
        )
        foreach ($expectedModule in $expectedModules) {
            Get-Module -Name $expectedModule | Should -Not -BeNullOrEmpty
        }
    }

    It "Exports each function from its own module" {
        (Get-Command Get-TrustedHost).ModuleName | Should -Be 'Get-TrustedHost'
        (Get-Command Get-RemoteServiceStatus).ModuleName | Should -Be 'Get-RemoteServiceStatus'
    }
}
