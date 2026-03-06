param(
    [Parameter(Mandatory)][string]$Type,
    [Parameter(Mandatory)][string]$Objective,
    [string]$BaseBranch = 'main',
    [string]$Prefix = 'cycle',
    [switch]$Push,
    [switch]$AllowDirty
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-BranchSlug {
    param(
        [Parameter(Mandatory)][string]$Value
    )

    $normalized = $Value.Normalize([Text.NormalizationForm]::FormD)
    $builder = [System.Text.StringBuilder]::new()

    foreach ($char in $normalized.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($char) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$builder.Append($char)
        }
    }

    $ascii = $builder.ToString().Normalize([Text.NormalizationForm]::FormC).ToLowerInvariant()
    $ascii = $ascii -replace '[^a-z0-9]+', '-'
    $ascii = $ascii.Trim('-')

    if ([string]::IsNullOrWhiteSpace($ascii)) {
        throw "Unable to build a branch slug from value: $Value"
    }

    return $ascii
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git not found in PATH.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
    git rev-parse --git-dir *> $null 2>&1

    if (-not $AllowDirty) {
        $status = @(git status --porcelain)
        if ($status.Count -gt 0) {
            throw 'Working tree is not clean. Commit or stash changes first, or use -AllowDirty.'
        }
    }

    $datePart = Get-Date -Format 'yyyyMMdd'
    $typeSlug = ConvertTo-BranchSlug -Value $Type
    $objectiveSlug = ConvertTo-BranchSlug -Value $Objective
    $branchSlug = "$datePart-$typeSlug-$objectiveSlug"
    if ($branchSlug.Length -gt 120) {
        $branchSlug = $branchSlug.Substring(0, 120).TrimEnd('-')
    }
    $branchName = "$Prefix/$branchSlug"

    $existingLocal = @(git branch --list $branchName)
    if ($existingLocal.Count -gt 0) {
        throw "Local branch already exists: $branchName"
    }

    $existingRemote = @(git ls-remote --heads origin $branchName 2>$null)
    if ($existingRemote.Count -gt 0) {
        throw "Remote branch already exists: $branchName"
    }

    $currentBranch = (git branch --show-current).Trim()
    if ($currentBranch -ne $BaseBranch) {
        git switch $BaseBranch
    }

    git switch -c $branchName
    Write-Host "Created and switched to branch: $branchName" -ForegroundColor Green

    if ($Push) {
        git push -u origin $branchName
        Write-Host "Branch pushed to origin: $branchName" -ForegroundColor Green
    }
} finally {
    Pop-Location
}
