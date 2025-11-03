# Procédure de publication d'une nouvelle release

Ce guide décrit pas à pas comment publier une nouvelle version du module itfabrik.stepper sur PowerShell Gallery en restant aligné entre `ModuleVersion` (manifeste) et le tag Git `vX.Y.Z`.

## 1) Pré-requis
- Secrets GitHub configurés: `PSGALLERY_API_KEY`, `RELEASE_TOKEN` (repository > Settings > Secrets and variables > Actions).
- Git installé et configuré (remote `origin` pointe sur GitHub).
- Tests Pester fonctionnels en local.
- Choisir une version SemVer: `MAJOR.MINOR.PATCH` (ex: 1.2.3).

## 2) Valider localement
- Lancer les tests:
  - Avec config (Pester v5):
    ```powershell
    Import-Module Pester -MinimumVersion 5.5.0 -Force
    $cfg = New-PesterConfiguration -Hashtable (Import-PowerShellDataFile 'Tests/PesterConfig.psd1')
    Invoke-Pester -Configuration $cfg
    ```
  - Ou simple: `Invoke-Pester -Path Tests`
- Corriger si besoin jusqu'a ce que tout passe.

## 3) Mettre à jour la version
- Ouvrir `itfabrik.stepper.psd1` et définir `ModuleVersion = 'X.Y.Z'`.
- Mettre a jour `CHANGELOG.md` si necessaire.
- Commit & push:
  ```powershell
  git add itfabrik.stepper.psd1 CHANGELOG.md
  git commit -m "Bump version to X.Y.Z"
  git push
  ```

## 4) Créer et pousser le tag
- Créer un tag qui correspond à `ModuleVersion`:
  ```powershell
  git tag vX.Y.Z
  git push origin vX.Y.Z
  ```
- Le workflow `.github/workflows/release.yml` déclenché par le tag packagera le module, créera la release GitHub et publiera sur PSGallery (si la clé est présente).

## 5) Release GitHub (optionnel)
- Si besoin de compléter les notes, éditez la release créée automatiquement par le workflow.

## 6) Publication PowerShell Gallery
- Intégrée au workflow `release.yml` via `Publish-PSResource`, utilisant `PSGALLERY_API_KEY`.

## 7) Verifier la publication
- Installer la version publiee depuis PSGallery (depuis une session propre):
  ```powershell
  Install-Module ITFabrik.Stepper -Repository PSGallery -Scope CurrentUser -Force -RequiredVersion X.Y.Z
  Import-Module ITFabrik.Stepper -RequiredVersion X.Y.Z -Force
  Get-Module ITFabrik.Stepper | Select-Object Name,Version,Path
  ```

## 8) Bonnes pratiques
- Respecter SemVer: PATCH = fix, MINOR = ajout non cassant, MAJOR = rupture.
- Ne pas tagger manuellement a la main; preferer `New-ReleaseTag.ps1`.
- Proteger `main` (PR + review) si depot public.
- Completer/tenir a jour `CHANGELOG.md`.

## 9) Rattrapage (en cas d'erreur)
- Tag et manifeste non alignes:
  - Corriger `ModuleVersion` puis re-creer le tag avec le script, ou
  - Supprimer le tag et le repusher:
    ```powershell
    git tag -d vX.Y.Z
    git push origin :refs/tags/vX.Y.Z
    ./Scripts/New-ReleaseTag.ps1 -Push
    ```
- Echec de publication (secret manquant): ajouter `PSGALLERY_API_KEY` dans les Secrets et republier la release.
- Version PSGallery a retirer: utiliser l'interface PSGallery (ou `Unpublish-Module` si applicable) et corriger la release.

## Fichiers et commandes utiles
- Manifeste: `itfabrik.stepper.psd1`
- Workflows: `.github/workflows/ci.yml`, `.github/workflows/release.yml`
- Tests: `Tests/`
