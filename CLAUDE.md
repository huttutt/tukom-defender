# CLAUDE.md — GitFlow Rules for TUKOM Defender

This document defines **strict GitFlow usage** for the TUKOM Defender project.  
Any human or assistant contributing to this repository must follow these rules without exception.

---

## 1. Branch Model Overview

We use **GitFlow** with the following permanent branches:

- `main`  
  - Always deployable, always stable.
  - Reflects production-ready releases only.

- `develop`  
  - Integration branch for upcoming work.
  - All completed features and fixes merge here first.

No direct commits to `main` or `develop` are allowed.  
All changes go through **short-lived branches** and **pull requests**.

Ephemeral branch types:

- `feature/*`
- `bugfix/*`
- `release/*`
- `hotfix/*`
- `chore/*` (for tooling, CI, config changes only)

---

## 2. Branch Naming Conventions

Use **kebab-case** and descriptive names. Include issue IDs when available.

### 2.1 Feature branches

- Base branch: `develop`
- Pattern:  
  - `feature/<short-description>`  
  - `feature/<ticket-id>-<short-description>`

Examples:
- `feature/procedural-map-generation`
- `feature/42-enemy-spawn-logic`

### 2.2 Bugfix branches (non-production bugs)

- Base branch: `develop`
- Pattern:
  - `bugfix/<short-description>`
  - `bugfix/<ticket-id>-<short-description>`

Examples:
- `bugfix/fix-enemy-bottom-detection`
- `bugfix/101-ammo-counter-negative`

### 2.3 Release branches

- Base branch: `develop`
- Pattern:
  - `release/x.y.z`

Example:
- `release/0.1.0`

### 2.4 Hotfix branches (production-critical)

- Base branch: `main`
- Pattern:
  - `hotfix/x.y.z-hot-topic`

Example:
- `hotfix/0.1.1-fix-crash-on-start`

### 2.5 Chore branches (non-feature code changes)

- Base branch: `develop`
- Pattern:
  - `chore/<short-description>`

Examples:
- `chore/update-godot-version`
- `chore/ci-lint-config`

---

## 3. Workflow Summary

### 3.1 New work (feature/bugfix/chore)

1. **Branch from** `develop`:
   - `git checkout develop`
   - `git pull`
   - `git checkout -b feature/procedural-map-generation`

2. Implement changes:
   - Keep commits small and focused.
   - Follow commit rules below.

3. Rebase on latest `develop` before opening PR:
   - `git fetch`
   - `git rebase origin/develop`

4. Open a Pull Request **into `develop`**:
   - Title: `[Feature] Procedural map generation`
   - Describe scope, risks, and testing.

5. Wait for review and approval; address review comments.

6. Merge via **fast-forward or squash** (prefer squash for small features).

7. Delete the branch after merge.

### 3.2 Release workflow

Used when preparing a version for distribution.

1. From `develop`:
   - `git checkout develop`
   - `git pull`
   - `git checkout -b release/x.y.z`

2. Only allow:
   - Final polishing.
   - Version bumps.
   - Minor non-breaking fixes.

3. When release is ready:
   - Merge `release/x.y.z` → `main`
   - Tag the release on `main` as `vX.Y.Z`
   - Merge `release/x.y.z` → `develop` (to bring any final changes back)

4. Delete the `release/x.y.z` branch.

### 3.3 Hotfix workflow

Used only for critical issues on `main`.

1. From `main`:
   - `git checkout main`
   - `git pull`
   - `git checkout -b hotfix/x.y.z-description`

2. Fix the issue with minimal scope.

3. When ready:
   - Merge `hotfix/x.y.z-description` → `main`
   - Tag the release on `main` as `vX.Y.Z`
   - Merge `hotfix/x.y.z-description` → `develop` (to keep branches in sync)

4. Delete the hotfix branch.

---

## 4. Commit Message Guidelines

Commit messages must be:

- Clear, imperative, and concise.
- Describing **what** and **why** (not just “fix stuff”).

Format:
- First line: max ~50 characters, imperative.
- Optional body: more detail, bullets as needed.

Examples:
- `Add enemy spawn timer and container`
- `Fix ammo going negative when clicking outside map`
- `Refactor Map.gd to expose is_inside_map helper`

Disallowed:
- `misc changes`
- `fix`
- `wip`
- `updates`

If using an issue tracker, reference IDs in the body:
- `Refs #42`

