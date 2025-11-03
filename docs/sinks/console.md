# Sortie Console (intégrée)

- Fourni nativement par le module via `Write-StepMessage`.
- Icônes (PS7+), couleurs par sévérité, padding aligné, timestamp.
- Indentation: `IndentLevel` (2 espaces par niveau) avant le message.
- Nom d'étape: affiché entre crochets s'il est disponible (ex: `[Build]`).
- Composant: injecté au début du message sous la forme `[Component] ...` (par défaut `'StepManager'`).

Exemple
- `[2025-01-01 12:00:00] V    [Build] [StepManager] Étape démarrée`

Remarques
- Les messages `Verbose`/`Debug` respectent les préférences PowerShell.
- L’encodage recommandé pour une console moderne est UTF-8 (PS7+).
