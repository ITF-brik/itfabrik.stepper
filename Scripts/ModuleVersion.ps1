Set-StrictMode -Version Latest

function Get-StepperReleaseVersionPattern {
    [CmdletBinding()]
    param()

    return '^(?<base>\d+\.\d+\.\d+(?:\.\d+)?)(?:-(?<prerelease>[0-9A-Za-z][0-9A-Za-z\.-]*))?$'
}

function Get-StepperReleaseVersionInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ManifestPath
    )

    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        throw "Manifest not found: $ManifestPath"
    }

    $manifest = Import-PowerShellDataFile -LiteralPath $ManifestPath
    $moduleVersion = [string]$manifest.ModuleVersion
    if ([string]::IsNullOrWhiteSpace($moduleVersion)) {
        throw 'ModuleVersion missing in manifest.'
    }

    $pattern = Get-StepperReleaseVersionPattern
    if ($moduleVersion -notmatch $pattern) {
        throw "ModuleVersion '$moduleVersion' must use a stable numeric format such as X.Y.Z or X.Y.Z.W."
    }

    $prerelease = $null
    if ($manifest.ContainsKey('PrivateData') -and $null -ne $manifest.PrivateData) {
        $psData = $manifest.PrivateData['PSData']
        if ($null -ne $psData -and $psData.ContainsKey('Prerelease')) {
            $rawPrerelease = [string]$psData['Prerelease']
            if (-not [string]::IsNullOrWhiteSpace($rawPrerelease)) {
                $prerelease = $rawPrerelease.Trim()
            }
        }
    }

    if ($prerelease -and $prerelease -notmatch '^[0-9A-Za-z][0-9A-Za-z\.-]*$') {
        throw "Prerelease '$prerelease' contains unsupported characters."
    }

    $effectiveVersion = if ($prerelease) {
        '{0}-{1}' -f $moduleVersion, $prerelease
    } else {
        $moduleVersion
    }

    return [pscustomobject]@{
        ManifestPath = (Resolve-Path -LiteralPath $ManifestPath).Path
        ModuleVersion = $moduleVersion
        Prerelease = $prerelease
        EffectiveVersion = $effectiveVersion
        TagName = "v$effectiveVersion"
        IsPrerelease = ($null -ne $prerelease)
    }
}

function Get-StepperTagVersionInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TagName
    )

    if ([string]::IsNullOrWhiteSpace($TagName)) {
        throw 'TagName is required.'
    }

    $tagVersion = $TagName.Trim()
    if ($tagVersion.StartsWith('v', [System.StringComparison]::OrdinalIgnoreCase)) {
        $tagVersion = $tagVersion.Substring(1)
    }

    $pattern = Get-StepperReleaseVersionPattern
    if ($tagVersion -notmatch $pattern) {
        throw "Tag '$TagName' must use a format like vX.Y.Z or vX.Y.Z-alpha1."
    }

    $prerelease = if ($Matches.ContainsKey('prerelease') -and $Matches['prerelease']) {
        $Matches['prerelease']
    } else {
        $null
    }

    return [pscustomobject]@{
        TagName = $TagName
        EffectiveVersion = $tagVersion
        ModuleVersion = $Matches['base']
        Prerelease = $prerelease
        IsPrerelease = ($null -ne $prerelease)
    }
}

function Test-StepperTagMatchesManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ManifestPath,
        [Parameter(Mandatory)][string]$TagName
    )

    $releaseInfo = Get-StepperReleaseVersionInfo -ManifestPath $ManifestPath
    $tagInfo = Get-StepperTagVersionInfo -TagName $TagName

    return $releaseInfo.EffectiveVersion -eq $tagInfo.EffectiveVersion
}
