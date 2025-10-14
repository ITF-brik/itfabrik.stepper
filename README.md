# StepManager

[![CI](https://github.com/ITF-brik/StepManager/actions/workflows/ci.yml/badge.svg)](https://github.com/ITF-brik/StepManager/actions/workflows/ci.yml)
[![PS Gallery Version](https://img.shields.io/powershellgallery/v/StepManager.svg?style=flat)](https://www.powershellgallery.com/packages/StepManager)
[![PS Gallery Downloads](https://img.shields.io/powershellgallery/dt/StepManager.svg?style=flat)](https://www.powershellgallery.com/packages/StepManager)
[![Release](https://img.shields.io/github/v/release/ITF-brik/StepManager?display_name=tag&sort=semver)](https://github.com/ITF-brik/StepManager/releases)
[![License](https://img.shields.io/badge/License-Apache--2.0-blue.svg)](LICENSE)

StepManager est un module PowerShell pour encapsuler des étapes d'exécution avec gestion d'état (Pending/Success/Error), imbrication, logging personnalisable et gestion d'erreurs (`ContinueOnError`).

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
- Imbrication (sous-étapes)
- Logging console et logger personnalisable
- Fonction publique **Write-Log** pour journalisation utilisateur
- Gestion d'erreur configurable (`ContinueOnError`)
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

### Boucle sur une liste d'éléments

```powershell
$items = 'A','B','C'
$steps = foreach ($item in $items) {
    Invoke-Step -Name "Traitement $item" -ScriptBlock {
        # Traitement spécifique à $item
        "Traitement de $item terminé."
    } -PassThru
}
# $steps contient la liste des objets Step pour chaque élément
```

#### Exemple d'affichage console attendu

```text
[2025-10-14 14:00:00] ℹ    [Traitement A] Démarrage de l'étape : Traitement A
[2025-10-14 14:00:00] ✓   [Traitement A] Étape terminée : Traitement A
[2025-10-14 14:00:01] ℹ    [Traitement B] Démarrage de l'étape : Traitement B
[2025-10-14 14:00:01] ✓   [Traitement B] Étape terminée : Traitement B
[2025-10-14 14:00:02] ℹ    [Traitement C] Démarrage de l'étape : Traitement C
[2025-10-14 14:00:02] ✓   [Traitement C] Étape terminée : Traitement C
```

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

Le module StepManager intègre une fonction de mise en forme avancée des messages console: timestamp, icônes, couleurs, indentation selon le niveau d'imbrication. Par défaut, tous les messages sont affichés via la console (`Write-StepMessage`).

Il est possible de raccorder StepManager à un module de logging externe pour bénéficier de fonctionnalités avancées (journalisation fichier, SIEM, etc.). Pour cela, définissez la variable globale `$StepManagerLogger` avec un scriptblock conforme à la signature suivante:

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
- Gérer les niveaux de sévérité (`Info`, `Success`, `Warning`, `Error`, `Debug`, `Verbose`).
- Prendre en compte l'indentation pour l'affichage ou la structuration du log.

Exemple: journalisation personnalisée en couleur dans la console

```powershell
$global:StepManagerLogger = { param($Component, $Message, $Severity, $IndentLevel)
    Write-Host "[$Component][$Severity] $Message" -ForegroundColor Cyan
}
```

Si aucun logger n'est défini, StepManager utilise automatiquement son affichage console intégré.

---

## Licence

Apache-2.0 — voir `LICENSE`.

