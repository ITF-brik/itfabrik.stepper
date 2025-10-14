# Module-scoped state and helpers (not exported)

if (-not $script:StepStack) { $script:StepStack = New-Object System.Collections.Stack }
if (-not $script:StepStateLock) { $script:StepStateLock = New-Object object }

function Push-Step {
    param([Step]$Step)
    [System.Threading.Monitor]::Enter($script:StepStateLock)
    try { $null = $script:StepStack.Push($Step) }
    finally { [System.Threading.Monitor]::Exit($script:StepStateLock) }
}

function Pop-Step {
    [System.Threading.Monitor]::Enter($script:StepStateLock)
    try { if ($script:StepStack.Count -gt 0) { return $script:StepStack.Pop() } }
    finally { [System.Threading.Monitor]::Exit($script:StepStateLock) }
}

function Peek-Step {
    [System.Threading.Monitor]::Enter($script:StepStateLock)
    try { if ($script:StepStack.Count -gt 0) { return $script:StepStack.Peek() } }
    finally { [System.Threading.Monitor]::Exit($script:StepStateLock) }
}

# (Removed) StopExecution flag was unused; keeping state minimal
