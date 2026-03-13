<#
.SYNOPSIS
Exécute un bloc de script dans une étape avec gestion d'état, d'imbrication et d'erreur.

.DESCRIPTION
Encapsule l'exécution d'un ScriptBlock dans une étape typée, avec gestion du statut
(Success, Error), imbrication et option de poursuite sur erreur.

Le cmdlet peut aussi traiter une collection d'éléments. Dans ce mode, une étape
parente est créée avec une sous-étape par élément. L'exécution est séquentielle
par défaut. En PowerShell 7+, l'option `-Parallel` utilise `ForEach-Object -Parallel`.
En Windows PowerShell 5.1, elle utilise `Start-Job` avec gestion du `ThrottleLimit`.
Dans ce mode parallèle, le worker reconstruit le `ScriptBlock` utilisateur dans
un contexte isolé. Les variables externes et helpers du scope appelant ne sont
donc pas garantis. Préférez un `ScriptBlock` autonome basé sur `param($item, $index)`.

.PARAMETER Name
Nom de l'étape à exécuter.

.PARAMETER ScriptBlock
Bloc de code à exécuter dans l'étape.

.PARAMETER ContinueOnError
Indique si l'exécution doit continuer en cas d'erreur dans l'étape. Par défaut : $false.

.PARAMETER InputObject
Collection d'éléments à traiter. Si ce paramètre est fourni, `Invoke-Step` exécute
le `ScriptBlock` une fois par élément.

.PARAMETER Parallel
Active l'exécution parallèle dans le mode collection.

.PARAMETER ThrottleLimit
Nombre maximal d'éléments exécutés en parallèle.

.PARAMETER ParallelThreshold
Nombre minimal d'éléments requis avant d'activer réellement le mode parallèle.

.OUTPUTS
Step
#>

function Get-InvokeStepModuleManifestPath {
    [CmdletBinding()]
    param()

    foreach ($candidate in @(
            (Join-Path $PSScriptRoot 'ITFabrik.Stepper.psd1'),
            (Join-Path (Split-Path -Parent $PSScriptRoot) 'ITFabrik.Stepper.psd1')
        )) {
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw 'Unable to resolve ITFabrik.Stepper.psd1 from the current module context.'
}

function Get-InvokeStepCapturedVariableMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ScriptBlock]$ScriptBlock
    )

    $captured = @{}
    $variableInfos = Get-InvokeStepExternalVariableInfo -ScriptBlock $ScriptBlock
    foreach ($variableInfo in $variableInfos) {
        $name = $variableInfo.LookupName
        if ([string]::IsNullOrWhiteSpace($name)) {
            continue
        }

        $variable = $null
        if ($ScriptBlock.Module) {
            $variable = $ScriptBlock.Module.SessionState.PSVariable.Get($name)
        }

        foreach ($scope in 0..10) {
            if ($null -ne $variable) {
                break
            }

            try {
                $variable = Get-Variable -Name $name -Scope $scope -ErrorAction Stop
            }
            catch {
                $variable = $null
            }

            if ($null -ne $variable) {
                break
            }
        }

        if ($null -eq $variable) {
            $variable = Get-Variable -Name $name -Scope Global -ErrorAction SilentlyContinue
        }

        if ($null -ne $variable) {
            $captured[$name] = $variable.Value
        }
    }

    return $captured
}

function Get-InvokeStepExternalVariableInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ScriptBlock]$ScriptBlock
    )

    $excluded = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($name in @(
            '_', 'PSItem', 'args', 'input', 'this', 'true', 'false', 'null',
            'PWD', 'HOME', 'PID', 'PSVersionTable', 'PSScriptRoot', 'PSCommandPath',
            'ExecutionContext', 'MyInvocation', 'PSBoundParameters', 'Matches', 'Error',
            'Host', 'VerbosePreference', 'DebugPreference', 'ErrorActionPreference',
            'WarningPreference', 'InformationPreference', 'ConfirmPreference', 'WhatIfPreference'
        )) {
        [void]$excluded.Add($name)
    }

    $paramNames = @()
    if ($ScriptBlock.Ast.ParamBlock) {
        $paramNames = @($ScriptBlock.Ast.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
        foreach ($paramName in $paramNames) {
            [void]$excluded.Add($paramName)
        }
    }

    $localDefinitions = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($assignmentAst in $ScriptBlock.Ast.FindAll({
                param($ast)
                $ast -is [System.Management.Automation.Language.AssignmentStatementAst]
            }, $true)) {
        $left = $assignmentAst.Left
        if ($left -is [System.Management.Automation.Language.VariableExpressionAst]) {
            $localName = $left.VariablePath.UserPath -replace '^(?i)(?:global|local|private|script):', ''
            if (-not [string]::IsNullOrWhiteSpace($localName)) {
                [void]$localDefinitions.Add($localName)
            }
        }
    }

    foreach ($foreachAst in $ScriptBlock.Ast.FindAll({
                param($ast)
                $ast -is [System.Management.Automation.Language.ForEachStatementAst]
            }, $true)) {
        if ($foreachAst.Variable -is [System.Management.Automation.Language.VariableExpressionAst]) {
            $localName = $foreachAst.Variable.VariablePath.UserPath -replace '^(?i)(?:global|local|private|script):', ''
            if (-not [string]::IsNullOrWhiteSpace($localName)) {
                [void]$localDefinitions.Add($localName)
            }
        }
    }

    $captured = [System.Collections.Generic.List[object]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $variableAsts = $ScriptBlock.Ast.FindAll({
            param($ast)
            $ast -is [System.Management.Automation.Language.VariableExpressionAst]
        }, $true)

    foreach ($variableAst in $variableAsts) {
        if ($variableAst.Splatted) { continue }

        $name = $variableAst.VariablePath.UserPath
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        if ($name -match '^(?i)env:') { continue }
        if ($excluded.Contains($name)) { continue }
        $lookupName = $name -replace '^(?i)(?:global|local|private|script):', ''
        if ([string]::IsNullOrWhiteSpace($lookupName)) { continue }
        if ($localDefinitions.Contains($lookupName)) { continue }

        $displayName = $variableAst.Extent.Text
        if ([string]::IsNullOrWhiteSpace($displayName)) {
            $displayName = '$' + $name
        }

        if ($seen.Add($displayName)) {
            [void]$captured.Add([pscustomobject]@{
                    LookupName = $lookupName
                    DisplayName = $displayName
                })
        }
    }

    return $captured
}

function Write-InvokeStepParallelContextWarning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ScriptBlock]$ScriptBlock
    )

    $externalVariables = @(Get-InvokeStepExternalVariableInfo -ScriptBlock $ScriptBlock)
    if ($externalVariables.Count -eq 0) {
        return
    }

    $variableList = @($externalVariables | ForEach-Object DisplayName) -join ', '
    Write-Warning ("Invoke-Step -Parallel detected external variable references in the ScriptBlock: {0}. Worker runspaces/jobs do not reliably preserve caller-local closure state. Prefer a self-contained ScriptBlock that depends on param(`$item, `$index) and explicit literal or recomputable data." -f $variableList)
}

function Get-InvokeStepChildName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BaseName,
        [Parameter(Mandatory)]$Item,
        [Parameter(Mandatory)][int]$Index
    )

    $itemLabel = $null
    if ($null -eq $Item) {
        $itemLabel = 'null'
    } elseif ($Item -is [string] -or $Item -is [ValueType]) {
        $itemLabel = [string]$Item
    }

    if ([string]::IsNullOrWhiteSpace($itemLabel)) {
        $itemLabel = "#{0}" -f ($Index + 1)
    }

    $itemLabel = ($itemLabel -replace '[\\/:*?"<>|]', '-').Trim()
    if ([string]::IsNullOrWhiteSpace($itemLabel)) {
        $itemLabel = "#{0}" -f ($Index + 1)
    }

    $name = "{0} [{1}]" -f $BaseName, $itemLabel
    if ($name.Length -gt 80) {
        $name = $name.Substring(0, 80).TrimEnd()
    }

    return $name
}

