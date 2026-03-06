# itfabrik.stepper

## Documentation
- Vue d’ensemble et guides: `docs/index.md`
- Workflow projet: `docs/development-cycle.md`

[![CI](https://github.com/ITF-brik/itfabrik.stepper/actions/workflows/ci.yml/badge.svg)](https://github.com/ITF-brik/itfabrik.stepper/actions/workflows/ci.yml)
[![PS Gallery Version](https://img.shields.io/powershellgallery/v/ITFabrik.Stepper.svg?style=flat)](https://www.powershellgallery.com/packages/ITFabrik.Stepper)
[![PS Gallery Downloads](https://img.shields.io/powershellgallery/dt/ITFabrik.Stepper.svg?style=flat)](https://www.powershellgallery.com/packages/ITFabrik.Stepper)
[![Release](https://img.shields.io/github/v/release/ITF-brik/itfabrik.stepper?display_name=tag&sort=semver)](https://github.com/ITF-brik/itfabrik.stepper/releases)
[![License](https://img.shields.io/badge/License-Apache--2.0-blue.svg)](LICENSE)

ITFabrik.Stepper est un module PowerShell pour encapsuler des étapes d'exécution avec gestion d'état (Pending/Success/Error), imbrication, logging personnalisable et gestion d'erreurs (`ContinueOnError`).

---

## Installation

- Depuis PowerShell Gallery (recommandé):

```powershell
Install-Module ITFabrik.Stepper -Scope CurrentUser -Force
# Puis si nécessaire
Import-Module ITFabrik.Stepper -Force
```

- Mise à jour:

```powershell
Update-Module ITFabrik.Stepper
```

- Installation manuelle depuis les sources du depot:

```powershell
git clone https://github.com/ITF-brik/itfabrik.stepper.git
Set-Location .\itfabrik.stepper
Import-Module .\ITFabrik.Stepper.psd1 -Force
```

---

## Fonctionnalités

- Étapes avec statut et détails
- Imbrication (sous-étapes)
- Logging console et logger personnalisable
- Fonction publique **Write-Log** pour journalisation utilisateur
- Gestion d'erreur configurable (`ContinueOnError`)
- Traitement natif d'une collection avec une sous-étape par élément
- Parallélisation optionnelle compatible PowerShell 5.1 et PowerShell 7
- Retour d'objets typés pour chaque étape

## Exemples d'utilisation

### Étape simple

```powershell
Invoke-Step -Name 'Préparation' -ScriptBlock {
    # Instructions de préparation
}
```

### Utilisation de Write-Log (recommandé pour les scripts utilisateurs)

```powershell
Write-Log -Message 'Début du traitement' -Severity Info
Write-Log -Message 'Traitement terminé' -Severity Success
```

> Seuls les messages Verbose sont affichés si `$VerbosePreference` le permet.

#### Exemple d'affichage console attendu (PowerShell 7+, console UTF‑8)

```text
[2025-10-14 14:00:00] ℹ    [Préparation] Démarrage de l'étape : Préparation
[2025-10-14 14:00:01] ✓   [Préparation] Étape terminée : Préparation
```

### Étapes imbriquées avec gestion d'erreur

```powershell
Invoke-Step -Name 'Installation' -ContinueOnError:$true -ScriptBlock {
    Invoke-Step -Name 'Télécharger' -ScriptBlock {
        # Téléchargement
    }

    Invoke-Step -Name 'Configurer' -ContinueOnError:$false -ScriptBlock {
        # Configuration
    }
}
```

#### Exemple d'affichage console attendu

```text
[2025-10-14 14:00:00] ℹ    [Installation] Démarrage de l'étape : Installation
[2025-10-14 14:00:00] ℹ      [Télécharger] Démarrage de l'étape : Télécharger
[2025-10-14 14:00:01] ✓     [Télécharger] Étape terminée : Télécharger
[2025-10-14 14:00:01] ℹ      [Configurer] Démarrage de l'étape : Configurer
[2025-10-14 14:00:02] ✓     [Configurer] Étape terminée : Configurer
[2025-10-14 14:00:02] ✓   [Installation] Étape terminée : Installation
```

### Traitement d'une liste d'elements

```powershell
$items = 'A','B','C'
$batch = Invoke-Step -Name 'Traitement des elements' -InputObject $items -PassThru -ScriptBlock {
    param($item, $index)

    Invoke-Step -Name "Validation $index $item" -ScriptBlock {
        Write-Log -Message "Traitement de $item" -Severity Info
    }
}

# $batch représente l'etape parente
# $batch.Children contient une sous-etape par element:
# - Traitement des elements [A]
# - Traitement des elements [B]
# - Traitement des elements [C]
```

#### Exemple d'affichage console attendu

```text
[2025-10-14 14:00:00] ℹ    [Traitement des elements] Démarrage de l'étape : Traitement des elements
[2025-10-14 14:00:00] ℹ      [Traitement des elements [A]] Démarrage de l'étape : Traitement des elements [A]
[2025-10-14 14:00:00] ℹ        [Validation 0 A] Traitement de A
[2025-10-14 14:00:00] ✓       [Traitement des elements [A]] Étape terminée : Traitement des elements [A]
[2025-10-14 14:00:01] ℹ      [Traitement des elements [B]] Démarrage de l'étape : Traitement des elements [B]
[2025-10-14 14:00:01] ℹ        [Validation 1 B] Traitement de B
[2025-10-14 14:00:01] ✓       [Traitement des elements [B]] Étape terminée : Traitement des elements [B]
[2025-10-14 14:00:02] ℹ      [Traitement des elements [C]] Démarrage de l'étape : Traitement des elements [C]
[2025-10-14 14:00:02] ℹ        [Validation 2 C] Traitement de C
[2025-10-14 14:00:02] ✓       [Traitement des elements [C]] Étape terminée : Traitement des elements [C]
[2025-10-14 14:00:02] ✓   [Traitement des elements] Étape terminée : Traitement des elements
```

### Traitement parallele d'une liste

```powershell
$servers = 'srv-01','srv-02','srv-03','srv-04'

$batch = Invoke-Step -Name 'Controle des serveurs' `
    -InputObject $servers `
    -Parallel `
    -ParallelThreshold 3 `
    -ThrottleLimit 2 `
    -PassThru `
    -ScriptBlock {
        param($server, $index)

        Invoke-Step -Name "Ping $server" -ScriptBlock {
            Write-Log -Message "Verification du serveur #$index : $server" -Severity Info
            Start-Sleep -Milliseconds 200
        }
    }
```

Points a retenir:
- Sans `-Parallel`, l'execution reste sequentielle.
- `-ParallelThreshold` evite d'activer le parallelisme pour de petites listes.
- En PowerShell 7, le module utilise `ForEach-Object -Parallel`.
- En Windows PowerShell 5.1, le module utilise `Start-Job`.
- Le `ScriptBlock` recoit toujours `param($item, $index)`.

### Gestion d'erreur

```powershell
Invoke-Step -Name 'Exemple' -ContinueOnError:$true -ScriptBlock {
    Write-Log -Message 'Démarrage du téléchargement...' -Severity 'Info'
    throw 'Erreur volontaire'
} -PassThru
# L'étape sera en statut 'Error', mais l'exécution continue

Invoke-Step -Name 'Exemple' -ContinueOnError:$false -ScriptBlock {
    throw 'Erreur volontaire'
} -PassThru
# L'étape sera en statut 'Error'
```

#### Exemple d'affichage console attendu

```text
[2025-10-14 14:00:00] ℹ    [Exemple] Démarrage de l'étape : Exemple
[2025-10-14 14:00:40] ℹ      [Télécharger] Démarrage du téléchargement...
[2025-10-14 14:00:00] ✖   [Exemple] Erreur dans l'étape [Exemple] : Erreur volontaire
[2025-10-14 14:00:01] ℹ     [Exemple] Démarrage de l'étape : Exemple
[2025-10-14 14:00:01] ✖   [Exemple] Erreur dans l'étape [Exemple] : Erreur volontaire
```

---

## Contrat de retour

- `Invoke-Step` retourne l'objet `[Step]` pour l'étape invoquée si `-PassThru` est utilisé.
- En mode collection, `-PassThru` retourne l'etape parente, et les sous-etapes sont disponibles dans `Children`.
- Signature : `[OutputType('Step')]` sur `Invoke-Step`.
- `Write-Log` n'a pas de retour, il journalise simplement.

## Structure de l'objet `Step`

| Propriété         | Type                                   | Description                                 |
|-------------------|----------------------------------------|---------------------------------------------|
| `Name`            | `string`                               | Nom de l'étape                               |
| `Status`          | `string` (`Pending`, `Success`, `Error`)| Statut courant de l'étape                    |
| `Level`           | `int`                                   | Niveau d'imbrication (0 = racine, 1 = enfant)|
| `ParentStep`      | `Step`                                  | Référence vers l'étape parente               |
| `Children`        | `List[Step]`                            | Liste des sous-étapes                        |
| `Detail`          | `string`                                | Détail ou message d'erreur associé           |
| `ContinueOnError` | `bool`                                  | Indique si l'exécution continue en cas d'erreur |
| `StartTime`       | `datetime`                              | Début de l'étape                              |
| `EndTime`         | `datetime` ou `$null`                   | Fin de l'étape                                |
| `Duration`        | `TimeSpan`                              | Durée (EndTime - StartTime)                   |

> Encodage: les fichiers du module sont en UTF‑8. Pour un rendu optimal des icônes, utilisez PowerShell 7+ avec une console UTF‑8.

---

## Intégration et personnalisation du logging

Le module itfabrik.stepper intègre une fonction de mise en forme avancée des messages console: timestamp, icônes, couleurs, indentation selon le niveau d'imbrication. Par défaut, tous les messages sont affichés via la console (`Write-StepMessage`).

Il est possible de raccorder itfabrik.stepper à un module de logging externe pour bénéficier de fonctionnalités avancées (journalisation fichier, SIEM, etc.). Pour cela, définissez la variable globale `$StepManagerLogger` avec un scriptblock conforme à la signature suivante:

```powershell
$global:StepManagerLogger = {
    param(
        $Component,   # string : nom du composant ou de l'étape
        $Message,     # string : message à journaliser
        $Severity,    # string : Info, Success, Warning, Error, Debug, Verbose
        $IndentLevel  # int    : niveau d'indentation (0 = racine)
    )
    # ...votre logique de log ici...
}
```

Spécifications à respecter pour un logger externe:

- Accepter les 4 paramètres ci-dessus, dans l'ordre.
- Ne pas interrompre l'exécution (pas d'exception non gérée).

## Couplage avec itfabrik.Logger

Pour déporter la journalisation vers un module dédié, vous pouvez coupler itfabrik.stepper avec itfabrik.Logger. Le principe: itfabrik.Logger enregistre un dispatcher dans `$StepManagerLogger`, et stepper s’appuie dessus pour émettre les messages.

Recommandation: initialiser les modules et la configuration logger en tout début de script (bloc `Begin {}`).

```powershell
Begin {
  # 1) Import des modules
Import-Module ITFabrik.Stepper -Force
  Import-Module itfabrik.Logger -Force

  # 2) Initialiser le service et déclarer les sinks
  Initialize-LoggerService -Reset

  # 2a) Sink Console (format par défaut)
  Register-LoggerSink -Type Console -Format Default

  # 2b) Sink Fichier au format CMTrace (rotation quotidienne, UTF8BOM)
  $logPath = Join-Path $HOME 'Logs/stepper.cmtrace.log'
  Register-LoggerSink -Type File -Path $logPath -FileFormat Cmtrace -Rotation Daily -Encoding UTF8BOM -MaxRolls 7
}

Process {
  # Vos étapes et journaux utilisent désormais le logger externe
  Invoke-Step -Name 'Exemple' -ScriptBlock {
    Write-Log -Message 'Démarrage' -Severity Info
    # ...
  }
}
```

Raccourcis possibles selon votre version de itfabrik.Logger:
- `Initialize-LoggerConsole`
- `Initialize-LoggerFile -Path <chemin> -FileFormat Cmtrace -Rotation Daily -Encoding UTF8BOM`

---

## Initialisation rapide - Logger fichier

- Minimal (sans rotation):

```powershell
$global:StepManagerLogger = {
  param($Component, $Message, $Severity, $IndentLevel)
  $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Severity] [$Component] $(' ' * ($IndentLevel*2))$Message"
  Add-Content -Path "$HOME/Logs/stepper.log" -Value $line -Encoding UTF8
}
```

- Avec rotation (taille/quotidienne): utilisez la fonction suivante, puis appelez-la:

```powershell
function Set-StepperFileLogger {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [ValidateSet('None','Size','Daily')][string]$Rotation = 'None',
    [int]$MaxSizeMB = 5,
    [int]$MaxRolls = 3,
    [ValidateSet('Default','Cmtrace')][string]$FileFormat = 'Default',
    [ValidateSet('UTF8','UTF8BOM','Unicode')][string]$Encoding = 'UTF8'
  )

  $global:StepperLoggerConfig = [pscustomobject]@{
    Path      = (Resolve-Path -LiteralPath $Path).Path 2>$null -or $Path
    Rotation  = $Rotation
    MaxSizeMB = [math]::Max(1,$MaxSizeMB)
    MaxRolls  = [math]::Max(1,$MaxRolls)
    FileFormat= $FileFormat
    Encoding  = $Encoding
  }

  $global:StepManagerLogger = {
    param($Component,$Message,$Severity,$IndentLevel)
    $cfg = $global:StepperLoggerConfig
    if (-not $cfg) { return }

    $path = $cfg.Path
    $dir  = Split-Path -Parent $path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    if ($cfg.Rotation -eq 'Daily') {
      $base = [IO.Path]::GetFileNameWithoutExtension($path)
      $ext  = [IO.Path]::GetExtension($path)
      $date = (Get-Date).ToString('yyyy-MM-dd')
      $path = Join-Path $dir ("$base-$date$ext")
    }

    if ($cfg.Rotation -eq 'Size' -and (Test-Path $path)) {
      try {
        $lenMB = ([double](Get-Item $path).Length) / 1MB
        if ($lenMB -ge $cfg.MaxSizeMB) {
          for ($i = $cfg.MaxRolls - 1; $i -ge 1; $i--) {
            $src = "$path.$i"
            $dst = "$path." + ($i + 1)
            if (Test-Path $src) { Move-Item -Force -ErrorAction SilentlyContinue -Path $src -Destination $dst }
          }
          if (Test-Path $path) { Move-Item -Force -ErrorAction SilentlyContinue -Path $path -Destination "$path.1" }
        }
      } catch { }
    }

    if ($cfg.FileFormat -eq 'Cmtrace') {
      $type = switch ($Severity) { 'Error' {3} 'Warning' {2} default {1} }
      $ts = Get-Date
      $line = "<![LOG[$Message]LOG]!><time=\"$($ts.ToString('HH:mm:ss.ffffff'))\" date=\"$($ts.ToString('M-d-yyyy'))\" component=\"$Component\" context=\"User\" type=\"$type\" thread=\"$PID\" file=\"\">"
    } else {
      $sev = $Severity.PadLeft(10)
      $indent = ' ' * ($IndentLevel * 2)
      $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$sev] [$Component] $indent$Message"
    }

    $enc = switch ($cfg.Encoding) { 'UTF8BOM' {'utf8BOM'} 'Unicode' {'unicode'} default {'utf8'} }
    Add-Content -Path $path -Value $line -Encoding $enc
  }
}

Set-StepperFileLogger -Path "$HOME/Logs/stepper.log" -Rotation Size -MaxSizeMB 5 -MaxRolls 3
# ou
Set-StepperFileLogger -Path "$HOME/Logs/stepper.log" -Rotation Daily -FileFormat Cmtrace -Encoding UTF8BOM
```
- Gérer les niveaux de sévérité (`Info`, `Success`, `Warning`, `Error`, `Debug`, `Verbose`).
- Prendre en compte l'indentation pour l'affichage ou la structuration du log.

Exemple: journalisation personnalisée en couleur dans la console

```powershell
$global:StepManagerLogger = { param($Component, $Message, $Severity, $IndentLevel)
    Write-Host "[$Component][$Severity] $Message" -ForegroundColor Cyan
}
```

Si aucun logger n'est défini, itfabrik.stepper utilise automatiquement son affichage console intégré.

---

## Licence

Apache-2.0 — voir `LICENSE`.
