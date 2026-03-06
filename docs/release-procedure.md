# Procedure de publication d'une nouvelle release

Ce guide decrit pas a pas comment publier une nouvelle version du module ITFabrik.Stepper sur PowerShell Gallery en restant aligne entre `ModuleVersion` (manifeste) et le tag Git `vX.Y.Z`.

## 1) Pre-requis
- Secret GitHub configure: `PSGALLERY_API_KEY` (repository > Settings > Secrets and variables > Actions).
- Git installe et configure (remote `origin` pointe sur GitHub).
- Tests Pester fonctionnels en local.
- Choisir une version SemVer: `MAJOR.MINOR.PATCH` (ex: 1.2.3).
- Si le cycle de travail n'est pas deja isole, creer une branche `cycle/*` avec `./Scripts/New-DevelopmentCycle.ps1`.

## 2) Valider localement
- Lancer les tests:
  - Avec config (Pester v5):
    ```powershell
    Import-Module Pester -MinimumVersion 5.5.0 -Force
    $cfg = New-PesterConfiguration -Hashtable (Import-PowerShellDataFile 'Tests/PesterConfig.psd1')
    Invoke-Pester -Configuration $cfg
    ```
  - Ou simple: `Invoke-Pester -Path Tests`
- Lancer l'analyse statique:
  ```powershell
  Import-Module PSScriptAnalyzer -MinimumVersion 1.22.0 -Force
  $targets = @('ITFabrik.Stepper.psm1','Public','Private')
  $issues = foreach ($target in $targets) {
    Invoke-ScriptAnalyzer -Path $target -Recurse -Settings 'PSScriptAnalyzerSettings.psd1'
  }
  if ($issues) {
    $issues | Format-Table -AutoSize
    throw "ScriptAnalyzer found $($issues.Count) issue(s)."
  }
  ```
- Construire l'artifact publie:
  ```powershell
  ./Scripts/Build-Module.ps1
  ```
- Verifier l'artifact (sans publier):
  ```powershell
  ./Scripts/Publish-PSGallery.ps1 -ModulePath .\dist\ITFabrik.Stepper -ValidateOnly
  ```
- Corriger si besoin jusqu'a ce que tout passe.

## 3) Mettre a jour la version
- Ouvrir `ITFabrik.Stepper.psd1` et definir `ModuleVersion = 'X.Y.Z'`.
- Mettre a jour `CHANGELOG.md` si necessaire.
- Commit & push:
  ```powershell
  git add ITFabrik.Stepper.psd1 CHANGELOG.md
  git commit -m "Bump version to X.Y.Z"
  git push
  ```

## 4) Creer et pousser le tag
- Utiliser le script fourni pour assurer l'alignement:
  ```powershell
  ./Scripts/New-ReleaseTag.ps1 -Push
  ```
- Ce script lit `ModuleVersion`, cree le tag `vX.Y.Z` et le pousse.
- Le workflow `.github/workflows/check-tag.yml` verifie automatiquement que le tag matche `ModuleVersion`.

## 5) Creer la release GitHub
- Aller sur GitHub > Releases > Draft a new release.
- Selectionner le tag cree `vX.Y.Z`.
- Target branch: la branche `cycle/*` active si elle doit etre fermee automatiquement apres succes, sinon `main`.
- Titre/notes: reprendre le resume du `CHANGELOG.md`.
- Publier la release.

## 6) Publication PowerShell Gallery
- Le workflow `.github/workflows/publish.yml` se declenche sur `release: published` ou `workflow_dispatch`.
- Il execute la chaine complete:
  - Validation tag/version
  - Build de l'artifact (`Scripts/Build-Module.ps1`)
  - Verification stricte du contenu (`psd1`, `psm1`, `format.ps1xml`, `LICENSE`, `README.md`)
  - ScriptAnalyzer sur l'artifact build
  - Publication via `Scripts/Publish-PSGallery.ps1` (source: `dist/ITFabrik.Stepper`)
  - Suppression de la branche distante `cycle/*` si la release a ete creee depuis cette branche ou si `release_branch` est fourni en `workflow_dispatch`

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
- Utiliser une branche `cycle/*` par cycle de developpement.
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
- Echec validation artifact (missing/extra files):
  - Regenerer l'artifact localement:
    ```powershell
    ./Scripts/Build-Module.ps1
    ./Scripts/Publish-PSGallery.ps1 -ModulePath .\dist\ITFabrik.Stepper -ValidateOnly
    ```
  - Corriger le build si le contenu n'est pas exactement: `ITFabrik.Stepper.psd1`, `ITFabrik.Stepper.psm1`, `ITFabrik.Stepper.format.ps1xml`, `LICENSE`, `README.md`.
- Echec ScriptAnalyzer sur artifact build:
  - Reproduire localement:
    ```powershell
    Import-Module PSScriptAnalyzer -MinimumVersion 1.22.0 -Force
    Invoke-ScriptAnalyzer -Path .\dist\ITFabrik.Stepper\ITFabrik.Stepper.psm1 -Settings .\PSScriptAnalyzerSettings.psd1
    ```
  - Corriger le code source, rebuild, puis relancer la publication.
- Version PSGallery a retirer: utiliser l'interface PSGallery (ou `Unpublish-Module` si applicable) et corriger la release.

## Fichiers et commandes utiles
- Manifeste: `ITFabrik.Stepper.psd1`
- Script ouverture cycle: `Scripts/New-DevelopmentCycle.ps1`
- Script fermeture locale: `Scripts/Close-DevelopmentCycle.ps1`
- Script tag: `Scripts/New-ReleaseTag.ps1`
- Workflows: `.github/workflows/ci.yml`, `.github/workflows/pester-coverage.yml`, `.github/workflows/check-tag.yml`, `.github/workflows/publish.yml`
- Build artifact: `Scripts/Build-Module.ps1`, `dist/ITFabrik.Stepper/`
- Tests: `Tests/`, `Tests/PesterConfig.psd1`
