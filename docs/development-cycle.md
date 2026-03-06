# Cycle de developpement

Ce document est la reference principale pour le flux de travail recurrent du projet.

## Principe
- Un cycle de developpement = une branche d'implementation dediee.
- Convention de nommage : `cycle/YYYYMMDD-<type>-<objectif>`.
- La branche est creee au debut du cycle, utilisee jusqu'a la release, puis fermee apres publication reussie.

## 1) Demarrer un cycle
- Depuis `main`, creer la branche avec :
  ```powershell
  ./Scripts/New-DevelopmentCycle.ps1 -Type 'Reorganisation CI/CD' -Objective 'Aligner la methodologie avec ITFabrik.Logger' -Push
  ```
- Le script :
  - construit un nom de branche standardise,
  - cree la branche localement,
  - bascule dessus,
  - la pousse vers `origin` si `-Push` est fourni.

## 2) Developper sur la branche
- Faire les commits du cycle sur cette branche uniquement.
- Les workflows suivants s'executent aussi sur `cycle/**` :
  - `.github/workflows/ci.yml`
  - `.github/workflows/pester-coverage.yml`
- Tant que la version n'est pas publiee, la branche reste la source de verite du cycle.

## 3) Preparer la version
- Mettre a jour :
  - `ITFabrik.Stepper.psd1`
  - `CHANGELOG.md`
- Convention de version :
  - stable : `ModuleVersion = '1.0.9'` et `PrivateData.PSData.Prerelease = $null`
  - prerelease : `ModuleVersion = '1.0.9'` et `PrivateData.PSData.Prerelease = 'alpha1'`
- Valider localement si necessaire :
  ```powershell
  ./Scripts/Build-Module.ps1
  ./Scripts/Publish-PSGallery.ps1 -ModulePath .\dist\ITFabrik.Stepper -ValidateOnly
  ```
- Committer puis pousser les derniers changements du cycle.

## 4) Publier la release
- Creer le tag depuis le manifeste :
  ```powershell
  ./Scripts/New-ReleaseTag.ps1 -Push
  ```
- Le tag genere est base sur la version effective :
  - stable : `v1.0.9`
  - prerelease : `v1.0.9-alpha1`
- Creer ensuite la release GitHub sur ce tag.
- Si la version est prerelease, marquer aussi la release GitHub comme prerelease.
- Important :
  - choisir la branche `cycle/*` active comme `Target` si vous voulez qu'elle soit fermee automatiquement apres succes,
  - le workflow `.github/workflows/publish.yml` publie ensuite le module sur PowerShell Gallery.

## 5) Fermer le cycle
- Si la release a ete creee depuis une branche `cycle/*`, le workflow de publication supprime automatiquement la branche distante apres succes.
- Pour supprimer aussi la branche locale :
  ```powershell
  ./Scripts/Close-DevelopmentCycle.ps1 -Branch 'cycle/20260306-reorganisation-ci-cd-aligner-la-methodologie-avec-itfabrik-logger'
  ```
- Si la publication est lancee manuellement via `workflow_dispatch`, renseigner `release_branch` pour obtenir le meme comportement de fermeture distante.

## Raccourcis utiles
- Ouvrir un cycle : `Scripts/New-DevelopmentCycle.ps1`
- Construire l'artifact : `Scripts/Build-Module.ps1`
- Valider l'artifact : `Scripts/Publish-PSGallery.ps1 -ValidateOnly`
- Tagger la version : `Scripts/New-ReleaseTag.ps1`
- Fermer la branche locale : `Scripts/Close-DevelopmentCycle.ps1`
