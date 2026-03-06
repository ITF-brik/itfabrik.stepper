$ErrorActionPreference = 'Stop'

BeforeAll {
    . (Join-Path (Split-Path $PSScriptRoot -Parent) 'Scripts\ModuleVersion.ps1')
    $script:manifestPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'ITFabrik.Stepper.psd1'
    $script:manifestData = Import-PowerShellDataFile -LiteralPath $script:manifestPath
    $script:currentModuleVersion = [string]$script:manifestData.ModuleVersion
    $script:currentPrerelease = [string]$script:manifestData.PrivateData.PSData.Prerelease
    if ([string]::IsNullOrWhiteSpace($script:currentPrerelease)) {
        $script:currentPrerelease = $null
    }
}

Describe 'Release version helpers' {
    It 'returns the effective version from the current manifest' {
        $info = Get-StepperReleaseVersionInfo -ManifestPath $script:manifestPath

        $expectedEffectiveVersion = if ($null -ne $script:currentPrerelease) {
            '{0}-{1}' -f $script:currentModuleVersion, $script:currentPrerelease
        } else {
            $script:currentModuleVersion
        }

        $info.ModuleVersion | Should -Be $script:currentModuleVersion
        $info.Prerelease | Should -Be $script:currentPrerelease
        $info.EffectiveVersion | Should -Be $expectedEffectiveVersion
        $info.TagName | Should -Be "v$expectedEffectiveVersion"
        $info.IsPrerelease | Should -Be ($null -ne $script:currentPrerelease)
    }

    It 'builds an alpha effective version when the manifest defines a prerelease suffix' {
        $tempManifest = Join-Path $TestDrive 'ITFabrik.Stepper.alpha.psd1'
        Copy-Item -LiteralPath $script:manifestPath -Destination $tempManifest -Force

        $content = Get-Content -LiteralPath $tempManifest -Raw
        $currentPrereleaseToken = if ($null -ne $script:currentPrerelease) {
            "Prerelease   = '{0}'" -f $script:currentPrerelease
        } else {
            "Prerelease   = `$null"
        }
        $content = $content.Replace($currentPrereleaseToken, "Prerelease   = 'alpha1'")
        Set-Content -LiteralPath $tempManifest -Value $content -Encoding UTF8

        $info = Get-StepperReleaseVersionInfo -ManifestPath $tempManifest

        $info.ModuleVersion | Should -Be $script:currentModuleVersion
        $info.Prerelease | Should -Be 'alpha1'
        $info.EffectiveVersion | Should -Be ("{0}-alpha1" -f $script:currentModuleVersion)
        $info.TagName | Should -Be ("v{0}-alpha1" -f $script:currentModuleVersion)
        $info.IsPrerelease | Should -BeTrue
    }

    It 'parses prerelease tags' {
        $tagInfo = Get-StepperTagVersionInfo -TagName 'v1.0.9-alpha2'

        $tagInfo.ModuleVersion | Should -Be '1.0.9'
        $tagInfo.Prerelease | Should -Be 'alpha2'
        $tagInfo.EffectiveVersion | Should -Be '1.0.9-alpha2'
        $tagInfo.IsPrerelease | Should -BeTrue
    }

    It 'matches a prerelease tag against a manifest carrying the same suffix' {
        $tempManifest = Join-Path $TestDrive 'ITFabrik.Stepper.beta.psd1'
        Copy-Item -LiteralPath $script:manifestPath -Destination $tempManifest -Force

        $content = Get-Content -LiteralPath $tempManifest -Raw
        $currentPrereleaseToken = if ($null -ne $script:currentPrerelease) {
            "Prerelease   = '{0}'" -f $script:currentPrerelease
        } else {
            "Prerelease   = `$null"
        }
        $content = $content.Replace($currentPrereleaseToken, "Prerelease   = 'beta1'")
        Set-Content -LiteralPath $tempManifest -Value $content -Encoding UTF8

        (Test-StepperTagMatchesManifest -ManifestPath $tempManifest -TagName ("v{0}-beta1" -f $script:currentModuleVersion)) | Should -BeTrue
        (Test-StepperTagMatchesManifest -ManifestPath $tempManifest -TagName ("v{0}" -f $script:currentModuleVersion)) | Should -BeFalse
    }
}
