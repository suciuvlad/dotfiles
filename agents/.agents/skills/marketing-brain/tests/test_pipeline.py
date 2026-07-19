#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path


REPO = Path(__file__).resolve().parent.parent


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="marketing-brain-test-") as tmp:
        tmp_path = Path(tmp)
        test_scaffold_and_lint(tmp_path)
        test_demo_and_report()
        test_dry_runs(tmp_path)
        test_missing_credentials(tmp_path)
        test_install_uninstall(tmp_path)
    print("Pipeline tests passed")
    return 0


def test_scaffold_and_lint(tmp_path: Path) -> None:
    run([
        sys.executable,
        "scripts/scaffold_vault.py",
        "--client",
        "test-client",
        "--site",
        "https://www.example.com",
        "--niche",
        "B2B SaaS workflow automation",
        "--business-type",
        "saas",
        "--owner",
        "Test Owner",
        "--out-dir",
        str(tmp_path),
    ])
    vault = tmp_path / "test-client"
    run([sys.executable, "scripts/lint_vault.py", "--vault", str(vault)])
    manifest = json.loads((vault / ".raw" / ".manifest.json").read_text(encoding="utf-8"))
    assert manifest["scaffold_history"][-1]["site_url"] == "https://www.example.com"
    assert stat_mode(vault / ".raw" / ".manifest.json") == "0o600"


def test_demo_and_report() -> None:
    run([sys.executable, "scripts/build_demo_vault.py"])
    vault = REPO / "examples" / "sample-vault"
    run([sys.executable, "scripts/lint_vault.py", "--vault", str(vault)])
    plan = vault / "wiki" / "deliverables" / "ULTIMATE BEAST Plan.md"
    text = plan.read_text(encoding="utf-8")
    assert "INVOKE beast-planner" not in text
    assert "Source Manifest" in text
    with tempfile.TemporaryDirectory(prefix="marketing-brain-report-") as tmp:
        report = Path(tmp) / "test-report.pdf"
        run([
            sys.executable,
            "scripts/render_beast_pdf.py",
            "--vault",
            str(vault),
            "--out",
            str(report),
            "--html-only",
        ])
        assert report.with_suffix(".html").exists()


def test_dry_runs(tmp_path: Path) -> None:
    vault = tmp_path / "test-client"
    competitors = vault / ".raw" / "sources" / "dataforseo" / "competitors-2026-05-11.json"
    competitors.parent.mkdir(parents=True, exist_ok=True)
    competitors.write_text(
        json.dumps({
            "site": "https://www.example.com",
            "competitors": [{"domain": "competitor.example"}],
        }),
        encoding="utf-8",
    )
    run([
        sys.executable,
        "scripts/pull_competitor_kw.py",
        "--vault",
        str(vault),
        "--dry-run",
    ])
    assert not list(competitors.parent.glob("competitor-kw-*.json"))


def test_install_uninstall(tmp_path: Path) -> None:
    install_root = tmp_path / "skills"
    run(["bash", "install.sh", "--target", "codex", "--dest", str(install_root)])
    installed = install_root / "marketing-brain"
    assert (installed / "SKILL.md").exists()
    assert (installed / "scripts" / "scaffold_vault.py").exists()
    run(["bash", "uninstall.sh", "--target", "codex", "--dest", str(install_root)])
    assert not installed.exists()


def test_missing_credentials(tmp_path: Path) -> None:
    vault = tmp_path / "missing-creds"
    env = dict(os.environ)
    env.pop("DATAFORSEO_LOGIN", None)
    env.pop("DATAFORSEO_PASSWORD", None)
    proc = subprocess.run([
        sys.executable,
        "scripts/find_competitors.py",
        "--vault",
        str(vault),
        "--site",
        "https://www.example.com",
        "--seed-keywords",
        "workflow automation software",
    ], cwd=REPO, env=env, capture_output=True, text=True)
    assert proc.returncode != 0
    assert "DATAFORSEO_LOGIN" in proc.stderr
    assert "DATAFORSEO_PASSWORD" in proc.stderr
    assert not vault.exists()


def stat_mode(path: Path) -> str:
    return oct(path.stat().st_mode & 0o777)


def run(cmd: list[str]) -> None:
    subprocess.run(cmd, cwd=REPO, check=True)


if __name__ == "__main__":
    raise SystemExit(main())
