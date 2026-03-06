<#
.SYNOPSIS
  Creates a Git tag vX.Y.Z from the module manifest version.

.DESCRIPTION
  Reads `ITFabrik.Stepper.psd1`, validates `ModuleVersion`, ensures the tag does
  not already exist, then creates an annotated tag `vX.Y.Z`. With `-Push`, the
  tag is pushed to `origin`.
#>
param(
    [switch]$Push
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $repoRoot 'ITFabrik.Stepper.psd1'
if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Manifest not found: $manifestPath"
}

$manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
$version = [string]$manifest.ModuleVersion
if ([string]::IsNullOrWhiteSpace($version)) {
    throw 'ModuleVersion missing in manifest.'
}

if ($version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+$') {
    throw "ModuleVersion '$version' is not in X.Y.Z format."
}

$tag = "v$version"
Write-Host "Manifest version: $version -> Tag: $tag" -ForegroundColor Cyan

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git not found in PATH.'
}

Push-Location $repoRoot
try {
    git rev-parse --git-dir *> $null 2>&1
} catch {
    Pop-Location
    throw "The folder '$repoRoot' is not a Git repository."
}

try {
    $existing = git tag -l $tag
    if ($existing) {
        throw "Tag '$tag' already exists."
    }

    git tag -a $tag -m "Release $tag"
    Write-Host "Tag created locally: $tag" -ForegroundColor Green

    if ($Push) {
        $remote = (git remote 2>$null) | Where-Object { $_ -eq 'origin' } | Select-Object -First 1
        if (-not $remote) { $remote = 'origin' }
        git push $remote $tag
        Write-Host "Tag pushed to '$remote': $tag" -ForegroundColor Green
    }
} finally {
    Pop-Location
}
