# StepManager

[![CI](https://github.com/ITF-brik/StepManager/actions/workflows/ci.yml/badge.svg)](https://github.com/ITF-brik/StepManager/actions/workflows/ci.yml)
[![PS Gallery Version](https://img.shields.io/powershellgallery/v/StepManager.svg?style=flat)](https://www.powershellgallery.com/packages/StepManager)
[![PS Gallery Downloads](https://img.shields.io/powershellgallery/dt/StepManager.svg?style=flat)](https://www.powershellgallery.com/packages/StepManager)
[![Release](https://img.shields.io/github/v/release/ITF-brik/StepManager?display_name=tag&sort=semver)](https://github.com/ITF-brik/StepManager/releases)
[![License](https://img.shields.io/badge/License-Apache--2.0-blue.svg)](LICENSE)

StepManager est un module PowerShell pour encapsuler des étapes d’exécution avec gestion d’état (Pending/Success/Error), imbrication, logging et gestion d’erreurs (`ContinueOnError`).

---

## Installation

- Depuis PowerShell Gallery (recommandé):

```powershell
Install-Module StepManager -Scope CurrentUser -Force
# Puis si nécessaire
Import-Module StepManager -Force
```

- Mise à jour:

```powershell
Update-Module StepManager
```

- Installation manuelle depuis GitHub Release:

```powershell
$tag = (Invoke-RestMethod https://api.github.com/repos/ITF-brik/StepManager/releases/latest).tag_name
$zip = Join-Path $env:TEMP "StepManager-$tag.zip"
Invoke-WebRequest -Uri "https://github.com/ITF-brik/StepManager/releases/download/$tag/StepManager-$tag.zip" -OutFile $zip
$dst = Join-Path $HOME "Documents/PowerShell/Modules/StepManager"
if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst -Force | Out-Null }
Expand-Archive -Path $zip -DestinationPath $dst -Force
Import-Module StepManager -Force
```

---

## Fonctionnalités

- Étapes avec statut et détails
- Imbrication (sous‑étapes)
- Logging simple (console) + logger personnalisable
- Gestion d’erreur configurable (`ContinueOnError`)
- Retour d’objets typés pour chaque étape

## Exemples d’utilisation

### Étape simple

```powershell
Invoke-Step -Name 'Préparation' -ScriptBlock {
    # Instructions de préparation
}
```

### Étapes imbriquées avec gestion d’erreur

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

### Boucle sur une liste d’éléments

```powershell
$items = 'A','B','C'
$steps = foreach ($item in $items) {
    Invoke-Step -Name "Traitement $item" -ScriptBlock {
        # Traitement spécifique à $item
        "Traitement de $item terminé."
    }
}
# $steps contient la liste des objets Step pour chaque élément
```

### Gestion d’erreur

```powershell
Invoke-Step -Name 'Exemple' -ContinueOnError:$true -ScriptBlock {
    throw 'Erreur volontaire'
}
# L’étape sera en statut 'Error', mais l’exécution continue

Invoke-Step -Name 'Exemple' -ContinueOnError:$false -ScriptBlock {
    throw 'Erreur volontaire'
}
# L’étape sera en statut 'Error'
```

---

## Contrat de retour

- `Invoke-Step` retourne l’objet `[Step]` pour l’étape invoquée.
- Signature : `[OutputType('Step')]` sur `Invoke-Step`.

## Structure de l’objet `Step`

| Propriété         | Type                                 | Description                                                     |
|-------------------|--------------------------------------|-----------------------------------------------------------------|
| `Name`            | `string`                              | Nom de l’étape                                                  |
| `Status`          | `string` (`Pending`, `Success`, `Error`) | Statut courant de l’étape                                   |
| `Level`           | `int`                                 | Niveau d’imbrication (0 = racine, 1 = enfant, etc.)             |
| `ParentStep`      | `Step`                                | Référence vers l’étape parente (ou `$null` si racine)           |
| `Children`        | `List[Step]`                          | Liste des sous‑étapes                                           |
| `Detail`          | `string`                              | Détail ou message d’erreur associé                              |
| `ContinueOnError` | `bool`                                | Indique si l’exécution continue en cas d’erreur                 |
| `StartTime`       | `datetime`                            | Début de l’étape                                                |
| `EndTime`         | `datetime` ou `$null`                 | Fin de l’étape                                                  |

---

## Intégration logging

- `Invoke-Logger` centralise le logging.
- Par défaut, fallback console via `Write-StepMessage` (gris, indentation).
- Possibilité d’injecter un logger personnalisé via la variable `StepManagerLogger`.

```powershell
$global:StepManagerLogger = { param($Component, $Message, $Severity, $IndentLevel)
    Write-Host "[$Component][$Severity] $Message" -ForegroundColor Cyan
}
```

---

## Licence

Apache-2.0 — voir `LICENSE`.
