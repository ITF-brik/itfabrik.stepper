<#
.SYNOPSIS
Exécute un bloc de script dans une étape avec gestion d'état, d'imbrication et d'erreur.

.DESCRIPTION
Encapsule l'exécution d'un ScriptBlock dans une étape typée, avec gestion du statut (Success, Error), imbrication et option de poursuite sur erreur. Les messages sont affichés en gris par défaut.

.PARAMETER Name
Nom de l'étape à exécuter.

.PARAMETER ScriptBlock
Bloc de code à exécuter dans l'étape.

.PARAMETER ContinueOnError
Indique si l'exécution doit continuer en cas d'erreur dans l'étape. Par défaut : $false.

.OUTPUTS
Step

.EXAMPLE
Invoke-Step -Name 'Préparation' -ScriptBlock {
    # Instructions de préparation
}

.EXAMPLE
Invoke-Step -Name 'Installation' -ScriptBlock {
    Invoke-Step -Name 'Télécharger' -ScriptBlock {
        # Téléchargement
    } -ContinueOnError

    Invoke-Step -Name 'Configurer' -ScriptBlock {
        # Configuration
    }
}

.EXAMPLE
$items = 'A', 'B', 'C'
$steps = foreach ($item in $items) {
    Invoke-Step -Name "Traitement $item" -ScriptBlock {
        # Traitement spécifique à $item
        "Traitement de $item terminé."
    }
}
# $steps contient la liste des objets Step pour chaque élément

.EXAMPLE
Invoke-Step -Name 'Exemple' -ScriptBlock {
    throw 'Erreur volontaire'
} -ContinueOnError
# L'étape sera en statut 'Error', mais l'exécution continue

Invoke-Step -Name 'Exemple' -ScriptBlock {
    throw 'Erreur volontaire'
}
# L'étape sera en statut 'Error' (propagation possible selon le parent)

#>
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
        [switch]$PassThru
    )

    # Autoriser les ScriptBlock vides (no-op)
    $step = New-Step -Name $Name -ContinueOnError:$ContinueOnError.IsPresent
    $errorDetail = $null
    $threw = $false
    $shouldThrow = $false
    $script:InsideStep = $true
    try {
        $null = & $ScriptBlock
    }
    catch {
        $threw = $true
        $errorDetail = $_.Exception.Message
        Set-Step -Status Error -Detail $errorDetail | Out-Null
        # Propagation contrôlée
        $shouldThrow = -not $ContinueOnError.IsPresent
        if ($shouldThrow -and $step.ParentStep -and $step.ParentStep.ContinueOnError) {
            $shouldThrow = $false
        }
    }
    finally {
        $script:InsideStep = $false
        if (-not $threw) { Set-Step -Status Success | Out-Null }
        Complete-Step
    }
    if ($threw -and $shouldThrow) { throw }
    if ($PassThru) { return $step }
}