function ConvertTo-InvokeStepData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][Step]$Step
    )

    return [pscustomobject]@{
        Name = $Step.Name
        Status = $Step.Status
        Detail = $Step.Detail
        Level = $Step.Level
        ContinueOnError = $Step.ContinueOnError
        StartTime = $Step.StartTime
        EndTime = $Step.EndTime
        Duration = $Step.Duration
        Children = @($Step.Children | ForEach-Object { ConvertTo-InvokeStepData -Step $_ })
    }
}

function ConvertFrom-InvokeStepData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$StepData,
        [Step]$Parent = $null
    )

    $step = [Step]::new([string]$StepData.Name, $Parent, [bool]$StepData.ContinueOnError)
    $step.Status = [string]$StepData.Status
    $step.Detail = [string]$StepData.Detail
    $step.StartTime = [datetime]$StepData.StartTime
    $step.EndTime = if ($null -ne $StepData.EndTime -and [string]$StepData.EndTime -ne '') { [datetime]$StepData.EndTime } else { $null }
    $step.Duration = [TimeSpan]$StepData.Duration
    $step.Children.Clear()

    foreach ($childData in @($StepData.Children)) {
        [void](ConvertFrom-InvokeStepData -StepData $childData -Parent $step)
    }

    return $step
}

function Invoke-StepInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][bool]$ContinueOnError,
        [Parameter(Mandatory)][ScriptBlock]$ScriptBlock
    )

    $step = New-Step -Name $Name -ContinueOnError:$ContinueOnError
    $threw = $false
    $shouldThrow = $false
    $exception = $null
    $script:InsideStep = $true

    try {
        $null = & $ScriptBlock
    }
    catch {
        $threw = $true
        $exception = $_
        Set-Step -Status Error -Detail $_.Exception.Message | Out-Null
        $shouldThrow = -not $ContinueOnError
        if ($shouldThrow -and $step.ParentStep -and $step.ParentStep.ContinueOnError) {
            $shouldThrow = $false
        }
    }
    finally {
        $script:InsideStep = $false
        if (-not $threw) {
            Set-Step -Status Success | Out-Null
        }
        Complete-Step
    }

    return [pscustomobject]@{
        Step = $step
        Threw = $threw
        ShouldThrow = $shouldThrow
        Exception = $exception
    }
}

function Invoke-StepForEachWorker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StepName,
        [Parameter(Mandatory)][string]$ScriptText,
        [Parameter(Mandatory)][hashtable]$CapturedVariables,
        [Parameter(Mandatory)]$Item,
        [Parameter(Mandatory)][int]$Index,
        [Parameter(Mandatory)][bool]$ContinueOnError
    )

    foreach ($entry in $CapturedVariables.GetEnumerator()) {
        Set-Variable -Name $entry.Key -Value $entry.Value -Scope Local
    }

    $logEntries = [System.Collections.Generic.List[object]]::new()
    $previousCollector = $script:StepLogCollector
    $script:StepLogCollector = {
        param($entry)
        [void]$logEntries.Add((ConvertTo-StepLogEntry -Entry $entry))
    }
    try {
        $userScript = [scriptblock]::Create($ScriptText)
        $currentItem = $Item
        $currentIndex = $Index
        $result = Invoke-StepInternal -Name $StepName -ContinueOnError:$ContinueOnError -ScriptBlock {
            & $userScript $currentItem $currentIndex
        }
    }
    finally {
        $script:StepLogCollector = $previousCollector
    }

    return [pscustomobject]@{
        Index = $Index
        Threw = $result.Threw
        ShouldThrow = $result.ShouldThrow
        ErrorMessage = if ($null -ne $result.Exception) { $result.Exception.Exception.Message } else { $null }
        StepData = ConvertTo-InvokeStepData -Step $result.Step
        LogEntries = @($logEntries.ToArray())
    }
}

function Receive-InvokeStepJobResultSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.ArrayList]$Jobs
    )

    $results = @()
    foreach ($job in @($Jobs)) {
        $payload = Receive-Job -Job $job -Wait -AutoRemoveJob -ErrorAction SilentlyContinue
        if ($null -ne $payload) {
            $results += $payload
        }
        [void]$Jobs.Remove($job)
    }

    return $results
}

