<#
.SYNOPSIS
    Module script providing Get-TrustedHost.

.DESCRIPTION
    Retrieves the WinRM client trusted hosts configured on the local computer.
    Imported by os_information_cooperlane.ps1.

.NOTES
    Author  : Cooper Lane
    Company : ITWorks
    Version : 1.0
#>

function Get-TrustedHost {
    <#
    .SYNOPSIS
        Retrieves the WinRM client trusted hosts configured on the computer.
    .DESCRIPTION
        Reads the WSMan client TrustedHosts setting. An empty setting is a valid
        result and returns an explanatory message rather than an error. On failure
        the function returns a string beginning with "Error:".
    .EXAMPLE
        Get-TrustedHost
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    try {
        $trustedHost = Get-Item -Path 'WSMan:\localhost\Client\TrustedHosts' -ErrorAction Stop

        # A blank TrustedHosts value is normal on a freshly built computer.
        if ([string]::IsNullOrWhiteSpace($trustedHost.Value)) {
            return 'No trusted hosts are configured on this computer.'
        }

        return $trustedHost.Value
    }
    catch {
        return "Error: Unable to retrieve the trusted hosts - $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function 'Get-TrustedHost'
