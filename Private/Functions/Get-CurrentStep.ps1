function Get-CurrentStep {
    [CmdletBinding()] param()
    return (Peek-Step)
}

