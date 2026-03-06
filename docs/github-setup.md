# Mise en place GitHub

Ce document couvre uniquement la mise en place initiale du depot GitHub.

Pour le flux de travail quotidien, voir `docs/development-cycle.md`.
Pour publier une version, voir `docs/release-procedure.md`.

## 1) Creer le depot
- Nom recommande : `ITFabrik.Stepper`
- Visibilite : Public
- Ne pas pre-initialiser le depot avec README, licence ou `.gitignore` si le projet existe deja localement.

Option CLI :
```bash
gh repo create ITFabrik.Stepper --public --source . --remote origin --push
```

## 2) Preparer le depot local
Dans `c:\Developpement\Scripting\Modules\ITfabrik.Stepper` :
```powershell
git init
git branch -M main
git remote add origin https://github.com/<org>/ITFabrik.Stepper.git
git push -u origin main
```

## 3) Configurer les secrets
- Secret requis :
  - `PSGALLERY_API_KEY`
- Emplacement :
  - GitHub > Repository > Settings > Secrets and variables > Actions

## 4) Workflows en place
- `.github/workflows/ci.yml`
  - tests et ScriptAnalyzer
- `.github/workflows/pester-coverage.yml`
  - gate de couverture
- `.github/workflows/check-tag.yml`
  - verification tag/version
- `.github/workflows/publish.yml`
  - publication PowerShell Gallery
  - suppression automatique de la branche distante `cycle/*` apres succes, si applicable

## 5) Recommandations depot
- Proteger `main`
- Activer les PRs et reviews
- Garder `main` comme branche stable
- Utiliser une branche `cycle/*` pour chaque cycle de developpement

## References
- Flux recurrent : `docs/development-cycle.md`
- Checklist release : `docs/release-procedure.md`
