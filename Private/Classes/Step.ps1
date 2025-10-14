
class Step {
    [string]$Name
    [ValidateSet('Pending','Success','Error')]
    [string]$Status = 'Pending'
    [int]$Level = 0
    [Step]$ParentStep = $null
    [System.Collections.Generic.List[Step]]$Children = [System.Collections.Generic.List[Step]]::new()
    [string]$Detail = ''
    [bool]$ContinueOnError = $false
    [datetime]$StartTime
    [Nullable[datetime]]$EndTime
    [TimeSpan]$Duration = [TimeSpan]::Zero

    Step([string]$Name, [Step]$ParentStep = $null, [bool]$ContinueOnError = $false) {
        $this.Name = $Name
        $this.Status = 'Pending'
        $this.Detail = ''
        $this.ParentStep = $ParentStep
        $this.Level = if ($ParentStep) { $ParentStep.Level + 1 } else { 0 }
        $this.ContinueOnError = $ContinueOnError
        $this.StartTime = Get-Date
        $this.EndTime = $null
        if ($ParentStep) {
            $ParentStep.Children.Add($this)
        }
    }

    [string] ToString() {
        $dur = if ($this.EndTime) { ($this.EndTime - $this.StartTime) } else { [TimeSpan]::Zero }
        return "{0} [{1}] L{2} ({3:c})" -f $this.Name, $this.Status, $this.Level, $dur
    }
}
