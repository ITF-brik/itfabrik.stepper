# Checklist de release

Cette page est volontairement courte.

Le contexte complet du flux se trouve dans `docs/development-cycle.md`.

## Avant de commencer
- Etre sur la branche `cycle/*` du travail a publier
- Avoir mis a jour :
  - `ITFabrik.Stepper.psd1`
  - `CHANGELOG.md`
- Avoir pousse les derniers commits

## Version stable vs prerelease
- Release stable :
  - `ModuleVersion = '1.0.9'`
  - `PrivateData.PSData.Prerelease = $null`
  - tag attendu : `v1.0.9`
- Release alpha/beta/rc :
  - `ModuleVersion = '1.0.9'`
  - `PrivateData.PSData.Prerelease = 'alpha1'` (ou `beta1`, `rc1`, etc.)
  - tag attendu : `v1.0.9-alpha1`

## Etapes
1. Construire et valider l'artifact :
   ```powershell
   ./Scripts/Build-Module.ps1
   ./Scripts/Publish-PSGallery.ps1 -ModulePath .\dist\ITFabrik.Stepper -ValidateOnly
   ```
2. Creer et pousser le tag :
   ```powershell
   ./Scripts/New-ReleaseTag.ps1 -Push
   ```
3. Creer la release GitHub sur le tag attendu (`vX.Y.Z` ou `vX.Y.Z-alpha1`).
4. Si la version est prerelease, marquer aussi la release GitHub comme prerelease.
5. Choisir la branche `cycle/*` active comme `Target` si elle doit etre fermee automatiquement apres succes.
6. Laisser `.github/workflows/publish.yml` publier sur PowerShell Gallery.

## Resultat attendu
- `check-tag.yml` valide l'alignement tag/version
- `publish.yml` publie le module
- la branche distante `cycle/*` est supprimee automatiquement si la release a ete creee depuis cette branche

## Apres succes
- Verifier la version sur PowerShell Gallery
- Supprimer la branche locale si besoin :
  ```powershell
  ./Scripts/Close-DevelopmentCycle.ps1 -Branch '<nom-de-branche>'
  ```

## En cas d'echec
- Revoir `docs/development-cycle.md`
- Regenerer l'artifact localement
- Verifier les logs GitHub Actions du workflow en echec
