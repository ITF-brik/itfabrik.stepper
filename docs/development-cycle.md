# Cycle de developpement

Ce document formalise le demarrage et la cloture d'un cycle de developpement.

## 1) Demarrer un cycle
- A l'ouverture d'un nouveau cycle, creer une branche d'implementation dediee depuis `main`.
- Utiliser le script:
  ```powershell
  ./Scripts/New-DevelopmentCycle.ps1 -Type 'Reorganisation CI/CD' -Objective 'Aligner la methodologie avec ITFabrik.Logger' -Push
  ```
- Convention de nommage:
  - `cycle/YYYYMMDD-<type>-<objective>`
  - Exemple: `cycle/20260306-reorganisation-ci-cd-aligner-la-methodologie-avec-itfabrik-logger`

## 2) Travailler sur la branche
- Les workflows `.github/workflows/ci.yml` et `.github/workflows/pester-coverage.yml` s'executent sur `main`, `master` et `cycle/**`.
- Garder le cycle de travail, les commits et la validation sur cette branche jusqu'a la release.

## 3) Publier la version
- Mettre a jour `ITFabrik.Stepper.psd1` et `CHANGELOG.md`.
- Creer et pousser le tag avec:
  ```powershell
  ./Scripts/New-ReleaseTag.ps1 -Push
  ```
- Lors de la creation de la release GitHub, choisir la branche `cycle/*` comme `Target` si vous voulez que la branche distante soit fermee automatiquement apres succes.

## 4) Fermer le cycle
- Si la publication GitHub / PSGallery reussit et que la release vise une branche `cycle/*`, `.github/workflows/publish.yml` supprime automatiquement la branche distante.
- Pour supprimer aussi la branche locale:
  ```powershell
  ./Scripts/Close-DevelopmentCycle.ps1 -Branch 'cycle/20260306-reorganisation-ci-cd-aligner-la-methodologie-avec-itfabrik-logger'
  ```
- Pour une publication declenchee manuellement via `workflow_dispatch`, fournir `release_branch` au workflow si la branche doit etre supprimee apres succes.