function Invoke-StepForEachParallelInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][object[]]$InputObject,
        [Parameter(Mandatory)][ScriptBlock]$ScriptBlock,
        [Parameter(Mandatory)][bool]$ContinueOnError,
        [Parameter(Mandatory)][int]$ThrottleLimit
    )

    $moduleManifestPath = Get-InvokeStepModuleManifestPath
    $scriptText = $ScriptBlock.ToString()
    Write-InvokeStepParallelContextWarning -ScriptBlock $ScriptBlock
    $capturedVariables = Get-InvokeStepCapturedVariableMap -ScriptBlock $ScriptBlock
    $parentStep = Get-CurrentStep
    $payloads = for ($index = 0; $index -lt $InputObject.Count; $index++) {
        [pscustomobject]@{
            Item = $InputObject[$index]
            Index = $index
            StepName = Get-InvokeStepChildName -BaseName $Name -Item $InputObject[$index] -Index $index
        }
    }

    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $results = $payloads | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
            $payload = $_
            try {
                Import-Module $using:moduleManifestPath -Force
                $module = Get-Module ITFabrik.Stepper

                & $module {
                    param($scriptText, $capturedVariables, $stepName, $item, $index, $continueOnError)
                    Invoke-StepForEachWorker -StepName $stepName -ScriptText $scriptText -CapturedVariables $capturedVariables -Item $item -Index $index -ContinueOnError:$continueOnError
                } $using:scriptText $using:capturedVariables $payload.StepName $payload.Item $payload.Index $using:ContinueOnError
            }
            catch {
                $now = Get-Date
                [pscustomobject]@{
                    Index = $payload.Index
                    Threw = $true
                    ShouldThrow = (-not $using:ContinueOnError)
                    ErrorMessage = $_.Exception.Message
                    StepData = [pscustomobject]@{
                        Name = $payload.StepName
                        Status = 'Error'
                        Detail = $_.Exception.Message
                        Level = 1
                        ContinueOnError = $using:ContinueOnError
                        StartTime = $now
                        EndTime = $now
                        Duration = [TimeSpan]::Zero
                        Children = @()
                    }
                }
            }
        }
    } else {
        $results = @()
        $jobs = [System.Collections.ArrayList]::new()
        $currentLocation = (Get-Location).Path
        $jobScript = {
            param($moduleManifestPath, $scriptText, $capturedVariables, $stepName, $item, $index, $continueOnError, $currentLocation)

            try {
                Set-Location -LiteralPath $currentLocation
                Import-Module $moduleManifestPath -Force
                $module = Get-Module ITFabrik.Stepper

                & $module {
                    param($scriptText, $capturedVariables, $stepName, $item, $index, $continueOnError)
                    Invoke-StepForEachWorker -StepName $stepName -ScriptText $scriptText -CapturedVariables $capturedVariables -Item $item -Index $index -ContinueOnError:$continueOnError
                } $scriptText $capturedVariables $stepName $item $index $continueOnError
            }
            catch {
                $now = Get-Date
                [pscustomobject]@{
                    Index = $index
                    Threw = $true
                    ShouldThrow = (-not $continueOnError)
                    ErrorMessage = $_.Exception.Message
                    StepData = [pscustomobject]@{
                        Name = $stepName
                        Status = 'Error'
                        Detail = $_.Exception.Message
                        Level = 1
                        ContinueOnError = $continueOnError
                        StartTime = $now
                        EndTime = $now
                        Duration = [TimeSpan]::Zero
                        Children = @()
                    }
                }
            }
        }

        foreach ($payload in $payloads) {
            while ($jobs.Count -ge $ThrottleLimit) {
                $completed = Wait-Job -Job @($jobs) -Any -Timeout 1
                if ($null -ne $completed) {
                    $results += Receive-Job -Job $completed -AutoRemoveJob -ErrorAction SilentlyContinue
                    [void]$jobs.Remove($completed)
                }
            }

            $job = Start-Job -ScriptBlock $jobScript -ArgumentList @(
                $moduleManifestPath,
                $scriptText,
                $capturedVariables,
                $payload.StepName,
                $payload.Item,
                $payload.Index,
                $ContinueOnError,
                $currentLocation
            )
            [void]$jobs.Add($job)
        }

        if ($jobs.Count -gt 0) {
            $results += Receive-InvokeStepJobResultSet -Jobs $jobs
        }
    }

    $orderedResults = @($results | Sort-Object Index)
    $firstFailure = $null

    foreach ($result in $orderedResults) {
        if ($null -ne $result.StepData) {
            [void](ConvertFrom-InvokeStepData -StepData $result.StepData -Parent $parentStep)
        }
        foreach ($logEntry in @($result.LogEntries)) {
            Write-StepLogEntry -Entry $logEntry
        }
        if ($result.ShouldThrow -and [string]::IsNullOrWhiteSpace($firstFailure)) {
            $firstFailure = $result.ErrorMessage
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($firstFailure)) {
        throw $firstFailure
    }
}

