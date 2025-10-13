function Complete-Step {
    [CmdletBinding()]
    param()

    $current = Get-CurrentStep
    if ($current) { $current.EndTime = Get-Date }

    # Pop current step and restore parent (if any)
    $null = Pop-Step
}

