# Configuration

itfabrik.stepper fournit par défaut un affichage console prêt à l'emploi (via `Write-StepMessage`). Vous pouvez:

- Utiliser la sortie console intégrée (aucune config requise)
- Brancher un logger externe via la variable globale `$StepManagerLogger`

## Utiliser la sortie console intégrée

- Les fonctions publiques affichent les étapes et logs:
  - `Invoke-Step` pour encapsuler un bloc
  - `Write-Log -Message <texte> -Severity <Info|Success|Warning|Error|Debug|Verbose>` pour les messages utilisateur
- L’affichage inclut: timestamp, icône (PS7+), indentation par niveau, nom d’étape, message.
- Les messages Verbose/Debug respectent `$VerbosePreference` / `$DebugPreference`.

## Définir un logger externe

Déclarez un scriptblock global `$StepManagerLogger` avec la signature suivante:

```powershell
$global:StepManagerLogger = {
    param(
        $Component,   # string : nom du composant (par défaut 'StepManager')
        $Message,     # string : message à journaliser
        $Severity,    # string : Info, Success, Warning, Error, Debug, Verbose
        $IndentLevel  # int    : niveau d'indentation (0 = racine)
    )
    # Exemple minimal : écriture fichier
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Severity] [$Component] $(' ' * ($IndentLevel*2))$Message"
    Add-Content -Path "$HOME/itfabrik.stepper.log" -Value $line -Encoding UTF8
}
```

Notes:
- Le composant par défaut utilisé par le module est la chaîne `'StepManager'` (compatibilité ascendante). Vous pouvez l’ignorer ou le mapper.
- Si aucun logger n’est défini, la console intégrée est utilisée automatiquement.
- L’indentation est calculée depuis la Step courante si `IndentLevel` n’est pas fourni explicitement par l’appelant.

