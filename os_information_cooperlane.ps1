<#
.SYNOPSIS
    Gathers operating system and hardware information from an ITWorks client computer.

.DESCRIPTION
    This is the master script. It imports the retrieval modules from the Modules
    folder, displays a menu, and calls the matching module function for the option
    the user selects. The menu repeats until the user selects option 9.

.NOTES
    Author  : Cooper Lane
    Company : ITWorks
    Version : 2.0
    Standard: ITWorks_PowerShell_Coding_Standards

    Required modules, in the Modules folder beside this script:
        Get-ClientComputerInformation.psm1
        Get-RemoteServiceStatus.psm1
        Get-TrustedHost.psm1
        Get-AllClientComputerInformation.psm1

    This script is safe to dot-source. Dot-sourcing imports the modules and loads
    the menu functions for Pester testing without starting the interactive menu.
#>

[CmdletBinding()]
param()

begin {

    # ---------------------------------------------------------------------------
    # Import the module scripts that provide the information retrieval functions.
    # ---------------------------------------------------------------------------
    $modulesFolder = Join-Path -Path $PSScriptRoot -ChildPath 'Modules'

    $requiredModules = @(
        'Get-ClientComputerInformation',
        'Get-RemoteServiceStatus',
        'Get-TrustedHost',
        'Get-AllClientComputerInformation'
    )

    foreach ($requiredModule in $requiredModules) {
        $modulePath = Join-Path -Path $modulesFolder -ChildPath "$requiredModule.psm1"

        try {
            Import-Module -Name $modulePath -Force -ErrorAction Stop
        }
        catch {
            Write-Output "Error: Unable to import the module '$requiredModule' - $($_.Exception.Message)"
        }
    }

    function Show-Menu {
        <#
        .SYNOPSIS
            Displays the OS information menu options on screen.
        #>
        [CmdletBinding()]
        param()

        try {
            # Ten lines are written: one heading plus the nine menu options.
            Write-Output '===== ITWorks Client OS Information Tool ====='
            Write-Output '1. Operating system'
            Write-Output '2. Windows remote (WinRM) service status'
            Write-Output '3. Computer manufacturer and model'
            Write-Output '4. Computer name'
            Write-Output '5. Computer domain name'
            Write-Output '6. Computer trusted hosts'
            Write-Output '7. Operating system architecture'
            Write-Output '8. Get all the above information'
            Write-Output '9. Quit'
        }
        catch {
            Write-Output "Error: Unable to display the menu - $($_.Exception.Message)"
        }
    }

    function Invoke-OSInformationMenu {
        <#
        .SYNOPSIS
            Runs the interactive menu loop until the user selects option 9.
        .DESCRIPTION
            Displays the menu, reads the user selection, validates that the selection
            is a whole number between 1 and 9, and calls the module function that
            matches the selection. Invalid input is rejected and the menu is
            displayed again.
        #>
        [CmdletBinding()]
        param()

        $exitRequested = $false

        while (-not $exitRequested) {

            try {
                Show-Menu
                $userChoice = Read-Host -Prompt 'Please select an option (1-9)'

                # Only a single digit from 1 to 9 is accepted. Letters, blanks,
                # decimals and numbers such as 10 or 0 all fail this test.
                if ($userChoice -notmatch '^[1-9]$') {
                    Write-Output 'Invalid selection. Please enter a whole number between 1 and 9.'
                }
                else {
                    switch ($userChoice) {
                        '1' { Write-Output (Get-ClientComputerInformation -PropertyName 'OsName') }
                        '2' { Write-Output (Get-RemoteServiceStatus) }
                        '3' {
                            $hardwareProperties = @('CsManufacturer', 'CsModel')
                            Write-Output (Get-ClientComputerInformation -PropertyName $hardwareProperties)
                        }
                        '4' { Write-Output (Get-ClientComputerInformation -PropertyName 'CsName') }
                        '5' { Write-Output (Get-ClientComputerInformation -PropertyName 'CsDomain') }
                        '6' { Write-Output (Get-TrustedHost) }
                        '7' { Write-Output (Get-ClientComputerInformation -PropertyName 'OsArchitecture') }
                        '8' { Write-Output (Get-AllClientComputerInformation) }
                        '9' { $exitRequested = $true }
                    }
                }
            }
            catch {
                # An unexpected error is reported but does not stop the menu.
                Write-Output "Error: An unexpected error occurred - $($_.Exception.Message)"
            }
        }
    }
}

process {

    # The menu only starts when the script is run directly. Dot-sourcing the script
    # (for example from the Pester test file) loads everything without running it.
    if ($MyInvocation.InvocationName -ne '.') {
        Invoke-OSInformationMenu
    }
}

end {
}
