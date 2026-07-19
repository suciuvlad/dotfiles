# Release Checklist

Release target: `v0.1.5`

Verified: 2026-05-11 local gates passed; live DataForSEO blocked by missing credentials in current shell

- [x] Current search requirements memo reviewed for 2026-05-11.
- [x] Source-available commercial license is present.
- [x] Third-party notices are present.
- [x] `python -m compileall scripts marketing_brain tests` passes.
- [x] `python scripts/generate_editorial_assets.py` reproduces `assets/svg/` without drift.
- [x] `python scripts/lint_vault.py --vault assets/template-brain --template` passes.
- [x] `python tests/test_pipeline.py` passes.
- [x] `python scripts/build_demo_vault.py` regenerates `examples/sample-vault`.
- [x] Markdown, HTML, and PDF report smoke checks pass.
- [x] `brain_schema: marketing-brain.v1` appears on all wiki notes.
- [x] Community Obsidian plugins are disabled by default.
- [x] Raw DataForSEO responses and copied raw exports are mode `0600`.
- [x] No credentials, private keys, local home paths, real client domains, or `.env` files appear in source or ZIP artifacts.
- [x] `install.sh --target codex|claude|agents|all` and `uninstall.sh --target codex|claude|agents|all` pass against temporary homes.
- [x] `python scripts/package_release.py --version 0.1.5` builds all-in-one, template, sample-vault, source ZIPs, manifest, and checksums.
- [ ] Live DataForSEO full-pipeline verification is blocked until both `DATAFORSEO_LOGIN` and `DATAFORSEO_PASSWORD` are present in the shell.

Release is ready when all boxes are checked and the tagged GitHub release has
the generated ZIPs, manifest, and checksums attached.
