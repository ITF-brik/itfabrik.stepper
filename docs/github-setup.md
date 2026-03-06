# Procedure GitHub pour ITFabrik.Stepper

Ce document decrit la creation du depot GitHub, la configuration des secrets et des workflows pour publier le module sur PowerShell Gallery et executer les tests Pester.

## 1) Creer le depot sur GitHub
- Nom: `ITFabrik.Stepper`
- Visibilite: Public (recommande pour un module publie)
- Ne pas initialiser avec README / .gitignore / licence (ces fichiers existent deja localement)

Via l'UI GitHub:
1. New repository ^ Name: `ITFabrik.Stepper`
2. Public
3. Laisser decoche "Add a README", "Add .gitignore", "Choose a license"
4. Create repository

Option CLI (si GitHub CLI):
```bash
gh repo create ITFabrik.Stepper --public --source . --remote origin --push
```

## 2) Preparer le depot local
Dans `c:\Developpement\Scripting\Modules\ITfabrik.Stepper`:
```powershell
git init
git branch -M main
# Optionnel : identite locale si necessaire
git config user.name "Votre Nom"
git config user.email "votre.email@domaine"
```
Un `.gitignore` adapte a ete ajoute: `.gitignore`.
Puis premier commit:
```powershell
git add .
git commit -m "Initial commit: ITFabrik.Stepper"
```

## 3) Lier le remote et pousser
Recuperez l'URL GitHub (ex: `https://github.com/<org>/ITFabrik.Stepper.git`) puis:
```powershell
git remote add origin https://github.com/<org>/ITFabrik.Stepper.git
git push -u origin main
```

## 4) Configurer GitHub Actions
Quatre workflows existent dans `.github/workflows`:
- `.github/workflows/ci.yml` - execute ScriptAnalyzer et les tests Pester sur `push`, `pull_request` et `workflow_dispatch`.
- `.github/workflows/pester-coverage.yml` - execute Pester avec gate de couverture.
- `.github/workflows/check-tag.yml` - verifie qu'un tag `vX.Y.Z` correspond a `ModuleVersion`.
- `.github/workflows/publish.yml` - declenche manuellement ou lors d'une release publiee, construit l'artifact `dist/ITFabrik.Stepper`, publie sur PowerShell Gallery et peut supprimer la branche `cycle/*` associee apres succes.

Permissions Actions (par defaut suffisantes):
- Settings ^ Actions ^ General ^ Workflow permissions ^ Read repository contents

## 5) Secret PowerShell Gallery
Le workflow de publication requiert `PSGALLERY_API_KEY`.
- PowerShell Gallery ^ Profile ^ API Keys ^ Creer une cle (Scope: Push, expiration selon besoin)
- GitHub ^ Repository ^ Settings ^ Secrets and variables ^ Actions ^ New repository secret
  - Name: `PSGALLERY_API_KEY`
  - Value: la cle API copiee

## 6) Publier une nouvelle version

Source de verite recommandee = manifeste:
1. Creer d'abord la branche de cycle si le travail n'est pas deja isole:
   ```powershell
   ./Scripts/New-DevelopmentCycle.ps1 -Type '<Type>' -Objective '<Objectif>' -Push
   ```
1. Mettre a jour `ModuleVersion` dans `ITFabrik.Stepper.psd1`.
2. Commit & push:
   ```powershell
   git add ITFabrik.Stepper.psd1 CHANGELOG.md
   git commit -m "Bump version to X.Y.Z"
   git push
   ```
3. Creer et pousser le tag depuis le manifeste:
   ```powershell
   ./Scripts/New-ReleaseTag.ps1 -Push
   ```
4. Le workflow `.github/workflows/check-tag.yml` verifie automatiquement l'alignement tag/version.
5. Creer ensuite la release GitHub en selectionnant ce tag et en visant la branche `cycle/*` active si elle doit etre fermee automatiquement.
6. Le workflow `.github/workflows/publish.yml` publie sur PowerShell Gallery lors de `release: published`, puis supprime la branche distante `cycle/*` si la publication reussit.

## 7) Bonnes pratiques
- Proteger `main` (PRs et reviews) une fois le depot public.
- Maintenir `ModuleVersion` et le tag `vX.Y.Z` alignes.
- Ajouter des Topics GitHub: `powershell`, `powershell-module`, `logging`, `workflow`.
- Tests Pester: les fichiers dans `Tests/` sont lances par `.github/workflows/ci.yml`.

References utiles:
- Cycle de developpement: `docs/development-cycle.md`
- CI: `.github/workflows/ci.yml`
- Coverage: `.github/workflows/pester-coverage.yml`
- Verification tag: `.github/workflows/check-tag.yml`
- Publication: `.github/workflows/publish.yml`
- Scripts: `Scripts/Build-Module.ps1`, `Scripts/Publish-PSGallery.ps1`, `Scripts/New-ReleaseTag.ps1`, `Scripts/New-DevelopmentCycle.ps1`, `Scripts/Close-DevelopmentCycle.ps1`
- Manifeste module: `ITFabrik.Stepper.psd1`
