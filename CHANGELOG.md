# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## [Unreleased]

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
