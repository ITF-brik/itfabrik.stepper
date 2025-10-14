<#
.SYNOPSIS
    Fonction publique pour écrire un message de log utilisateur dans StepManager.
.DESCRIPTION
    Permet à l'utilisateur d'écrire un message dans le log StepManager, avec un niveau d'indentation adapté pour les logs utilisateurs (toujours un cran de plus que la Step courante).
.PARAMETER Message
    Le message à afficher.
.PARAMETER Severity
    Le niveau de sévérité du message : Info, Success, Warning, Error, Debug, Verbose.
.EXAMPLE
    Write-Log -Message 'Début du traitement' -Severity 'Info'
#>
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Message,
        [Parameter(Mandatory)] [ValidateSet('Info','Success','Warning','Error','Debug','Verbose')] [string]$Severity
    )
    
    try {
        $currentStep = Get-CurrentStep
        if ($null -ne $currentStep) {
            $finalIndent = $currentStep.Level + 1
        } else {
            $finalIndent = 1
        }
    } catch {
        $finalIndent = 1
    }

    if ($Severity -eq 'Info') {
        $ForegroundColor = 'DarkGray'
    }
    
    $logger = $null
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
        # Affiche uniquement le StepName pour éviter la duplication [Step][Component]
        Write-StepMessage -Severity $Severity -Message $Message -IndentLevel $finalIndent -StepName $($currentStep.Name) -ForegroundColor $ForegroundColor
    } else {
        & $logger $($currentStep.Name) $Message $Severity $finalIndent
    }
}

