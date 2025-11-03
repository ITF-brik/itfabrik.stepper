# itfabrik.stepper - Roadmap

Cette feuille de route rassemble les axes d'amélioration prévus pour les prochaines versions du module.

## vNext (propositions)

- API Logging console
  - Option pour rediriger les messages vers les flux PowerShell natifs selon la sévérité:
    - Info/Success → `Write-Information` (avec balises)
    - Warning → `Write-Warning`
    - Error → `Write-Error`
    - Debug → `Write-Debug`
    - Verbose → `Write-Verbose`
  - Switch global/module (p. ex. `$StepManagerUseStreams`) ou paramètre d’init pour activer/désactiver ce mode.
  - Conservation de la compatibilité avec le logger externe `$StepManagerLogger`.

- Personnalisation du formalisme des messages
  - Permettre à l'utilisateur de définir au début du script un style de rendu (icônes, couleurs, structure `[Step]`/`[Component]`, timestamps…).
  - Fournir des préréglages (compact, détaillé, minimal, sans icônes) et un mécanisme d’override fin.

- Robustesse multi-runspace
  - Continuer à protéger l’état interne (`StepStack`, pile d’indentation) avec des verrous.
  - Documenter clairement les garanties et limites en scénarios multi-runspace.

- Internationalisation et encodage
  - S’assurer que tous les fichiers sont en UTF-8 et que les caractères (accents, icônes) s’affichent correctement sous Windows PowerShell 5.1 et PowerShell 7+.
  - Option pour désactiver les icônes Unicode si l’environnement ne les supporte pas.

- Expérience objet
  - Propriété calculée `Duration` et méthode `ToString()` (ajoutées) — itérer avec un fichier `.format.ps1xml` plus riche si besoin (vues liste/détails).
  - Envisager des types additionnels pour événements de log ou résultats d’agrégation.

- Diagnostics et performance
  - Traces internes optionnelles (niveau Debug) pour diagnostiquer la pile des Steps.
  - Micro-optimisations sur la construction de messages et la gestion d’objets.

- CI/CD et compatibilité
  - Matrice de tests multi-plateforme (Windows/Linux/macOS) et multi-versions (5.1, 7.x).
  - Analyser avec PSScriptAnalyzer (style et sûreté) et publier les résultats.
