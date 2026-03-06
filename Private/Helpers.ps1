# Initialisation du flag d'exécution interne d'un Step
if ($null -eq $script:InsideStep) { $script:InsideStep = $false }
if ($null -eq $script:StepLogCollector) { $script:StepLogCollector = $null }

<#
.SYNOPSIS
Affiche un message d'étape avec indentation.

.DESCRIPTION
Affiche un message d'étape à l'écran, en gris, avec un niveau d'indentation optionnel.

.PARAMETER Message
Le message à afficher.

.PARAMETER IndentLevel
Niveau d'indentation (nombre d'espaces).
#>
function Get-StepManagerLogger {
    [CmdletBinding()]
    param()

    $currentScopeVariable = Get-Variable -Name 'StepManagerLogger' -ErrorAction SilentlyContinue
    if ($null -ne $currentScopeVariable) {
        return $currentScopeVariable.Value
    }

    foreach ($scope in @('Script', 'Global')) {
        $variable = Get-Variable -Name 'StepManagerLogger' -Scope $scope -ErrorAction SilentlyContinue
        if ($null -ne $variable) {
            return $variable.Value
        }
    }

    return $null
}

function ConvertTo-StepLogEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Entry
    )

    $timestamp = if ($Entry.PSObject.Properties.Match('Timestamp').Count -gt 0 -and $null -ne $Entry.Timestamp) {
        [datetime]$Entry.Timestamp
    } else {
        Get-Date
    }

    return [pscustomobject]@{
        Timestamp = $timestamp
        Source = [string]$Entry.Source
        Component = [string]$Entry.Component
        Message = [string]$Entry.Message
        Severity = [string]$Entry.Severity
        IndentLevel = [int]$Entry.IndentLevel
        StepName = if ($Entry.PSObject.Properties.Match('StepName').Count -gt 0) { [string]$Entry.StepName } else { '' }
        ForegroundColor = if ($Entry.PSObject.Properties.Match('ForegroundColor').Count -gt 0) { [string]$Entry.ForegroundColor } else { '' }
    }
}

function Write-StepLogEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Entry
    )

    $normalizedEntry = ConvertTo-StepLogEntry -Entry $Entry
    $collector = $script:StepLogCollector
    if ($null -ne $collector) {
        & $collector $normalizedEntry
        return
    }

    $logger = Get-StepManagerLogger
    if ($null -eq $logger) {
        if ($normalizedEntry.Source -eq 'User') {
            Write-StepMessage -Severity $normalizedEntry.Severity -Message $normalizedEntry.Message -IndentLevel $normalizedEntry.IndentLevel -StepName $normalizedEntry.StepName -Timestamp $normalizedEntry.Timestamp -ForegroundColor $normalizedEntry.ForegroundColor
        } else {
            Write-StepMessage -Severity $normalizedEntry.Severity -Message ("[{0}] {1}" -f $normalizedEntry.Component, $normalizedEntry.Message) -IndentLevel $normalizedEntry.IndentLevel -Timestamp $normalizedEntry.Timestamp
        }
    } else {
        & $logger $normalizedEntry.Component $normalizedEntry.Message $normalizedEntry.Severity $normalizedEntry.IndentLevel
    }
}

function Write-StepMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Severity,
        [Parameter(Mandatory)] [string]$Message,
        [int]$IndentLevel = 0,
        [string]$StepName = '',
        [datetime]$Timestamp,
        [string]$ForegroundColor
    )

    # Détection de PowerShell 7+
    $isPwsh7 = $PSVersionTable.PSVersion.Major -ge 7

    # Dictionnaire d'icônes par sévérité (Unicode, fallback via [Severity] si non supporté)
    $icons = @{
        'Info'    = 'ℹ'
        'Success' = '✓'
        'Warning' = '⚠'
        'Error'   = '✖'
        'Debug'   = '⚙'
        'Verbose' = '…'
    }

    $prefixRaw = if ($isPwsh7 -and $icons.ContainsKey($Severity)) { $icons[$Severity] } else { "[$Severity]" }
    # Padding spécifique par sévérité pour un alignement optimal
    $nbsp = [char]0x2007
    function Get-NbspString($count) { [string]::new(@($nbsp) * $count) }
    
    switch ($Severity) {
        'Info'    { $prefix = $prefixRaw + (Get-NbspString 4) ; $ForegroundColor = if(-not $ForegroundColor){ 'Gray'} else{$ForegroundColor} }
        'Success' { $prefix = $prefixRaw + (Get-NbspString 3) ; $ForegroundColor = if(-not $ForegroundColor){ 'Green'} else{$ForegroundColor}}
        'Warning' { $prefix = $prefixRaw + (Get-NbspString 4) ; $ForegroundColor = if(-not $ForegroundColor){ 'Yellow'} else{$ForegroundColor}}
        'Error'   { $prefix = $prefixRaw + (Get-NbspString 3) ; $ForegroundColor = if(-not $ForegroundColor){ 'Red'} else{$ForegroundColor}}
        'Debug'   { $prefix = $prefixRaw + (Get-NbspString 3) ; $ForegroundColor = if(-not $ForegroundColor){ 'Cyan'} else{$ForegroundColor}}
        'Verbose' { $prefix = $prefixRaw + (Get-NbspString 3) ; $ForegroundColor = if(-not $ForegroundColor){ 'Magenta'} else{$ForegroundColor}}
        default   { $prefix = $prefixRaw + (Get-NbspString 3) ; $ForegroundColor = if(-not $ForegroundColor){ 'White'} else{$ForegroundColor}}
    }

    $indent = if ($IndentLevel -gt 0) { ' ' * ($IndentLevel * 2) } else { '' }
    $effectiveTimestamp = if ($PSBoundParameters.ContainsKey('Timestamp')) { $Timestamp } else { Get-Date }
    $now = $effectiveTimestamp.ToString('yyyy-MM-dd HH:mm:ss')
    $step = if ($StepName) { "[$StepName]" } else { '' }
    # Ne plus afficher le Component ici pour éviter la duplication d'étiquettes
    $text = "[$now] $prefix$indent$step $Message"
    Write-Host $text -ForegroundColor $ForegroundColor
}
