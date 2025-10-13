$ErrorActionPreference = 'Stop'

# Import the module from the repo root
$modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'StepManager.psd1'
Import-Module $modulePath -Force

Describe 'Logging' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..\Private\Helpers.ps1')
        . (Join-Path $PSScriptRoot '..\Private\Functions\New-Step.ps1')
        . (Join-Path $PSScriptRoot '..\Private\Functions\Set-Step.ps1')
        . (Join-Path $PSScriptRoot '..\Private\Functions\Get-CurrentStep.ps1')
        . (Join-Path $PSScriptRoot '..\Private\State.ps1')
        . (Join-Path $PSScriptRoot '..\Private\Classes\Step.ps1')
    }

    BeforeEach {
        # Ensure clean state between tests
        try { while (Get-CurrentStep) { Complete-Step } } catch { }
    }

    It 'affiche un message avec Write-StepMessage' {
        Mock Write-Host { }
        Write-StepMessage -Prefix '[UnitTest]' -Message 'Test log' -IndentLevel 2
        Assert-MockCalled Write-Host -Exactly 1 -Scope It -ParameterFilter { $Object -match 'Test log' }
    }

    It 'utilise Invoke-Logger (fallback console)' {
        Mock Write-Host { }
        Invoke-Logger -Component 'UnitTest' -Message 'Log message' -Severity 'Information' -IndentLevel 1
        Assert-MockCalled Write-Host -Exactly 1 -Scope It -ParameterFilter { $Object -match '\[UnitTest\]\[Information\] Log message' }
    }

    It 'utilise un logger personnalisé si défini' {
        $Script:calls = @()
        $customLogger = { param($Component, $Message, $Severity, $IndentLevel) $global:calls += "$Component|$Message|$Severity|$IndentLevel" }
        Set-Variable -Name StepManagerLogger -Value $customLogger -Scope Script
        Invoke-Logger -Component 'Custom' -Message 'Msg' -Severity 'Warning' -IndentLevel 3
        Remove-Variable -Name StepManagerLogger -Scope Script
        $global:calls | Should -Contain 'Custom|Msg|Warning|3'
        Remove-Variable -Name calls -Scope Global -ErrorAction SilentlyContinue
    }

    It "log lors de la création d'une étape" {
        Mock Write-Host { }
        $oldLogger = $null
        try {
            $oldLogger = Get-Variable StepManagerLogger -Scope Script -ErrorAction SilentlyContinue
            Remove-Variable StepManagerLogger -Scope Script -ErrorAction SilentlyContinue
            New-Step -Name 'LogStepTest' | Out-Null
        } finally {
            if ($oldLogger) { Set-Variable -Name StepManagerLogger -Value $oldLogger.Value -Scope Script }
        }
        Assert-MockCalled Write-Host -Exactly 1 -Scope It -ParameterFilter { $Object -match "Création de l'étape : LogStepTest" }
    }

    It "log une erreur via Set-Step" {
        Mock Write-Host { }
        $step = New-Step -Name 'ErrStepTest'
        Set-Step -Status Error -Detail 'Erreur test' | Out-Null
        Assert-MockCalled Write-Host -Exactly 1 -Scope It -ParameterFilter { $Object -match "Erreur dans l'étape \[ErrStepTest\] : Erreur test" }
    }
}