# ITWorks OS Information Script

A menu-driven PowerShell tool that collects operating system and hardware details from
the computer it is run on, so a support technician can gather what they need for a fault
diagnosis without remembering individual cmdlets.

Built for the ITWorks scenario in **ICTNWK428 Create scripts for networking** (TAFE SA,
ICT40120 Certificate IV in Information Technology).

---

## Requirements

| | |
|---|---|
| Operating system | Windows Server 2022 / Windows 10 / Windows 11 |
| PowerShell | 5.1 or later |
| Modules | None at runtime. Pester 5+ and PSScriptAnalyzer for development only |

The script runs against the local computer only. It does not connect to remote machines.

---

## Usage

Clone or copy the repository, keeping the `Modules` folder beside the master script, then:

```powershell
cd .\itworks-os-information-script
.\os_information_cooperlane.ps1
```

The menu repeats until option 9 is selected. Any entry that is not a single digit from
1 to 9 is rejected and the menu is displayed again.

### Menu options

| Option | Returns | Source |
|---|---|---|
| 1 | Operating system name | `Get-ComputerInfo` → `OsName` |
| 2 | WinRM service status | `Get-Service WinRM` |
| 3 | Manufacturer and model | `Get-ComputerInfo` → `CsManufacturer`, `CsModel` |
| 4 | Computer name | `Get-ComputerInfo` → `CsName` |
| 5 | Domain name | `Get-ComputerInfo` → `CsDomain` |
| 6 | WinRM trusted hosts | `WSMan:\localhost\Client\TrustedHosts` |
| 7 | OS architecture | `Get-ComputerInfo` → `OsArchitecture` |
| 8 | All of the above, as a list | One batched call plus options 2 and 6 |
| 9 | Quit | |

---

## Project structure

```
os_information_cooperlane.ps1                  Master script: menu display and menu loop
os_information_cooperlane.Tests.ps1            Pester test suite
Modules\
    Get-ClientComputerInformation.psm1         Options 1, 3, 4, 5, 7
    Get-RemoteServiceStatus.psm1               Option 2
    Get-TrustedHost.psm1                       Option 6
    Get-AllClientComputerInformation.psm1      Option 8
```

The master script builds the module path from its own location, so the `Modules` folder
must stay alongside it.

---

## Design notes

**One parameterised retrieval function.** Five of the seven menu items are properties of
the same `Get-ComputerInfo` object, so they share `Get-ClientComputerInformation`, which
takes the property name as a parameter. The WinRM service status and the trusted hosts are
not `Get-ComputerInfo` properties, so they have dedicated modules.

**Option 8 makes a single query.** Rather than calling the other functions seven times, it
requests every property in one `Get-ComputerInfo` call and then adds the two items that
come from elsewhere. Faster, and lighter on the client machine.

**Errors are returned, not thrown.** Every function handles its own failures in a
`try`/`catch` and returns a string beginning `Error:`. A failed lookup shows a message and
the menu keeps running, instead of dropping a technician back to a bare prompt mid-job.

**Validation happens before dispatch.** The selection is tested against `^[1-9]$` in the
menu loop, so each retrieval function stays responsible for exactly one task.

**The script is safe to dot-source.** The menu only starts when the script is run directly:

```powershell
if ($MyInvocation.InvocationName -ne '.') { Invoke-OSInformationMenu }
```

Without that guard, the test suite would launch the interactive menu and hang.

**Output is written to the host.** Display goes through `Out-Host` rather than
`Write-Output` alone. The PowerShell ISE buffers the output stream while `Read-Host` writes
its prompt directly to the host, which made every result appear one selection late in the
ISE. Writing to the host keeps the ordering correct in the ISE and the Windows command
line alike.

---

## Testing

```powershell
Remove-Module Pester -ErrorAction SilentlyContinue
Import-Module Pester -MinimumVersion 5.0.0 -Force
Invoke-Pester -Path .\os_information_cooperlane.Tests.ps1 -Output Detailed
```

28 tests covering every function, including out-of-scope input — null, empty string,
whitespace, letters, `0`, `10` — and forced failures to prove the error handling.

Static analysis:

```powershell
Invoke-ScriptAnalyzer -Path .\os_information_cooperlane.ps1
Invoke-ScriptAnalyzer -Path .\Modules -Recurse
```

### Two things worth knowing before you run the tests

**Mocks for commands called inside a module need `-ModuleName`.** A mock created in the
test session cannot be seen from inside a module's own scope, so mocks for
`Get-ComputerInfo`, `Get-Service` and `Get-Item` all name their module. `Show-Menu` and
`Invoke-OSInformationMenu` live in the master script, so their mocks do not.

**Do not use `Assert-MockCalled`.** Pester 6 removed it. Calling it makes PowerShell
auto-load the Pester 3.4.0 that ships with Windows, whose `Mock` and `Should` then shadow
the modern ones and every subsequent test fails. The symptom is a run that reports
`Pester v6.x` in the banner while the stack traces point into `...\Pester\3.4.0\`. This
suite uses `Should -Invoke` throughout.

---

## Coding standards

Written to the ITWorks PowerShell coding standards: four-space indentation, One True Brace
Style, lines under 115 characters, approved verbs, PascalCase function names, camelCase
private variables, comment-based help on every function, and `[CmdletBinding()]` with
`begin`/`process`/`end` in the master script. Version control follows the ITWorks Git and
GitHub procedure — private repository, meaningful commit messages, `main` for
production-ready code, tagged releases, and no hardcoded sensitive data.

---

## Version history

| Tag | Change |
|---|---|
| v1.0 | Initial working menu script with module structure and passing tests |
| v1.1 | Pester 6 compatible tests; `[OutputType()]` declared on all module functions |
| v1.2 | Menu output written to the host so results display in order in the ISE |

---

## Known limitations and future work

- **Local only.** Remote support would need a `-ComputerName` parameter, credential
  handling, and WinRM configured on the target.
- **Tied to `Get-ComputerInfo` property names**, which are not guaranteed stable across
  Windows releases and should be re-checked when the fleet moves to a newer build.
- **The menu is defined in two places** — the display text in `Show-Menu` and the
  behaviour in the `switch`. These can drift; a single data structure driving both would
  be better.
- **No export or logging.** Results are shown on screen only. A technician attaching
  findings to a ticket would want a text or CSV export.
- **Pester version sensitivity.** The suite should be re-run and reviewed whenever a new
  major version of Pester is released.

---

## Author

Cooper Lane
