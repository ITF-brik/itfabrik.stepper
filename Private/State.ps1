# Module-scoped state and helpers (not exported)

if (-not $script:StepStack) {
    $script:StepStack = New-Object System.Collections.Stack
}

function Push-Step {
    param([Step]$Step)
    $null = $script:StepStack.Push($Step)
}

function Pop-Step {
    if ($script:StepStack.Count -gt 0) { return $script:StepStack.Pop() }
}

function Peek-Step {
    if ($script:StepStack.Count -gt 0) { return $script:StepStack.Peek() }
}

# (Removed) StopExecution flag was unused; keeping state minimal
