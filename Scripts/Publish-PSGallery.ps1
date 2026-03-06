param(
    [string]$ApiKey,
    [string]$Repository = 'PSGallery',
    [string]$ModulePath = (Join-Path $PSScriptRoot '..\dist\ITFabrik.Stepper'),
    [switch]$ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'ModuleVersion.ps1')

$requiredFiles = @(
    'ITFabrik.Stepper.psd1',
    'ITFabrik.Stepper.psm1',
    'ITFabrik.Stepper.format.ps1xml',
    'LICENSE',
    'README.md'
)

if (-not (Test-Path -LiteralPath $ModulePath)) {
    throw "ModulePath not found: $ModulePath. Run ./Scripts/Build-Module.ps1 first."
}
$ModulePath = (Resolve-Path -LiteralPath $ModulePath).Path

$actualFiles = @(Get-ChildItem -LiteralPath $ModulePath -File | Select-Object -ExpandProperty Name)
$missing = @($requiredFiles | Where-Object { $_ -notin $actualFiles })
$extra = @($actualFiles | Where-Object { $_ -notin $requiredFiles })
if ($missing.Count -gt 0 -or $extra.Count -gt 0) {
    throw ("Invalid artifact content. Missing: [{0}] Extra: [{1}] (expected: {2})" -f ($missing -join ', '), ($extra -join ', '), ($requiredFiles -join ', '))
}

$manifest = Join-Path $ModulePath 'ITFabrik.Stepper.psd1'
if (-not (Test-Path -LiteralPath $manifest)) { throw "Manifest not found: $manifest" }
$manifest = (Resolve-Path -LiteralPath $manifest).Path
$releaseInfo = Get-StepperReleaseVersionInfo -ManifestPath $manifest

$rootModule = (Import-PowerShellDataFile -LiteralPath $manifest).RootModule
if (-not $rootModule -or -not (Test-Path -LiteralPath (Join-Path $ModulePath $rootModule))) {
    throw "RootModule not found in artifact: $rootModule"
}

Test-ModuleManifest -Path $manifest | Out-Null
$imported = Import-Module -Name $manifest -Force -PassThru
if (-not $imported) { throw "Import-Module failed on artifact: $manifest" }
Remove-Module -Name $imported.Name -Force -ErrorAction SilentlyContinue

Write-Host "Publishing module from artifact: $ModulePath" -ForegroundColor Cyan
Write-Host "Effective release version: $($releaseInfo.EffectiveVersion)" -ForegroundColor Cyan

if ($ValidateOnly) {
    Write-Host 'ValidateOnly enabled: no publication executed.' -ForegroundColor Green
    return
}

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    throw 'ApiKey is required for publication (or use -ValidateOnly).'
}

try {
    Set-PSRepository -Name $Repository -InstallationPolicy Trusted -ErrorAction SilentlyContinue
} catch {
    Write-Verbose ("Unable to set PSRepository '{0}' to Trusted: {1}" -f $Repository, $_.Exception.Message)
}

Publish-Module -Path $ModulePath -Repository $Repository -NuGetApiKey $ApiKey -Verbose -Force
