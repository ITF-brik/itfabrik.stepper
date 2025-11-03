# Load private state, helpers, classes
. $PSScriptRoot\Private\State.ps1
. $PSScriptRoot\Private\Helpers.ps1
. $PSScriptRoot\Private\Classes\Step.ps1

# Load private functions
Get-ChildItem -Path "$PSScriptRoot\Private\Functions" -Filter *.ps1 -File -ErrorAction SilentlyContinue |
    ForEach-Object { . $_.FullName }

# Load public functions
Get-ChildItem -Path "$PSScriptRoot\Public" -Filter *.ps1 -File -ErrorAction SilentlyContinue |
    ForEach-Object { . $_.FullName }

# Export public functions
Export-ModuleMember -Function Invoke-Step,Write-Log -Alias @()