---

## 5. PR (Pull Request) Rules

Every change must go through a PR.

### 5.1 General rules

- Target branch:
  - `develop` for features, bugfixes, chores.
  - `main` only for release/hotfix merges (via the dedicated workflows above).
- PR title: `[Type] Short description`
  - Types: `Feature`, `Bugfix`, `Chore`, `Release`, `Hotfix`.

Examples:
- `[Feature] Implement tap-to-fire shell system`
- `[Bugfix] Fix enemy bottom-line detection`
- `[Chore] Configure GitHub Actions pipeline`

### 5.2 PR description template

- **Summary**: what this PR does.
- **Scope**: main files/areas affected.
- **Testing**: how this was tested (e.g. “Ran in Godot editor, clicked map, verified enemies die”).
- **Risks**: any known risks or edge cases.

### 5.3 Reviews

- At least **one review** required before merging (human or trusted reviewer).
- No self-approval merges if possible.
- Address all comments or explicitly explain why not.

---

## 6. Rebase vs Merge

- For **branch maintenance**, prefer **rebase** over merge to keep history linear:
  - Before opening a PR:
    - `git fetch`
    - `git rebase origin/develop`
- For **integrating PRs**:
  - Use **squash merge** or **fast-forward** in the UI:
    - Squash: good for many small commits → one coherent feature commit.
    - Fast-forward: if branch is clean and up-to-date.

Avoid long “merge commit chains” like `Merge branch 'develop' into feature/...` unless absolutely necessary.

---

## 7. Versioning & Tags

We use **Semantic Versioning**:

- `MAJOR.MINOR.PATCH` → `X.Y.Z`

Rules:

- Increment `MAJOR` when making incompatible gameplay/system changes (breaking save formats, etc.).
- Increment `MINOR` when adding new features in a backwards-compatible way.
- Increment `PATCH` for bugfixes and small improvements.

On every release or hotfix:

- Tag the commit on `main`:
  - `vX.Y.Z` (e.g. `v0.1.0`)

---

## 8. Project-Specific Notes (Godot)

- Do not commit editor cache or platform exports.
- Include the `.godot` recommended ignore patterns in `.gitignore`.
- Scenes and scripts must stay in the directories specified in the PRD (`/scenes`, `/scripts`, `/assets`).

When making engine- or project-wide configuration changes (e.g. Project Settings, input map):

- Use a **chore** branch:
  - `chore/update-project-settings`
- Describe clearly in the PR what changed and why.

---

## 9. Rules for Automated Assistants

When using an assistant to modify this repo:

1. **Never edit directly on `main` or `develop`.**  
   Always:
   - Checkout `develop`.
   - Create or switch to a `feature/*`, `bugfix/*`, `chore/*`, `release/*`, or `hotfix/*` branch.

2. Before making changes:
   - Pull latest:
     - `git checkout develop`
     - `git pull`
     - `git checkout -b <branch-name>` (if new branch)

3. Make changes **only** related to the branch purpose:
   - `feature/*` → new functionality.
   - `bugfix/*` → targeted fixes.
   - `chore/*` → infrastructure and tooling.
   Avoid mixing unrelated tasks.

4. After changes:
   - Run formatting or lint steps if defined.
   - Ensure the project runs in Godot (at least at a basic level) if relevant.

5. Commit messages must follow the rules in section 4.

6. Open a PR with a proper description and wait for review.

---

## 10. What Is Not Allowed

- Direct commits to `main` or `develop`.
- Force pushes to `main` or `develop`.
- Long-lived feature branches that are never rebased on `develop`.
- “WIP” commits and PRs without clear description.
- Combining unrelated changes (e.g., new feature + refactor + tooling) into one branch.

---

## 11. Quick Reference

**Start new feature:**
- `git checkout develop`
- `git pull`
- `git checkout -b feature/<name>`

**Update feature before PR:**
- `git fetch`
- `git rebase origin/develop`

**Finish feature:**
- Push branch.
- Open PR → `develop`.
- After approval, squash/merge PR.
- Delete branch.

**Start release:**
- `git checkout develop`
- `git pull`
- `git checkout -b release/x.y.z`

**Start hotfix:**
- `git checkout main`
- `git pull`
- `git checkout -b hotfix/x.y.z-description`

Follow this document strictly for all changes to the TUKOM Defender repository.