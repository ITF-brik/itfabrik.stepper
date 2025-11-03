@{
    RootModule        = 'itfabrik.stepper.psm1'
    ModuleVersion     = '1.0.2'
    GUID              = 'b3a9d3b4-7a2d-4a0b-9f8e-2c3b6f7f8c2e'
    Author            = 'IT FABRIK'
    CompanyName       = 'IT FABRIK'
    Copyright        = '(c) IT FABRIK. All rights reserved.'
    Description       = 'itfabrik.stepper: Encapsulates steps with logging and error handling.'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop','Core')
    FunctionsToExport = @('Invoke-Step', 'Write-Log')
    CmdletsToExport   = @()
    AliasesToExport   = @()
    VariablesToExport = @()
    FormatsToProcess = @('itfabrik.stepper.format.ps1xml')
    PrivateData       = @{
        PSData = @{
            Tags = @('steps','logging','workflow')
            LicenseUri   = 'https://github.com/ITF-brik/itfabrik.stepper/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/ITF-brik/itfabrik.stepper'
            IconUri      = 'https://raw.githubusercontent.com/ITF-brik/itfabrik.stepper/main/Media/icon.png'
            ReleaseNotes = 'Voir CHANGELOG.md et la page Releases sur GitHub.'
        }
    }
}
