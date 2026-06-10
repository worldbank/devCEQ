# CLAUDE.md

This file provides configuration and conventions for AI agents working in this repository.

## Agent skills

### Issue tracker

Issues live in GitHub Issues on `worldbank/devCEQ`. See `.docs/agents/issue-tracker.md`.

### Triage labels

Default label vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `.docs/agents/triage-labels.md`.

### Domain .docs

Single-context repo — one `CONTEXT.md` + `.docs/adr/` at the repo root. See `.docs/agents/domain.md`.

## Running R code

`Rscript` is not on PATH. Use the full path:

```powershell
& "C:\Program Files\R\R-4.5.3\bin\Rscript.exe" -e "your_expression_here"
```

To run covr coverage:

```powershell
& "C:\Program Files\R\R-4.5.3\bin\Rscript.exe" -e "covr::package_coverage(quiet = FALSE)"
```
