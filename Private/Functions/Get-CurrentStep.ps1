function Get-CurrentStep {
    [CmdletBinding()] param()
    return (Get-StepStackTop)
}
