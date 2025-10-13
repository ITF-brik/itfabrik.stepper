# Initialisation du flag d'exécution interne d'un Step
if ($null -eq $script:InsideStep) { $script:InsideStep = $false }

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
function Write-StepMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$prefix,
        [Parameter(Mandatory)] [string]$Message,
        [int]$IndentLevel = 0
    )

    $indent = if ($IndentLevel -gt 0) { ' ' * ($IndentLevel * 2) } else { '' }
    $text = "$prefix${indent}$Message"
    Write-Host $text -ForegroundColor Gray
}

# Appelle le logger injecté via VariableManager, ou fallback sur Write-StepMessage
function  Invoke-Logger{
    param(
        [Parameter(Mandatory)] [string]$Component,
        [Parameter(Mandatory)] [string]$Message,
        [Parameter(Mandatory)] [ValidateSet('Information','Warning','Error')] [string]$Severity,
        [int]$IndentLevel = 0
    )
    $logger = $null
    $finalIndent = $IndentLevel
    if ($script:InsideStep) { $finalIndent++ }
    try {
        # On tente de récupérer le logger depuis en utilisant le module PSVariableManager
        $logger = Get-PSVariable -Name 'StepManagerLogger' -ErrorAction Stop
    } catch {
        $logger = (Get-Variable -Name 'StepManagerLogger' -Scope Script -ErrorAction SilentlyContinue).Value
    }
    if ($null -eq $logger) {
        # Fallback simple : affichage console avec formalisme
        $prefix = "[$Component][$Severity]"
        Write-StepMessage -Prefix $prefix -Message $Message -IndentLevel $finalIndent
    } else {
        & $logger $Component $Message $Severity $finalIndent
    }
}


