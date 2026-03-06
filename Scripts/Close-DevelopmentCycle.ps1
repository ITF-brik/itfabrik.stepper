param(
    [Parameter(Mandatory)][string]$Branch,
    [string]$BaseBranch = 'main',
    [switch]$DeleteRemote,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git not found in PATH.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
    git rev-parse --git-dir *> $null 2>&1

    if ($Branch -eq $BaseBranch) {
        throw "Refusing to delete base branch: $BaseBranch"
    }

    $currentBranch = (git branch --show-current).Trim()
    if ($currentBranch -eq $Branch) {
        git switch $BaseBranch
    }

    $deleteFlag = if ($Force) { '-D' } else { '-d' }
    git branch $deleteFlag $Branch
    Write-Host "Deleted local branch: $Branch" -ForegroundColor Green

    if ($DeleteRemote) {
        git push origin --delete $Branch
        Write-Host "Deleted remote branch: $Branch" -ForegroundColor Green
    }
} finally {
    Pop-Location
}
