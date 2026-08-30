<#
.SYNOPSIS
    Module script providing Get-RemoteServiceStatus.

.DESCRIPTION
    Retrieves the status of the Windows Remote Management (WinRM) service on the
    local computer. Imported by os_information_cooperlane.ps1.

.NOTES
    Author  : Cooper Lane
    Company : ITWorks
    Version : 1.0
#>

function Get-RemoteServiceStatus {
    <#
    .SYNOPSIS
        Retrieves the status of the Windows Remote Management (WinRM) service.
    #>
    [CmdletBinding()]
    param()

    try {
        $remoteService = Get-Service -Name 'WinRM' -ErrorAction Stop
        return $remoteService.Status.ToString()
    }
    catch {
        return "Error: Unable to retrieve the WinRM service status - $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function 'Get-RemoteServiceStatus'
