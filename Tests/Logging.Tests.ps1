$ErrorActionPreference = 'Stop'


Describe 'Logging' {
    BeforeAll {
        # Import du module depuis la racine
        $modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'ITFabrik.Stepper.psd1'
        Import-Module $modulePath -Force
        . (Join-Path $PSScriptRoot '..\Private\Functions\New-Step.ps1')
        . (Join-Path $PSScriptRoot '..\Private\Functions\Set-Step.ps1')
        . (Join-Path $PSScriptRoot '..\Private\Functions\Get-CurrentStep.ps1')
        . (Join-Path $PSScriptRoot '..\Private\Functions\Invoke-Logger.ps1')
        . (Join-Path $PSScriptRoot '..\Private\Helpers.ps1')
        . (Join-Path $PSScriptRoot '..\Private\State.ps1')
        . (Join-Path $PSScriptRoot '..\Private\Classes\Step.ps1')
        
        # Mock Write-Host avant import du module pour qu'il soit pris en compte dans le scope du module
        Mock Write-Host { } -ModuleName ITFabrik.Stepper
    }

    BeforeEach {
        # Ensure clean state between tests
        try { while (Get-CurrentStep) { Complete-Step } } catch { }
    }

    It 'affiche un message avec Write-StepMessage' {
        . (Join-Path $PSScriptRoot '..\Private\Helpers.ps1')
        Mock Write-Host { }
        Write-StepMessage -Severity 'Info' -Message 'Test log' -IndentLevel 2 -Component 'UnitTest'
        Assert-MockCalled Write-Host -Exactly 1 -Scope It -ParameterFilter { $Object -match 'Test log' }
    }


    It 'utilise Write-Log (fallback console)' {
        Mock Write-StepMessage { } -ModuleName ITFabrik.Stepper
        Write-Log -Message 'Log message' -Severity 'Info'
        Assert-MockCalled Write-StepMessage -Exactly 1 -Scope It -ModuleName ITFabrik.Stepper -ParameterFilter { $Message -eq 'Log message' -and $Severity -eq 'Info' }
    }

    It 'utilise un logger personnalisé si défini' {
        $global:calls = @()
        $customLogger = { param($Component, $Message, $Severity, $IndentLevel) $global:calls += "$Component|$Message|$Severity|$IndentLevel" }
        Set-Variable -Name StepManagerLogger -Value $customLogger -Scope Global
        Write-Log -Message 'Msg' -Severity 'Warning'
        Remove-Variable -Name StepManagerLogger -Scope Global
        $global:calls | Should -Contain '|Msg|Warning|1'
        Remove-Variable -Name calls -Scope Global -ErrorAction SilentlyContinue
    }

    It "log lors de la création d'une étape" {
        $global:calls = @()
        $customLogger = { param($Component, $Message, $Severity, $IndentLevel) $global:calls += "$Component|$Message|$Severity|$IndentLevel" }
        $oldLogger = $null
        try {
            $oldVerbosePreference = $VerbosePreference
            $Global:VerbosePreference = 'Continue'
            $oldLogger = Get-Variable StepManagerLogger -Scope Global -ErrorAction SilentlyContinue
            Set-Variable -Name StepManagerLogger -Value $customLogger -Scope Global
            New-Step -Name 'LogStepTest' | Out-Null
            $Global:VerbosePreference = $oldVerbosePreference
        } finally {
            if ($oldLogger) { Set-Variable -Name StepManagerLogger -Value $oldLogger.Value -Scope Global } else { Remove-Variable -Name StepManagerLogger -Scope Global -ErrorAction SilentlyContinue }
        }
        $global:calls | Should -BeExactly @(
            "StepManager|Création de l'étape : LogStepTest|Verbose|0"
            "StepManager|LogStepTest|Info|0"
        )
        Remove-Variable -Name calls -Scope Global -ErrorAction SilentlyContinue
    }

    It "log une erreur via Set-Step" {
    $global:calls = @()
    $customLogger = { param($Component, $Message, $Severity, $IndentLevel) $global:calls += "$Component|$Message|$Severity|$IndentLevel" }
    $oldLogger = $null
    try {
        $oldLogger = Get-Variable StepManagerLogger -Scope Global -ErrorAction SilentlyContinue
        Set-Variable -Name StepManagerLogger -Value $customLogger -Scope Global
        $step = New-Step -Name 'ErrStepTest'
        Set-Step -Status Error -Detail 'Erreur test' | Out-Null
    } finally {
        if ($oldLogger) { Set-Variable -Name StepManagerLogger -Value $oldLogger.Value -Scope Global } else { Remove-Variable -Name StepManagerLogger -Scope Global -ErrorAction SilentlyContinue }
    }
    $global:calls | Should -Contain "StepManager|Erreur dans l'étape [ErrStepTest] : Erreur test|Error|0"
    Remove-Variable -Name calls -Scope Global -ErrorAction SilentlyContinue
    }
}

