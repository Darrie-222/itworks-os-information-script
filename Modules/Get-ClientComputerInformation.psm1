<#
.SYNOPSIS
    Module script providing Get-ClientComputerInformation.

.DESCRIPTION
    Retrieves one or more named properties from the local computer. Imported by
    os_information_cooperlane.ps1.

.NOTES
    Author  : Cooper Lane
    Company : ITWorks
    Version : 1.0
#>

function Get-ClientComputerInformation {
    <#
    .SYNOPSIS
        Retrieves one or more named properties from the local computer.
    .DESCRIPTION
        Queries Get-ComputerInfo for the supplied property name or names and returns
        the result. On failure the function returns a string beginning with "Error:"
        rather than throwing, so the calling menu keeps running.
    .PARAMETER PropertyName
        The name or names of the Get-ComputerInfo properties to retrieve, for example
        OsName or CsManufacturer.
    .EXAMPLE
        Get-ClientComputerInformation -PropertyName 'OsName'
    #>
    [CmdletBinding()]
    [OutputType([string], [object])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$PropertyName
    )

    try {
        # Query only the requested properties to keep the call efficient.
        $computerInfo = Get-ComputerInfo -Property $PropertyName -ErrorAction Stop

        if ($null -eq $computerInfo) {
            return "Error: No information was returned for '$($PropertyName -join ', ')'."
        }

        return $computerInfo
    }
    catch {
        return "Error: Unable to retrieve '$($PropertyName -join ', ')' - $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function 'Get-ClientComputerInformation'
