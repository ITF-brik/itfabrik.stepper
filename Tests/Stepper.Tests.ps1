$ErrorActionPreference = 'Stop'

# Import the module from the repo root
$modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'ITFabrik.Stepper.psd1'
Import-Module $modulePath -Force

Describe 'ITFabrik.Stepper' {
    BeforeEach {
        # Ensure clean state between tests
        try { while (Get-CurrentStep) { Complete-Step } } catch { Write-Verbose 'Step stack cleanup skipped.' }
    }

    It 'exports only Invoke-Step' {
        $cmds = Get-Command -Module ITFabrik.Stepper | Select-Object -ExpandProperty Name
        $cmds | Should -Be @('Invoke-Step', 'Write-Log')
    }

    It 'returns a step with all statuses' {
        $s = Invoke-Step -Name 'PendingTest' -ScriptBlock { } -PassThru
        $s.Status | Should -Be 'Success'
        $s = $null
        $s = Invoke-Step -Name 'ErrorTest' -ContinueOnError -ScriptBlock { throw 'fail' } -PassThru
        $s.Status | Should -Be 'Error'
        $s.Detail | Should -Be 'fail'
    }

    It 'handles deep nesting (3+ levels)' {
        $step = @(Invoke-Step -Name 'L0' -ScriptBlock {
            Invoke-Step -Name 'L1' -ScriptBlock {
                Invoke-Step -Name 'L2' -ScriptBlock {
                    Invoke-Step -Name 'L3' -ScriptBlock { } -PassThru
                } -PassThru
            } -PassThru
        } -PassThru)
        $step.Level | Should -Be 0
        $step.Children[0].Level | Should -Be 1
        $step.Children[0].Children[0].Level | Should -Be 2
        $step.Children[0].Children[0].Children[0].Level | Should -Be 3
    }

    It 'handles error in nested step with ContinueOnError' {
        $parent = Invoke-Step -Name 'Parent' -ContinueOnError -PassThru -ScriptBlock {
            Invoke-Step -Name 'Child' -PassThru -ScriptBlock { throw 'fail' }
        }
        $parent.Children.Count | Should -Be 1
        $parent.Children[0].Status | Should -Be 'Error'
        $parent.Status | Should -Be 'Success'
    }

    It 'returns all steps in correct order (children then parent)' {
        $steps = @(
            Invoke-Step -Name 'C1' -PassThru -ScriptBlock { }
            Invoke-Step -Name 'C2' -PassThru -ScriptBlock { }
            Invoke-Step -Name 'P' -PassThru -ScriptBlock { }
        )
        $steps.Count | Should -Be 3
        $steps[0].Name | Should -Be 'C1'
        $steps[1].Name | Should -Be 'C2'
        $steps[2].Name | Should -Be 'P'
    }

    It 'sets Detail property on error' {
        $s = Invoke-Step -Name 'ErrDetail' -ContinueOnError -PassThru -ScriptBlock { throw 'detail test' }
        $s.Detail | Should -Be 'detail test'
    }

    It 'sets StartTime and EndTime' {
        $s = Invoke-Step -Name 'TimeTest' -PassThru -ScriptBlock { Start-Sleep -Milliseconds 10 }
        $s.StartTime | Should -Not -Be $null
        $s.EndTime | Should -Not -Be $null
        ($s.EndTime - $s.StartTime).TotalMilliseconds | Should -BeGreaterThan 0
    }

    It 'returns distinct Step objects in a foreach loop' {
        $items = 1..3
        $steps = foreach ($i in $items) {
            Invoke-Step -Name "Loop $i" -PassThru -ScriptBlock { }
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

    It 'throws when Name exceeds 80 characters' {
        $name = ('A' * 81)
        { Invoke-Step -Name $name -ScriptBlock { } } | Should -Throw '*Le nom de l''étape ne doit pas dépasser 80 caractères.*'
    }

    It 'throws when Name contains invalid characters' {
        { Invoke-Step -Name 'Bad/Name' -ScriptBlock { } } | Should -Throw '*Le nom de l''étape contient des caractères interdits*'
    }

    # Pour la compatibilité PowerShell Core, prévoir un pipeline CI multi‑plateforme (hors test local)

    It 'returns a step for simple Invoke-Step' {
        $s = Invoke-Step -Name 'A' -PassThru -ScriptBlock { }
        $s.Name | Should -Be 'A'
        $s.Level | Should -Be 0
        $s.Status | Should -Be 'Success'
        $s.EndTime | Should -Not -Be $null
    }

    It 'nests via Invoke-Step and returns both steps' {
        $parent = Invoke-Step -Name 'Parent' -PassThru -ScriptBlock { Invoke-Step -Name 'Child' -ScriptBlock { } }
        $parent.Children.Count | Should -Be 1
        $parent.Children[0].Name | Should -Be 'Child'
        $parent.Children[0].Level | Should -Be 1
        $parent.Children[0].ParentStep.Name | Should -Be 'Parent'
        $parent.Name | Should -Be 'Parent'
        $parent.Level | Should -Be 0
    }

    It 'propagates error status on failure with ContinueOnError' {
        $s = Invoke-Step -Name 'Err' -PassThru -ContinueOnError -ScriptBlock { throw 'x' }
        $s.Status | Should -Be 'Error'
        $s.Detail | Should -Be 'x'
    }

    It 'Invoke-Step throws when ContinueOnError is false' {
        { Invoke-Step -Name 'Err' -ScriptBlock { throw 'x' } } | Should -Throw
    }

    It 'Invoke-Step does not throw when ContinueOnError is true' {
        { Invoke-Step -Name 'Err' -ContinueOnError -ScriptBlock { throw 'x' } } | Should -Not -Throw
    }

    It 'creates one child step per input item in collection mode' {
        $parent = Invoke-Step -Name 'Batch' -InputObject @('alpha', 'beta', 'gamma') -PassThru -ScriptBlock {
            param($item, $index)
            [void]$item
            Start-Sleep -Milliseconds (5 + $index)
        }

        $parent.Name | Should -Be 'Batch'
        $parent.Status | Should -Be 'Success'
        $parent.Children.Count | Should -Be 3
        @($parent.Children | ForEach-Object Name) | Should -Be @(
            'Batch [alpha]',
            'Batch [beta]',
            'Batch [gamma]'
        )
        @($parent.Children | ForEach-Object Status) | Should -Be @('Success', 'Success', 'Success')
    }

    It 'passes the item and index to the collection script block' {
        $parent = Invoke-Step -Name 'Batch args' -InputObject @('one', 'two') -PassThru -ScriptBlock {
            param($item, $index)
            Invoke-Step -Name "Args $index $item" -ScriptBlock { }
        }

        @($parent.Children | ForEach-Object {
                $_.Children[0].Name
            }) | Should -Be @(
            'Args 0 one',
            'Args 1 two'
        )
    }

    It 'continues processing remaining items when ContinueOnError is enabled in collection mode' {
        $parent = Invoke-Step -Name 'Batch continue' -InputObject @(1, 2, 3) -ContinueOnError -PassThru -ScriptBlock {
            param($item, $index)
            [void]$item
            if ($index -eq 1) {
                throw 'boom 2'
            }
        }

        $parent.Status | Should -Be 'Success'
        $parent.Children.Count | Should -Be 3
        @($parent.Children | ForEach-Object Status) | Should -Be @('Success', 'Error', 'Success')
        $parent.Children[1].Detail | Should -Be 'boom 2'
    }

    It 'stops collection processing on the first error when ContinueOnError is disabled' {
        {
            Invoke-Step -Name 'Batch stop' -InputObject @(1, 2, 3) -ScriptBlock {
                param($item, $index)
                [void]$item
                if ($index -eq 1) {
                    throw 'boom stop'
                }
            }
        } | Should -Throw '*boom stop*'
    }

    It 'supports parallel collection processing in PowerShell 7+' -Skip:($PSVersionTable.PSVersion.Major -lt 7) {
        $env:ITFABRIK_STEPPER_PARALLEL_PREFIX = 'Inner'

        try {
            $parent = Invoke-Step -Name 'Parallel batch' -InputObject @('alpha', 'beta', 'gamma') -Parallel -ThrottleLimit 2 -PassThru -ScriptBlock {
                param($item, $index)
                Invoke-Step -Name "${env:ITFABRIK_STEPPER_PARALLEL_PREFIX}-$item-$index" -ScriptBlock {
                    Start-Sleep -Milliseconds 20
                }
            }

            $parent.Status | Should -Be 'Success'
            @($parent.Children | ForEach-Object Name) | Should -Be @(
                'Parallel batch [alpha]',
                'Parallel batch [beta]',
                'Parallel batch [gamma]'
            )
            @($parent.Children | ForEach-Object {
                    $_.Children[0].Name
                }) | Should -Be @(
                'Inner-alpha-0',
                'Inner-beta-1',
                'Inner-gamma-2'
            )
        }
        finally {
            Remove-Item Env:ITFABRIK_STEPPER_PARALLEL_PREFIX -ErrorAction SilentlyContinue
        }
    }

    It 'preserves child failures in parallel collection mode when ContinueOnError is enabled' -Skip:($PSVersionTable.PSVersion.Major -lt 7) {
        $parent = Invoke-Step -Name 'Parallel errors' -InputObject @(1, 2, 3) -Parallel -ThrottleLimit 2 -ContinueOnError -PassThru -ScriptBlock {
            param($item)
            if ($item -eq 2) {
                throw 'parallel boom'
            }
        }

        $parent.Status | Should -Be 'Success'
        @($parent.Children | ForEach-Object Status) | Should -Be @('Success', 'Error', 'Success')
        $parent.Children[1].Detail | Should -Be 'parallel boom'
    }

    It 'replays worker logs through the caller logger in input order when running in parallel' {
        $events = [System.Collections.Generic.List[object]]::new()
        $customLogger = {
            param($component, $message, $severity, $indent)
            [void]$events.Add([pscustomobject]@{
                    Component = $component
                    Message = $message
                    Severity = $severity
                    Indent = $indent
                })
        }

        Set-Variable -Name StepManagerLogger -Value $customLogger -Scope Global
        try {
            Invoke-Step -Name 'Parallel logs' -InputObject @('beta', 'alpha') -Parallel -ParallelThreshold 1 -ThrottleLimit 2 -PassThru -ScriptBlock {
                param($item)
                Write-Log -Message "User $item" -Severity Info
            } | Out-Null
        }
        finally {
            Remove-Variable -Name StepManagerLogger -Scope Global -ErrorAction SilentlyContinue
        }

        $userEvents = @($events | Where-Object { $_.Message -like 'User *' })
        @($userEvents | ForEach-Object Component) | Should -Be @('Parallel logs [beta]', 'Parallel logs [alpha]')
        @($userEvents | ForEach-Object Message) | Should -Be @('User beta', 'User alpha')
    }
}
