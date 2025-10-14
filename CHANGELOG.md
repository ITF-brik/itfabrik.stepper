# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## [Unreleased]
- Planned: CI via GitHub Actions (Pester + PSScriptAnalyzer)
- Planned: Tag-driven release packaging

## [2025.10.1.7] - 2025-10-13
- CI/Release: publier via PSResourceGet (Publish-PSResource) pour éviter le bootstrap du provider NuGet
- CI/Release: condition de job corrigée et sécurisée (pas de secrets dans if)
- Manifest: bump ModuleVersion à 2025.10.1.7

## [2025.10.1.5] - 2025-10-13
- Fix: Autoriser les ScriptBlock vides dans `Invoke-Step` (steps no-op)
- Fix(logging): espacement du fallback console et indentation cohérente
- CI: correction `Invoke-ScriptAnalyzer` multi‑plateforme; normalisation LF
- Release: permissions token, utilisation d’un secret `RELEASE_TOKEN`
- Release: ajout job de publication PowerShell Gallery (tags `v*`)
- Manifest: ajout `LicenseUri`, `ProjectUri`, `IconUri`, `ReleaseNotes`
- Repo: `.gitattributes`, templates Issues/PR, `.gitignore`

## [0.1.0] - 2025-10-13
- Initial public version of StepManager
- Core command `Invoke-Step` with nested steps, logging, error handling
- Private helpers, classes, and tests (Pester)
