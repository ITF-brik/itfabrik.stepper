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
        Invoke-Logger -Component 'StepManager' -Severity 'Error' -Message "Erreur dans l'étape [$($current.Name)] : $Detail" -IndentLevel ($current.Level)
    }
}

