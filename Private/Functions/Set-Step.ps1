function Set-Step {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [ValidateSet('Pending','Success','Error')] [string]$Status,
        [string]$Detail = ''
    )

    $current = Get-CurrentStep
    if (-not $current) { return }

    $current.Status = $Status
    $current.Detail = $Detail

    if ($Status -eq 'Error') {
        # Laisser l'auto-indentation gérer le niveau quand non spécifié
        Invoke-Logger -Component 'StepManager' -Severity 'Error' -Message "Erreur dans l'étape [$($current.Name)] : $Detail"
    }
    else{
        Invoke-Logger -Component 'StepManager' -Severity 'Verbose' -Message "Étape [$($current.Name)] définie sur le statut : $Status"
    }
}

