$ErrorActionPreference = 'Stop'

# Import the module from the repo root
$modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'StepManager.psd1'
Import-Module $modulePath -Force

Describe 'StepManager' {
    BeforeEach {
        # Ensure clean state between tests
        try { while (Get-CurrentStep) { Complete-Step } } catch { }
    }

    It 'exports only Invoke-Step' {
        $cmds = Get-Command -Module StepManager | Select-Object -ExpandProperty Name
        $cmds | Should -Be @('Invoke-Step')
    }

    It 'returns a step with all statuses' {
        $s = Invoke-Step -Name 'PendingTest' -ScriptBlock { }
        $s.Status | Should -Be 'Success'
        $s = $null
        $s = Invoke-Step -Name 'ErrorTest' -ContinueOnError -ScriptBlock { throw 'fail' }
        $s.Status | Should -Be 'Error'
        $s.Detail | Should -Be 'fail'
    }

    It 'handles deep nesting (3+ levels)' {
        $step = @(Invoke-Step -Name 'L0' -ScriptBlock {
            Invoke-Step -Name 'L1' -ScriptBlock {
                Invoke-Step -Name 'L2' -ScriptBlock {
                    Invoke-Step -Name 'L3' -ScriptBlock { }
                }
            }
        })
        $step.Level | Should -Be 0
        $step.Children[0].Level | Should -Be 1
        $step.Children[0].Children[0].Level | Should -Be 2
        $step.Children[0].Children[0].Children[0].Level | Should -Be 3
    }

    It 'handles error in nested step with ContinueOnError' {
        $parent = Invoke-Step -Name 'Parent' -ContinueOnError -ScriptBlock {
            Invoke-Step -Name 'Child' -ScriptBlock { throw 'fail' }
        }
        $parent.Children.Count | Should -Be 1
        $parent.Children[0].Status | Should -Be 'Error'
        $parent.Status | Should -Be 'Success'
    }

    It 'returns all steps in correct order (children then parent)' {
        $steps = @(
            Invoke-Step -Name 'C1' -ScriptBlock { }
            Invoke-Step -Name 'C2' -ScriptBlock { }
            Invoke-Step -Name 'P' -ScriptBlock { }
        )
        $steps.Count | Should -Be 3
        $steps[0].Name | Should -Be 'C1'
        $steps[1].Name | Should -Be 'C2'
        $steps[2].Name | Should -Be 'P'
    }

    It 'sets Detail property on error' {
        $s = Invoke-Step -Name 'ErrDetail' -ContinueOnError -ScriptBlock { throw 'detail test' }
        $s.Detail | Should -Be 'detail test'
    }

    It 'sets StartTime and EndTime' {
        $s = Invoke-Step -Name 'TimeTest' -ScriptBlock { Start-Sleep -Milliseconds 10 }
        $s.StartTime | Should -Not -Be $null
        $s.EndTime | Should -Not -Be $null
        ($s.EndTime - $s.StartTime).TotalMilliseconds | Should -BeGreaterThan 0
    }

    It 'returns distinct Step objects in a foreach loop' {
        $items = 1..3
        $steps = foreach ($i in $items) {
            Invoke-Step -Name "Loop $i" -ScriptBlock { }
        }
        $steps.Count | Should -Be 3
        $steps[0].Name | Should -Be 'Loop 1'
        $steps[1].Name | Should -Be 'Loop 2'
        $steps[2].Name | Should -Be 'Loop 3'
    }

    It 'throws on missing ScriptBlock' {
        { Invoke-Step -Name 'NoBlock' } | Should -Throw
    }

    It 'throws on empty Name' {
        { Invoke-Step -Name '' -ScriptBlock { } } | Should -Throw
    }

    # Pour la compatibilité PowerShell Core, prévoir un pipeline CI multi-plateforme (hors test local)

    It 'returns a step for simple Invoke-Step' {
        $s = Invoke-Step -Name 'A' -ScriptBlock { }
        $s.Name | Should -Be 'A'
        $s.Level | Should -Be 0
        $s.Status | Should -Be 'Success'
        $s.EndTime | Should -Not -Be $null
    }

    It 'nests via Invoke-Step and returns both steps' {
        $parent = Invoke-Step -Name 'Parent' -ScriptBlock { Invoke-Step -Name 'Child' -ScriptBlock { } }
        $parent.Children.Count | Should -Be 1
        $parent.Children[0].Name | Should -Be 'Child'
        $parent.Children[0].Level | Should -Be 1
        $parent.Children[0].ParentStep.Name | Should -Be 'Parent'
        $parent.Name | Should -Be 'Parent'
        $parent.Level | Should -Be 0
    }

    It 'propagates error status on failure with ContinueOnError' {
        $s = Invoke-Step -Name 'Err' -ContinueOnError -ScriptBlock { throw 'x' }
        $s.Status | Should -Be 'Error'
        $s.Detail | Should -Be 'x'
    }

    It 'Invoke-Step returns Error status when ContinueOnError is false' {
        $s = Invoke-Step -Name 'Err' -ScriptBlock { throw 'x' }
        $s.Status | Should -Be 'Error'
        $s.Detail | Should -Be 'x'
    }

    It 'Invoke-Step does not throw when ContinueOnError is true' {
        { Invoke-Step -Name 'Err' -ContinueOnError -ScriptBlock { throw 'x' } } | Should -Not -Throw
    }
}


