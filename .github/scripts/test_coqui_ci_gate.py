#!/usr/bin/env python3
"""Integration tests for `.github/scripts/coqui_ci_gate.sh` and its handoff to `coqui/tool/test_all.sh`.

Stdlib-only Python 3.12 (`unittest`).
"""

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
GATE_SCRIPT = SCRIPT_DIR / "coqui_ci_gate.sh"
TEST_ALL_SCRIPT = REPO_ROOT / "coqui" / "tool" / "test_all.sh"


def _git(repo: Path, *args: str) -> str:
    res = subprocess.run(
        ["git", "-C", str(repo), *args],
        capture_output=True,
        text=True,
        check=False,
    )
    if res.returncode != 0:
        raise RuntimeError(
            f"git {' '.join(args)} failed (exit {res.returncode}): {res.stderr.strip()}"
        )
    return res.stdout.strip()


def _write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def _parse_kv_file(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    if not path.is_file():
        return result
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            result[k] = v
    return result


class CoquiCiGateTests(unittest.TestCase):
    def _init_temp_repo(self, root: Path) -> str:
        _git(root, "init", "-q", "-b", "main")
        _git(root, "config", "user.name", "Test Bot")
        _git(root, "config", "user.email", "test@example.com")
        _write(root / "README.md", "# test\n")
        _write(root / "docs" / "note.md", "# note\n")
        _write(root / "content" / "games" / "la-lluvia.json", "{}\n")
        _write(root / "historia" / "datos" / "repaso.json", "{}\n")
        _write(
            root / "coqui" / "packages" / "features" / "feature_words" / "lib" / "a.dart",
            "// words\n",
        )
        _write(root / "coqui" / "tool" / "plan_tests.py", "# planner\n")
        _git(root, "add", "-A")
        _git(root, "commit", "-q", "-m", "initial")
        return _git(root, "rev-parse", "HEAD")

    def _run_gate(
        self,
        repo: Path,
        *,
        event: str,
        base: str = "main",
        runner_temp: Path,
    ) -> tuple[subprocess.CompletedProcess[str], dict[str, str], dict[str, str]]:
        gh_out = runner_temp / "github_output.txt"
        gh_env = runner_temp / "github_env.txt"
        gh_out.write_text("", encoding="utf-8")
        gh_env.write_text("", encoding="utf-8")

        env = os.environ.copy()
        for k in ("EVENT_NAME", "BASE_REF", "BASE_SHA", "COQUI_FULL_SUITE", "COQUI_CHANGED_PATHS_FILE"):
            env.pop(k, None)
        env["GITHUB_OUTPUT"] = str(gh_out)
        env["GITHUB_ENV"] = str(gh_env)
        env["RUNNER_TEMP"] = str(runner_temp)

        proc = subprocess.run(
            ["bash", str(GATE_SCRIPT), "--event", event, "--base", base],
            cwd=str(repo),
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )
        return proc, _parse_kv_file(gh_out), _parse_kv_file(gh_env)

    def _run_test_all_dry_run_with_env(
        self, gh_env: dict[str, str]
    ) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        for k in ("COQUI_FULL_SUITE", "COQUI_CHANGED_PATHS_FILE", "COQUI_CI_EVENT"):
            env.pop(k, None)
        env.update(gh_env)
        return subprocess.run(
            ["bash", str(TEST_ALL_SCRIPT), "--dry-run"],
            cwd=str(REPO_ROOT),
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )

    def test_push_and_workflow_dispatch_set_full_suite(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repo = base / "repo"
            repo.mkdir()
            self._init_temp_repo(repo)

            for event in ("push", "workflow_dispatch"):
                with self.subTest(event=event):
                    rtemp = base / f"rt_{event}"
                    rtemp.mkdir()
                    proc, out, gh_env = self._run_gate(repo, event=event, runner_temp=rtemp)
                    self.assertEqual(proc.returncode, 0, proc.stderr)
                    self.assertEqual(out.get("run"), "true")
                    self.assertEqual(gh_env.get("COQUI_FULL_SUITE"), "1")
                    self.assertEqual(gh_env.get("COQUI_CI_EVENT"), event)

                    dry = self._run_test_all_dry_run_with_env(gh_env)
                    self.assertEqual(dry.returncode, 0, dry.stderr)
                    self.assertIn("Mode: full", dry.stdout)

    def test_pr_docs_only_skips_ci(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repo = base / "repo"
            repo.mkdir()
            rtemp = base / "rt"
            rtemp.mkdir()
            self._init_temp_repo(repo)

            _git(repo, "checkout", "-q", "-b", "docs/readme")
            _write(repo / "docs" / "note.md", "# updated\n")
            _git(repo, "add", "-A")
            _git(repo, "commit", "-q", "-m", "docs change")

            proc, out, gh_env = self._run_gate(repo, event="pull_request", runner_temp=rtemp)
            self.assertEqual(proc.returncode, 0, proc.stderr)
            self.assertEqual(out.get("run"), "false")
            self.assertNotIn("COQUI_CHANGED_PATHS_FILE", gh_env)

    def test_pr_content_only_hands_off_to_content_only_plan(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repo = base / "repo"
            repo.mkdir()
            rtemp = base / "rt"
            rtemp.mkdir()
            self._init_temp_repo(repo)

            _git(repo, "checkout", "-q", "-b", "lane/content/1")
            _write(repo / "content" / "games" / "la-lluvia.json", '{"v": 2}\n')
            _git(repo, "add", "-A")
            _git(repo, "commit", "-q", "-m", "content change")

            proc, out, gh_env = self._run_gate(repo, event="pull_request", runner_temp=rtemp)
            self.assertEqual(proc.returncode, 0, proc.stderr)
            self.assertEqual(out.get("run"), "true")
            self.assertEqual(gh_env.get("COQUI_FULL_SUITE"), "0")
            self.assertEqual(gh_env.get("COQUI_CI_EVENT"), "pull_request")
            changed_file = Path(gh_env["COQUI_CHANGED_PATHS_FILE"])
            self.assertTrue(changed_file.is_file())
            self.assertEqual(
                changed_file.read_text(encoding="utf-8").splitlines(),
                ["content/games/la-lluvia.json"],
            )

            dry = self._run_test_all_dry_run_with_env(gh_env)
            self.assertEqual(dry.returncode, 0, dry.stderr)
            self.assertIn("Mode: content_only", dry.stdout)
            self.assertIn("Packages to test (0):", dry.stdout)

    def test_pr_feature_words_only_hands_off_to_selective_plan(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repo = base / "repo"
            repo.mkdir()
            rtemp = base / "rt"
            rtemp.mkdir()
            self._init_temp_repo(repo)

            _git(repo, "checkout", "-q", "-b", "lane/feature_words/2")
            _write(
                repo / "coqui" / "packages" / "features" / "feature_words" / "lib" / "a.dart",
                "// updated\n",
            )
            _git(repo, "add", "-A")
            _git(repo, "commit", "-q", "-m", "feature_words change")

            proc, out, gh_env = self._run_gate(repo, event="pull_request", runner_temp=rtemp)
            self.assertEqual(proc.returncode, 0, proc.stderr)
            self.assertEqual(out.get("run"), "true")
            self.assertEqual(gh_env.get("COQUI_FULL_SUITE"), "0")

            dry = self._run_test_all_dry_run_with_env(gh_env)
            self.assertEqual(dry.returncode, 0, dry.stderr)
            self.assertIn("Mode: selective", dry.stdout)
            self.assertIn("Packages to test (2):", dry.stdout)
            self.assertIn("feature_words (packages/features/feature_words", dry.stdout)
            self.assertIn("app (app", dry.stdout)

    def test_pr_coqui_tool_change_hands_off_to_full_plan(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repo = base / "repo"
            repo.mkdir()
            rtemp = base / "rt"
            rtemp.mkdir()
            self._init_temp_repo(repo)

            _git(repo, "checkout", "-q", "-b", "lane/tool/3")
            _write(repo / "coqui" / "tool" / "plan_tests.py", "# changed\n")
            _git(repo, "add", "-A")
            _git(repo, "commit", "-q", "-m", "tool change")

            proc, out, gh_env = self._run_gate(repo, event="pull_request", runner_temp=rtemp)
            self.assertEqual(proc.returncode, 0, proc.stderr)
            self.assertEqual(out.get("run"), "true")
            self.assertEqual(gh_env.get("COQUI_FULL_SUITE"), "0")

            dry = self._run_test_all_dry_run_with_env(gh_env)
            self.assertEqual(dry.returncode, 0, dry.stderr)
            self.assertIn("Mode: full", dry.stdout)

    def test_pr_historia_datos_matches_gate(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repo = base / "repo"
            repo.mkdir()
            rtemp = base / "rt"
            rtemp.mkdir()
            self._init_temp_repo(repo)

            _git(repo, "checkout", "-q", "-b", "lane/content/4")
            _write(repo / "historia" / "datos" / "repaso.json", '{"v": 2}\n')
            _git(repo, "add", "-A")
            _git(repo, "commit", "-q", "-m", "historia datos change")

            proc, out, gh_env = self._run_gate(repo, event="pull_request", runner_temp=rtemp)
            self.assertEqual(proc.returncode, 0, proc.stderr)
            self.assertEqual(out.get("run"), "true")
            self.assertEqual(gh_env.get("COQUI_FULL_SUITE"), "0")

            dry = self._run_test_all_dry_run_with_env(gh_env)
            self.assertEqual(dry.returncode, 0, dry.stderr)
            self.assertIn("Mode: selective", dry.stdout)
            self.assertIn("coqui_content", dry.stdout)
            self.assertIn("data_checks", dry.stdout)


if __name__ == "__main__":
    unittest.main()
