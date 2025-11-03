# Procédure GitHub pour itfabrik.stepper

Ce document décrit la création du dépôt GitHub, la configuration des secrets et des workflows pour publier le module sur PowerShell Gallery et exécuter les tests Pester.

## 1) Créer le dépôt sur GitHub
- Nom: `itfabrik.stepper`
- Visibilite: Public (recommande pour un module publie)
- Ne pas initialiser avec README / .gitignore / licence (ces fichiers existent deja localement)

Via l'UI GitHub:
1. New repository ^ Name: `itfabrik.stepper`
2. Public
3. Laisser decoche "Add a README", "Add .gitignore", "Choose a license"
4. Create repository

Option CLI (si GitHub CLI):
```bash
gh repo create itfabrik.stepper --public --source . --remote origin --push
```

## 2) Préparer le dépôt local
Dans `c:\Developpement\Scripting\Modules\itfabrik.stepper`:
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
git commit -m "Initial commit: itfabrik.stepper"
```

## 3) Lier le remote et pousser
Récupérez l'URL GitHub (ex: `https://github.com/<org>/itfabrik.stepper.git`) puis:
```powershell
git remote add origin https://github.com/<org>/itfabrik.stepper.git
git push -u origin main
```

## 4) Configurer GitHub Actions
Deux workflows existent dans `.github/workflows`:
- CI Pester: `.github/workflows/ci.yml` - exécute les tests Pester et l’analyseur sur plusieurs OS.
- Release + Publication PSGallery: `.github/workflows/release.yml` - déclenché par un tag `v*`, crée une release GitHub et publie sur PowerShell Gallery.

Permissions Actions (par defaut suffisantes):
- Settings ^ Actions ^ General ^ Workflow permissions ^ Read repository contents

## 5) Secrets requis
- `PSGALLERY_API_KEY` (publication PowerShell Gallery)
- `RELEASE_TOKEN` (création de release GitHub via `softprops/action-gh-release`)
- PowerShell Gallery ^ Profile ^ API Keys ^ Creer une cle (Scope: Push, expiration selon besoin)
- GitHub ^ Repository ^ Settings ^ Secrets and variables ^ Actions ^ New repository secret
  - Name: `PSGALLERY_API_KEY`
  - Value: la cle API copiee

## 6) Publier une nouvelle version

Deux options pour garder `ModuleVersion` et le tag `vX.Y.Z` alignes:

- Source de vérité = tag (workflow actuel)
  1. Mettre à jour `ModuleVersion` dans `itfabrik.stepper.psd1` (ex: `X.Y.Z`).
  2. Commit & push:
     ```powershell
     git add itfabrik.stepper.psd1
     git commit -m "Bump version to X.Y.Z"
     git push
     ```
  3. Créer et pousser le tag `vX.Y.Z`:
     ```powershell
     git tag vX.Y.Z
     git push origin vX.Y.Z
     ```
  4. Le workflow `release.yml` va packager, créer la release et publier sur PSGallery (si `PSGALLERY_API_KEY` est présent).

- Source de verite = tag (moins pratique)
  - Creer un tag `vX.Y.Z`, puis mettre a jour manuellement `ModuleVersion = 'X.Y.Z'` dans le manifeste dans le meme commit/PR. (Le workflow refusera la publication si non aligne.)

Le workflow de publication contient une etape de validation qui echoue si `ModuleVersion` <> `vX.Y.Z`.

## 7) Bonnes pratiques
- Proteger `main` (PRs et reviews) une fois le depot public.
- Maintenir `ModuleVersion` et le tag `vX.Y.Z` alignes.
- Ajouter des Topics GitHub: `powershell`, `powershell-module`, `logging`.
- Tests Pester: les fichiers dans `Tests/` sont lances par `.github/workflows/ci.yml`.

Références utiles:
- CI: `.github/workflows/ci.yml`
- Release + publication PSGallery: `.github/workflows/release.yml`
- Manifeste module: `itfabrik.stepper.psd1`
