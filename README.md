# StepManager

StepManager est un module PowerShell permettant d'encapsuler des étapes d'exécution avec gestion d'état (Pending/Success/Error), imbrication, logging simple et gestion d'erreur (`ContinueOnError`).

## Sommaire

- [Installation](#installation)
- [Fonctionnalités](#fonctionnalités)
- [Exemples d'utilisation](#exemples-dutilisation)
- [Contrat de retour](#contrat-de-retour)
- [Structure de l'objet Step](#structure-de-lobjet-step)
- [Fonctions internes](#fonctions-internes)
- [Intégration logging](#intégration-logging)
- [Comportement des erreurs](#comportement-des-erreurs)
- [Notes de conception](#notes-de-conception)

---

## Installation

```powershell
Import-Module .\StepManager.psd1 -Force
```

## Fonctionnalités

- Encapsulation d'étapes d'exécution avec statut et détails
- Imbrication d'étapes (sous-étapes)
- Logging simple (console)
- Gestion d'erreur configurable (`ContinueOnError`)
- Retour d'objets typés pour chaque étape

## Exemples d'utilisation

### Étape simple

```powershell
Invoke-Step -Name 'Préparation' -ScriptBlock {
    # Instructions de préparation
}
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

### Boucle sur une liste d'éléments

```powershell
$items = 'A', 'B', 'C'
$steps = foreach ($item in $items) {
    Invoke-Step -Name "Traitement $item" -ScriptBlock {
        # Traitement spécifique à $item
        "Traitement de $item terminé."
    }
}
# $steps contient la liste des objets Step pour chaque élément
```

### Gestion d'erreur et propagation

```powershell
Invoke-Step -Name 'Exemple' -ContinueOnError:$true -ScriptBlock {
    throw 'Erreur volontaire'
}
# L'étape sera en statut 'Error', mais l'exécution continue

Invoke-Step -Name 'Exemple' -ContinueOnError:$false -ScriptBlock {
    throw 'Erreur volontaire'
}
# L'étape sera en statut 'Error'
```

## Contrat de retour

- `Invoke-Step` retourne l'objet `[Step]` créé pour l'étape invoquée.
- Signature : `[OutputType('Step')]` sur `Invoke-Step`.

## Structure de l'objet `Step`

L'objet `[Step]` retourné par `Invoke-Step` possède les propriétés suivantes :

| Propriété         | Type                              | Description                                                      |
|-------------------|-----------------------------------|------------------------------------------------------------------|
| `Name`            | `string`                          | Nom de l'étape                                                   |
| `Status`          | `string` (`Pending`, `Success`, `Error`) | Statut courant de l'étape                                  |
| `Level`           | `int`                             | Niveau d'imbrication (0 = racine, 1 = enfant, etc.)              |
| `ParentStep`      | `Step`                            | Référence vers l'étape parente (ou `$null` si racine)            |
| `Children`        | `List[Step]`                      | Liste des sous-étapes (enfants)                                  |
| `Detail`          | `string`                          | Détail ou message d'erreur associé à l'étape                     |
| `ContinueOnError` | `bool`                            | Indique si l'exécution continue en cas d'erreur                  |
| `StartTime`       | `datetime`                        | Date/heure de début de l'étape                                   |
| `EndTime`         | `datetime` ou `$null`             | Date/heure de fin de l'étape (ou `$null` si non terminée)        |

Exemple d'accès :

```powershell
$step = Invoke-Step -Name 'Exemple' -ScriptBlock { }
$step.Name      # 'Exemple'
$step.Status    # 'Success'
$step.Children  # Liste des sous-étapes
$step.StartTime # Date de début
$step.EndTime   # Date de fin
```

---

## Fonctions internes

Les fonctions suivantes sont internes et non accessibles directement :

- `New-Step` - création d'une étape imbriquée
- `Set-Step` - mise à jour du statut/détail de l'étape courante
- `Complete-Step` (`Stop-Step`) - termine l'étape courante
- `Get-CurrentStep` - retourne l'étape courante

Toute la gestion des statuts, erreurs et imbrications se fait via `Invoke-Step`.

## Intégration logging

`Write-StepMessage` (privé) utilise `Write-Host`/`Write-Warning`/`Write-Error`. Vous pouvez le rebrancher vers votre propre module de logging (ex. `Write-Message`) si besoin.

## Comportement des erreurs

- Lorsqu'une exception survient dans le `ScriptBlock` :
  - Le statut de l'étape passe à `Error` et `Detail` contient le message d'erreur (`$_.Exception.Message`).
  - Un enregistrement `Write-Error` est émis (non bloquant par défaut).
  - L'exception n'est pas propagée par `Invoke-Step`. L'appelant récupère l'objet `Step` et peut décider quoi faire.
- Imbrication d'étapes :
  - Une erreur dans une sous-étape n'entraîne pas d'échec automatique de l'étape parente. Le parent reste `Success` sauf s'il lève lui-même une exception.
  - Le paramètre `-ContinueOnError` est stocké sur l'objet `Step` (métadonnée d'intention) et peut être utilisé par du code d'orchestration; il ne change pas le fait que `Invoke-Step` ne relance pas l'exception.
- Bonnes pratiques :
  - Exploiter la propriété `Status` et/ou `Detail` pour décider des suites (poursuivre, ignorer, compenser, etc.).
  - Si vous souhaitez transformer une erreur d'étape en exception, vérifiez le statut après l'appel et `throw` selon votre logique métier.

## Notes de conception

- État module-scopé via une pile (`Stack`) pour gérer l'imbrication.
- `Step` est une classe PowerShell 5.1+ avec `StartTime`/`EndTime`.
- `Invoke-Step` positionne le statut `Error` en cas d'exception, et n'élève pas l'exception (statut à inspecter côté appelant). Le paramètre `-ContinueOnError` sert de métadonnée d'intention.
- Pour une meilleure conformité des verbes, alias `Stop-Step` vers `Complete-Step` (optionnel).