function Invoke-StepForEachSequentialInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][object[]]$InputObject,
        [Parameter(Mandatory)][ScriptBlock]$ScriptBlock,
        [Parameter(Mandatory)][bool]$ContinueOnError
    )

    $userScriptBlock = $ScriptBlock

    for ($index = 0; $index -lt $InputObject.Count; $index++) {
        $item = $InputObject[$index]
        $childName = Get-InvokeStepChildName -BaseName $Name -Item $item -Index $index
        $result = Invoke-StepInternal -Name $childName -ContinueOnError:$ContinueOnError -ScriptBlock {
            & $userScriptBlock $item $index
        }

        if ($result.ShouldThrow) {
            throw $result.Exception
        }
    }
}

function Invoke-Step {
    [CmdletBinding()]
    [OutputType('Step')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if ($_.Length -gt 80) { throw "Le nom de l'étape ne doit pas dépasser 80 caractères." }
            if ($_ -match '[\\/:*?"<>|]') { throw "Le nom de l'étape contient des caractères interdits (\\ / : * ? \"" < > |)." }
            return $true
        })]
        [string]$Name,

        [switch]$ContinueOnError = $false,

        [Parameter(Mandatory)]
        [ScriptBlock]$ScriptBlock,

        [Alias('Items')]
        [object[]]$InputObject,

        [switch]$Parallel,

        [Alias('Threshold')]
        [ValidateRange(1, 2147483647)]
        [int]$ParallelThreshold = 2,

        [ValidateRange(1, 2147483647)]
        [int]$ThrottleLimit = 5,

        [switch]$PassThru
    )

    $isCollectionMode = $PSBoundParameters.ContainsKey('InputObject')
    $continueOnErrorEnabled = [bool]$ContinueOnError
    $userScriptBlock = $ScriptBlock

    if (-not $isCollectionMode -and $Parallel.IsPresent) {
        throw 'The -Parallel option requires -InputObject.'
    }

    if (-not $isCollectionMode) {
        $result = Invoke-StepInternal -Name $Name -ContinueOnError:$continueOnErrorEnabled -ScriptBlock $userScriptBlock
        if ($result.Threw -and $result.ShouldThrow) {
            throw $result.Exception
        }
        if ($PassThru) {
            return $result.Step
        }
        return
    }

    $items = @($InputObject)
    $useParallel = $Parallel.IsPresent -and $items.Count -ge $ParallelThreshold
    $result = Invoke-StepInternal -Name $Name -ContinueOnError:$continueOnErrorEnabled -ScriptBlock {
        if ($useParallel) {
            Invoke-StepForEachParallelInternal -Name $Name -InputObject $items -ScriptBlock $userScriptBlock -ContinueOnError:$continueOnErrorEnabled -ThrottleLimit $ThrottleLimit
        } else {
            Invoke-StepForEachSequentialInternal -Name $Name -InputObject $items -ScriptBlock $userScriptBlock -ContinueOnError:$continueOnErrorEnabled
        }
    }

    if ($result.Threw -and $result.ShouldThrow) {
        throw $result.Exception
    }
    if ($PassThru) {
        return $result.Step
    }
}
