<#
.SYNOPSIS
Crée une nouvelle étape et la pousse dans la pile d'exécution.

.DESCRIPTION
Crée un objet Step, gère l'imbrication et l'état, et affiche le nom de l'étape. Les messages sont affichés en gris par défaut.

.PARAMETER Name
Nom de l'étape à créer.

.PARAMETER ContinueOnError
Indique si l'exécution doit continuer en cas d'erreur dans l'étape.

.OUTPUTS
Step
#>
function New-Step {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string]$Name,
        [switch]$ContinueOnError
    )

    $parent = Get-CurrentStep
    $step = [Step]::new($Name, $parent, $ContinueOnError.IsPresent)

    Push-Step -Step $step

    Invoke-Logger -Component 'StepManager' -Message "Création de l'étape : $Name" -Severity 'Information' -IndentLevel $step.Level

    return $step
}

