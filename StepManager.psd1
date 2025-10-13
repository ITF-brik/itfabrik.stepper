@{
    RootModule        = 'StepManager.psm1'
    ModuleVersion     = '2025.10.1.5'
    GUID              = 'b3a9d3b4-7a2d-4a0b-9f8e-2c3b6f7f8c2e'
    Author            = 'IT FABRIK'
    CompanyName       = 'IT FABRIK'
    Copyright        = '(c) IT FABRIK. All rights reserved.'
    Description       = 'StepManager: Encapsulates steps with logging and error handling.'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop','Core')
    FunctionsToExport = @('Invoke-Step')
    CmdletsToExport   = @()
    AliasesToExport   = @()
    VariablesToExport = @()
    PrivateData       = @{
        PSData = @{
            Tags = @('steps','logging','workflow')
            LicenseUri   = 'https://github.com/ITF-brik/StepManager/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/ITF-brik/StepManager'
            IconUri      = 'https://raw.githubusercontent.com/ITF-brik/StepManager/main/Media/icon.png'
            ReleaseNotes = 'Voir CHANGELOG.md et la page Releases sur GitHub.'
        }
    }
}
