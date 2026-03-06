# Repository Instructions

## Development Cycle Workflow
- When the user says `Nouveau cycle de développement`, create and switch to a dedicated implementation branch before making code changes.
- Use `Scripts/New-DevelopmentCycle.ps1` to create the branch.
- Branch naming convention: `cycle/YYYYMMDD-<type>-<objective>`.
- Keep release work associated with that cycle branch until the version is published successfully.
- When a release succeeds, close the cycle branch:
  - remote branch deletion is handled by `.github/workflows/publish.yml` for `cycle/*` branches,
  - local branch cleanup can be done with `Scripts/Close-DevelopmentCycle.ps1`.

## Release Workflow
- Prefer creating the GitHub release from the active `cycle/*` branch so the publish workflow can identify and delete it after success.
- If the publish workflow is triggered manually, provide the cycle branch name through the `release_branch` input when relevant.
