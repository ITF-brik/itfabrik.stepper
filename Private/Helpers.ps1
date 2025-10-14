# Initialisation du flag d'exécution interne d'un Step
if ($null -eq $script:InsideStep) { $script:InsideStep = $false }

<#
.SYNOPSIS
Affiche un message d'étape avec indentation.

.DESCRIPTION
Affiche un message d'étape à l'écran, en gris, avec un niveau d'indentation optionnel.

.PARAMETER Message
Le message à afficher.

.PARAMETER IndentLevel
Niveau d'indentation (nombre d'espaces).
#>
function Write-StepMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Severity,
        [Parameter(Mandatory)] [string]$Message,
        [int]$IndentLevel = 0,
        [string]$StepName = '',
        [string]$Component = '',
        [string]$ForegroundColor
    )

    # Détection de PowerShell 7+
    $isPwsh7 = $PSVersionTable.PSVersion.Major -ge 7

    # Dictionnaire d'icônes par sévérité (Unicode, fallback via [Severity] si non supporté)
    $icons = @{
        'Info'    = 'ℹ'
        'Success' = '✓'
        'Warning' = '⚠'
        'Error'   = '✖'
        'Debug'   = '⚙'
        'Verbose' = '…'
    }

    $prefixRaw = if ($isPwsh7 -and $icons.ContainsKey($Severity)) { $icons[$Severity] } else { "[$Severity]" }
    # Padding spécifique par sévérité pour un alignement optimal
    $nbsp = [char]0x2007
    function Get-NbspString($count) { [string]::new(@($nbsp) * $count) }
    
    switch ($Severity) {
        'Info'    { $prefix = $prefixRaw + (Get-NbspString 4) ; $ForegroundColor = if(-not $ForegroundColor){ 'Gray'} else{$ForegroundColor} }
        'Success' { $prefix = $prefixRaw + (Get-NbspString 3) ; $ForegroundColor = if(-not $ForegroundColor){ 'Green'} else{$ForegroundColor}}
        'Warning' { $prefix = $prefixRaw + (Get-NbspString 4) ; $ForegroundColor = if(-not $ForegroundColor){ 'Yellow'} else{$ForegroundColor}}
        'Error'   { $prefix = $prefixRaw + (Get-NbspString 3) ; $ForegroundColor = if(-not $ForegroundColor){ 'Red'} else{$ForegroundColor}}
        'Debug'   { $prefix = $prefixRaw + (Get-NbspString 3) ; $ForegroundColor = if(-not $ForegroundColor){ 'Cyan'} else{$ForegroundColor}}
        'Verbose' { $prefix = $prefixRaw + (Get-NbspString 3) ; $ForegroundColor = if(-not $ForegroundColor){ 'Magenta'} else{$ForegroundColor}}
        default   { $prefix = $prefixRaw + (Get-NbspString 3) ; $ForegroundColor = if(-not $ForegroundColor){ 'White'} else{$ForegroundColor}}
    }

    $indent = if ($IndentLevel -gt 0) { ' ' * ($IndentLevel * 2) } else { '' }
    $now = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    $step = if ($StepName) { "[$StepName]" } else { '' }
    # Ne plus afficher le Component ici pour éviter la duplication d'étiquettes
    $text = "[$now] $prefix$indent$step $Message"
    Write-Host $text -ForegroundColor $ForegroundColor
}

