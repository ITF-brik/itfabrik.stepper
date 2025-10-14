function Complete-Step {
    [CmdletBinding()]
    param()

    $current = Get-CurrentStep
    if ($current) {
        $current.EndTime = Get-Date
        try { $current.Duration = ($current.EndTime - $current.StartTime) } catch { }
    }

    Invoke-Logger -Component 'StepManager' -Severity 'Verbose' -Message "Étape [$($current.Name)] terminée." -IndentLevel ($current.Level)


    # Dépile le niveau d'indentation contextuel (protégé pour runspace)
    [System.Threading.Monitor]::Enter($script:StepStateLock)
    try {
        if ($script:CurrentStepIndentStack) {
            $script:CurrentStepIndentStack = $script:CurrentStepIndentStack[0..($script:CurrentStepIndentStack.Count-2)]
            if ($script:CurrentStepIndentStack.Count -eq 0) {
                Remove-Variable -Name CurrentStepIndentStack -Scope Script -ErrorAction SilentlyContinue
            }
        }
    } finally { [System.Threading.Monitor]::Exit($script:StepStateLock) }

    # Pop current step and restore parent (if any)
    $null = Pop-Step
}
