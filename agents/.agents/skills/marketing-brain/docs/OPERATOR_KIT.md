# 5-Minute Operator Kit

## 1. Install

```bash
./install.sh --target codex
python -m pip install -e ".[pdf]"
marketing-brain --help
```

Use `--target claude`, `--target agents`, or `--target all` when installing
for another runtime.

## 2. Open The Template

Open `assets/template-brain/` in Obsidian. Start at:

1. `CODEX.md`
2. `wiki/hot.md`
3. `wiki/index.md`
4. `wiki/meta/Start Here.md`

Community plugins ship disabled. Enable optional plugins only after reviewing
the vault README.

## 3. Build The Demo Vault

```bash
marketing-brain demo
marketing-brain lint --vault examples/sample-vault
marketing-brain report --vault examples/sample-vault --html-only
```

The demo uses synthetic fixtures and does not call DataForSEO.

## 4. Scaffold A Client

```bash
marketing-brain new acme-growth \
  --site https://www.example.com \
  --niche "B2B SaaS workflow automation" \
  --business-type saas \
  --owner "Strategy Owner"
```

## 5. Run Research

```bash
marketing-brain competitors --vault ~/marketing-brain-vaults/acme-growth --site https://www.example.com --dry-run
marketing-brain competitors --vault ~/marketing-brain-vaults/acme-growth --site https://www.example.com --seed-keywords "workflow automation software,b2b automation platform"
marketing-brain keywords --vault ~/marketing-brain-vaults/acme-growth
marketing-brain xlsx --vault ~/marketing-brain-vaults/acme-growth
marketing-brain paa --vault ~/marketing-brain-vaults/acme-growth
marketing-brain synthesize --vault ~/marketing-brain-vaults/acme-growth
marketing-brain report --vault ~/marketing-brain-vaults/acme-growth
marketing-brain next --vault ~/marketing-brain-vaults/acme-growth
```

Live DataForSEO steps require `DATAFORSEO_LOGIN` and `DATAFORSEO_PASSWORD`.
Keep `--cost-cap` and `--total-cap` conservative until the source site and
market are verified.
