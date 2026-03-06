# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## [Unreleased]

## [1.0.9-alpha1] - 2026-03-06

### Added
- Support des versions prerelease via `PrivateData.PSData.Prerelease` dans le manifeste.
- Validation tag/version adaptee aux tags du type `v1.0.9-alpha1`.
- Tests de non-regression autour de la resolution des versions de release et prerelease.

### Fixed
- Le mode `Invoke-Step -Parallel` rejoue maintenant les logs des workers dans l'ordre des elements.
- Les loggers personnalises recoivent aussi les messages emis depuis les workers paralleles.
- La documentation utilisateur precise le role de `-ThrottleLimit` et le comportement de log en mode parallele.

## [1.0.8] - 2026-03-06

### Added
- `Invoke-Step` prend maintenant en charge un mode collection via `-InputObject`, avec une sous-etape par element.
- La collection peut etre executee en parallele avec `-Parallel`, `-ParallelThreshold` et `-ThrottleLimit`.
- Le chemin parallele est compatible PowerShell 7 (`ForEach-Object -Parallel`) et Windows PowerShell 5.1 (`Start-Job`).
- Le README documente le mode collection et le mode parallele avec des exemples utilisateurs.

### Changed
- Le workflow `pester-coverage.yml` est aligne sur la methode de `ITFabrik.Logger` pour eviter un faux negatif sur la couverture des commandes executees dans des runspaces/jobs paralleles.

## [1.0.7] - 2026-03-06

### Fixed
- `Write-Log` utilise maintenant `StepManager` comme composant de repli lorsqu'aucune step active n'existe.
- L'intégration avec des loggers externes, notamment `ITFabrik.Logger` et son sink `Serilog`, produit désormais un `Component` non vide hors step.

## [2025.10.2.0] - 2025-10-14

### Added
- Roadmap.md: idées pour vNext (API logging via flux PS, formalisme de messages configurable, robustesse multi-runspace, i18n/UTF‑8, vues objets, CI multi‑plateforme).
- Objet Step: propriété `Duration` (TimeSpan) et méthode `ToString()` pour un rendu lisible.
- Fichier de formatage `itfabrik.stepper.format.ps1xml` pour un affichage tabulaire par défaut (Name, Status, Level, Duration, Detail).
- `.editorconfig` pour standardiser encodage UTF‑8, EOL LF et indentation.

### Changed
- Invoke-Logger: n’auto‑indente plus lorsqu’un `-IndentLevel` explicite est fourni (cohérence d’indentation).
- Write-StepMessage: suppression de l’affichage de `[Component]` pour éviter la duplication avec `[Step]`.
- Invoke-Step: propagation d’erreur hiérarchique — si `ContinueOnError:$false`, throw; si le parent a `ContinueOnError:$true`, la suite continue.
- État interne: protection multi‑runspace par verrou autour des piles (`StepStack`, pile d’indentation).

### Fixed
- README et messages internes: corrections d’accents et d’icônes Unicode (UTF‑8), exemples revus.
- Tests: correction d’un test d’indentation et alignement du test de propagation d’erreur.

### Planned
- CI via GitHub Actions (Pester + PSScriptAnalyzer)
- Tag-driven release packaging

## [2025.10.1.7] - 2025-10-13
- CI/Release: publier via PSResourceGet (Publish-PSResource) pour éviter le bootstrap du provider NuGet
- CI/Release: condition de job corrigée et sécurisée (pas de secrets dans if)
- Manifest: bump ModuleVersion à 2025.10.1.7

## [2025.10.1.5] - 2025-10-13
- Fix: Autoriser les ScriptBlock vides dans `Invoke-Step` (steps no‑op)
- Fix(logging): espacement du fallback console et indentation cohérente
- CI: correction `Invoke-ScriptAnalyzer` multi‑plateforme; normalisation LF
- Release: permissions token, utilisation d'un secret `RELEASE_TOKEN`
- Release: ajout job de publication PowerShell Gallery (tags `v*`)
- Manifest: ajout `LicenseUri`, `ProjectUri`, `IconUri`, `ReleaseNotes`
- Repo: `.gitattributes`, templates Issues/PR, `.gitignore`

## [0.1.0] - 2025-10-13
- Initial public version of StepManager
- Core command `Invoke-Step` with nested steps, logging, error handling
- Private helpers, classes, and tests (Pester)
