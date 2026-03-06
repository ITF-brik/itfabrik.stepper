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
        [Parameter(Mandatory=$false)] [ValidateSet('Info','Success','Warning','Error','Debug','Verbose')] [string]$Severity = 'Info'
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
    
    $component = if ($null -ne $currentStep -and -not [string]::IsNullOrWhiteSpace($currentStep.Name)) {
        $currentStep.Name
    } else {
        'StepManager'
    }

    Write-StepLogEntry -Entry ([pscustomobject]@{
            Source = 'User'
            Component = $component
            Message = $Message
            Severity = $Severity
            IndentLevel = $finalIndent
            StepName = if ($null -ne $currentStep) { $currentStep.Name } else { '' }
            ForegroundColor = $ForegroundColor
        })
}
