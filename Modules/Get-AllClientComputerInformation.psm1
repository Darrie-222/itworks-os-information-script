<#
.SYNOPSIS
    Module script providing Get-AllClientComputerInformation.

.NOTES
    Author  : Cooper Lane
    Company : ITWorks
    Version : 1.0

    This module depends on Get-RemoteServiceStatus.psm1 and Get-TrustedHost.psm1.
    They are imported below so this module also works when loaded on its own.
#>

# Import the two modules this one depends on. Import-Module does not reload a
# module that is already loaded, so this is safe when the master script has
# already imported them.
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Get-RemoteServiceStatus.psm1')
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Get-TrustedHost.psm1')

function Get-AllClientComputerInformation {
    <#
    .SYNOPSIS
        Retrieves every item of information offered by the menu and returns a list.
    .DESCRIPTION
        Makes a single call to Get-ComputerInfo for all required properties, then
        adds the WinRM service status and the trusted hosts, and returns the combined
        result formatted as a list. On failure the function returns a string
        beginning with "Error:".
    .EXAMPLE
        Get-AllClientComputerInformation
    #>
    [CmdletBinding()]
    param()

    try {
        $requiredProperties = @(
            'OsName',
            'OsVersion',
            'CsManufacturer',
            'CsModel',
            'CsName',
            'CsDomain',
            'OsArchitecture'
        )

        # One call retrieves every property, which is faster than seven calls.
        $computerInfo = Get-ComputerInfo -Property $requiredProperties -ErrorAction Stop

        $allInformation = [ordered]@{
            'Operating System'     = $computerInfo.OsName
            'OS Version'           = $computerInfo.OsVersion
            'WinRM Service Status' = Get-RemoteServiceStatus
            'Manufacturer'         = $computerInfo.CsManufacturer
            'Model'                = $computerInfo.CsModel
            'Computer Name'        = $computerInfo.CsName
            'Domain Name'          = $computerInfo.CsDomain
            'Trusted Hosts'        = Get-TrustedHost
            'OS Architecture'      = $computerInfo.OsArchitecture
        }

        # Format-List presents the results one item per line as required.
        return ([pscustomobject]$allInformation | Format-List | Out-String)
    }
    catch {
        return "Error: Unable to gather all computer information - $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function 'Get-AllClientComputerInformation'
