<#
.SYNOPSIS
    Centralise l'affichage des messages de log pour StepManager.
.DESCRIPTION
    Permet d'afficher des messages typés (Info, Success, Warning, Error, Debug, Verbose) avec indentation et support d'un logger personnalisé.
    Si aucun logger n'est défini, affiche le message formaté dans la console.
    Les messages Debug ne sont affichés que si $DebugPreference le permet.
.PARAMETER Component
    Nom du composant ou de l'étape à l'origine du message.
.PARAMETER Message
    Le message à afficher.
.PARAMETER Severity
    Le niveau de sévérité du message : Info, Success, Warning, Error, Debug, Verbose.
.PARAMETER IndentLevel
    Niveau d'indentation pour l'affichage (entier, optionnel).
#>
function Invoke-Logger {
    param(
        [Parameter(Mandatory)] [string]$Component,
        [Parameter(Mandatory)] [string]$Message,
        [Parameter(Mandatory)] [ValidateSet('Info','Success','Warning','Error','Debug','Verbose')] [string]$Severity,
        [int]$IndentLevel = [int]::MinValue
    )
    $logger = $null
    # Indentation: respecte une valeur explicite sinon calcule depuis la step courante
    $explicitIndent = ($IndentLevel -ne [int]::MinValue)
    $finalIndent = if ($explicitIndent) { $IndentLevel } else { 0 }
    if (-not $explicitIndent) {
        if ($script:InsideStep) {
            try {
                $currentStep = Get-CurrentStep
                if ($null -ne $currentStep) { $finalIndent = $currentStep.Level + 1 } else { $finalIndent = 1 }
            } catch { $finalIndent = 1 }
        }
    }
    # Gestion du niveau Debug et Verbose
    if ($Severity -eq 'Debug') { if ($DebugPreference -eq 'SilentlyContinue') { return } }
    if ($Severity -eq 'Verbose') { if ($VerbosePreference -eq 'SilentlyContinue') { return } }
    try {
        $logger = Get-PSVariable -Name 'StepManagerLogger' -ErrorAction Stop
    } catch {
        $logger = $null
        try {
            $logger = (Get-Variable -Name 'StepManagerLogger' -Scope Script -ErrorAction Stop).Value
        } catch {
            try {
                $logger = (Get-Variable -Name 'StepManagerLogger' -Scope Global -ErrorAction Stop).Value
            } catch {}
        }
    }
    if ($null -eq $logger) {
        Write-StepMessage -Severity $Severity -Message ("[$Component] $Message") -IndentLevel $finalIndent
    } else {
        & $logger $Component $Message $Severity $finalIndent
    }
}

