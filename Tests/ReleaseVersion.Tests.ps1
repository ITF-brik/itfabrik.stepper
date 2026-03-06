$ErrorActionPreference = 'Stop'

BeforeAll {
    . (Join-Path (Split-Path $PSScriptRoot -Parent) 'Scripts\ModuleVersion.ps1')
    $script:manifestPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'ITFabrik.Stepper.psd1'
}

Describe 'Release version helpers' {
    It 'returns the stable effective version from the current manifest' {
        $info = Get-StepperReleaseVersionInfo -ManifestPath $script:manifestPath

        $info.ModuleVersion | Should -Be '1.0.8'
        $info.Prerelease | Should -Be $null
        $info.EffectiveVersion | Should -Be '1.0.8'
        $info.TagName | Should -Be 'v1.0.8'
        $info.IsPrerelease | Should -BeFalse
    }

    It 'builds an alpha effective version when the manifest defines a prerelease suffix' {
        $tempManifest = Join-Path $TestDrive 'ITFabrik.Stepper.alpha.psd1'
        Copy-Item -LiteralPath $script:manifestPath -Destination $tempManifest -Force

        $content = Get-Content -LiteralPath $tempManifest -Raw
        $content = $content.Replace("Prerelease   = `$null", "Prerelease   = 'alpha1'")
        Set-Content -LiteralPath $tempManifest -Value $content -Encoding UTF8

        $info = Get-StepperReleaseVersionInfo -ManifestPath $tempManifest

        $info.ModuleVersion | Should -Be '1.0.8'
        $info.Prerelease | Should -Be 'alpha1'
        $info.EffectiveVersion | Should -Be '1.0.8-alpha1'
        $info.TagName | Should -Be 'v1.0.8-alpha1'
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
        $content = $content.Replace("Prerelease   = `$null", "Prerelease   = 'beta1'")
        Set-Content -LiteralPath $tempManifest -Value $content -Encoding UTF8

        (Test-StepperTagMatchesManifest -ManifestPath $tempManifest -TagName 'v1.0.8-beta1') | Should -BeTrue
        (Test-StepperTagMatchesManifest -ManifestPath $tempManifest -TagName 'v1.0.8') | Should -BeFalse
    }
}
