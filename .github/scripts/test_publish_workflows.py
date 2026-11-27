#!/usr/bin/env python3
"""Unit and static validation tests for Coquí publish workflows and scripts.

Covers:
  - .github/scripts/sitio_publish_gate.py
  - .github/scripts/stage_pages_site.py
  - .github/scripts/voz_publish_pr.py
  - .github/workflows/coqui-sitio.yml
  - .github/workflows/voz.yml

Stdlib-only Python 3.12 (`unittest`). Makes zero live network calls.
"""

from __future__ import annotations

import io
import os
import re
import stat
import subprocess
import sys
import tempfile
import unittest
import urllib.error
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
sys.path.insert(0, str(SCRIPT_DIR))

import sitio_publish_gate as gate  # noqa: E402
import stage_pages_site as stage  # noqa: E402
import voz_publish_pr as voz_pr  # noqa: E402


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


def _init_repo(path: Path) -> None:
    _git(path, "init", "-q", "-b", "main")
    _git(path, "config", "user.name", "Test Bot")
    _git(path, "config", "user.email", "test@example.com")


def _write_file(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def _commit_all(repo: Path, message: str) -> str:
    _git(repo, "add", "-A")
    _git(repo, "commit", "-q", "-m", message)
    return _git(repo, "rev-parse", "HEAD")


class SitioPublishGateTests(unittest.TestCase):
    def _make_base_repo(self, root: Path) -> str:
        _init_repo(root)
        _write_file(root / "coqui" / ".flutter-version", "3.50.0\n")
        _write_file(root / "coqui" / "BUILD", "17\n")
        _write_file(root / "index.html", "<html>root</html>\n")
        _write_file(root / "prueba" / "index.html", "<html>redirect</html>\n")
        _write_file(root / "historia" / "datos" / "curso.json", "{}\n")
        _write_file(root / "historia" / "audio" / "ready.json", "{}\n")
        _write_file(root / "historia" / "tools" / "voz.py", "# tool\n")
        _write_file(root / "historia" / "notas" / "note.md", "# note\n")
        _write_file(root / "docs" / "readme.md", "# doc\n")
        return _commit_all(root, "initial")

    def test_publish_trigger_and_site_content_predicates(self) -> None:
        trigger_true = [
            "coqui/BUILD",
            "./coqui/BUILD",
            "index.html",
            "prueba/index.html",
            "historia/app.html",
            "historia/audio/ready.json",
            "historia/datos/curso.json",
            "historia/tools_extra.js",
            "historia/notas_extra.md",
        ]
        trigger_false = [
            "historia/tools/voz.py",
            "historia/notas/danny.md",
            "coqui/app/lib/main.dart",
            "coqui/ref/pp/a.png",
            "coqui/requests/r1.md",
            "prueba/main.dart.js",
            "app/index.html",
            "docs/readme.md",
            "AGENTS.md",
        ]
        for path in trigger_true:
            with self.subTest(predicate="trigger", path=path):
                self.assertTrue(gate.is_publish_trigger_path(path))
                self.assertTrue(gate.is_site_content_path(path))
        for path in trigger_false:
            with self.subTest(predicate="trigger", path=path):
                self.assertFalse(gate.is_publish_trigger_path(path))

        site_only_true = [
            "coqui/app/lib/main.dart",
            "coqui/packages/core/coqui_ui/lib/a.dart",
            "coqui/ref_helper.dart",
            "coqui/requests_helper.dart",
        ]
        site_false = [
            "coqui/ref/pp/a.png",
            "coqui/requests/r1.md",
            "historia/tools/voz.py",
            "historia/notas/danny.md",
            "docs/readme.md",
            "AGENTS.md",
        ]
        for path in site_only_true:
            with self.subTest(predicate="site_content", path=path):
                self.assertTrue(gate.is_site_content_path(path))
        for path in site_false:
            with self.subTest(predicate="site_content", path=path):
                self.assertFalse(gate.is_site_content_path(path))

    def test_invalid_build_or_flutter_version_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._make_base_repo(root)

            _write_file(root / "coqui" / "BUILD", "17beta\n")
            with self.assertRaises(ValueError):
                gate.read_flutter_and_build(root)

            _write_file(root / "coqui" / "BUILD", "17\n")
            _write_file(root / "coqui" / ".flutter-version", "   \n")
            with self.assertRaises(ValueError):
                gate.read_flutter_and_build(root)

    def test_non_main_or_pr_builds_artifact_only(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            sha = self._make_base_repo(root)
            out_file = root / "gh_output.txt"

            decision, rc = gate.evaluate_gate(
                repo_root=root,
                event="workflow_dispatch",
                ref="refs/heads/lane/coqui_ui/99",
                sha=sha,
                before_sha="",
                repository="salimocasio-dev/field-notes",
                token="tok",
                skip_api=True,
            )
            self.assertEqual(rc, 0)
            self.assertEqual(decision.flutter, "3.50.0")
            self.assertEqual(decision.build, "17")
            self.assertTrue(decision.should_build)
            self.assertFalse(decision.should_deploy)

            gate.write_github_output(str(out_file), decision)
            written = out_file.read_text(encoding="utf-8")
            self.assertIn("should_build=true\n", written)
            self.assertIn("should_deploy=false\n", written)

            pr_decision, pr_rc = gate.evaluate_gate(
                repo_root=root,
                event="pull_request",
                ref="refs/heads/main",
                sha=sha,
                before_sha="",
                repository="salimocasio-dev/field-notes",
                token="tok",
                skip_api=True,
            )
            self.assertEqual(pr_rc, 0)
            self.assertTrue(pr_decision.should_build)
            self.assertFalse(pr_decision.should_deploy)

    def test_push_noop_and_trigger_cases(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            sha0 = self._make_base_repo(root)

            # 1. Non-trigger path only -> no-op
            _write_file(root / "historia" / "notas" / "note.md", "# updated\n")
            _write_file(root / "docs" / "readme.md", "# updated\n")
            sha1 = _commit_all(root, "docs and notas only")
            dec1, rc1 = gate.evaluate_gate(
                repo_root=root,
                event="push",
                ref="refs/heads/main",
                sha=sha1,
                before_sha=sha0,
                repository="salimocasio-dev/field-notes",
                token="",
                skip_api=True,
            )
            self.assertEqual(rc1, 0)
            self.assertFalse(dec1.should_build)
            self.assertFalse(dec1.should_deploy)

            # 2. Only coqui/BUILD touched with same trimmed value -> no-op
            _write_file(root / "coqui" / "BUILD", "17  \n\n")
            sha2 = _commit_all(root, "whitespace in BUILD")
            dec2, rc2 = gate.evaluate_gate(
                repo_root=root,
                event="push",
                ref="refs/heads/main",
                sha=sha2,
                before_sha=sha1,
                repository="salimocasio-dev/field-notes",
                token="",
                skip_api=True,
            )
            self.assertEqual(rc2, 0)
            self.assertFalse(dec2.should_build)
            self.assertFalse(dec2.should_deploy)

            # 3. coqui/BUILD bumped -> build and deploy (isolating push trigger logic)
            _write_file(root / "coqui" / "BUILD", "18\n")
            sha3 = _commit_all(root, "bump BUILD to 18")
            dec3, rc3 = gate.evaluate_gate(
                repo_root=root,
                event="push",
                ref="refs/heads/main",
                sha=sha3,
                before_sha=sha2,
                repository="salimocasio-dev/field-notes",
                token="",
                skip_api=True,
                require_green_main=False,
            )
            self.assertEqual(rc3, 0)
            self.assertEqual(dec3.build, "18")
            self.assertTrue(dec3.should_build)
            self.assertTrue(dec3.should_deploy)

            # 4. Runtime historia file changed -> build and deploy (isolating push trigger logic)
            _write_file(root / "historia" / "audio" / "ready.json", '{"v":2}\n')
            sha4 = _commit_all(root, "audio ready update")
            dec4, rc4 = gate.evaluate_gate(
                repo_root=root,
                event="push",
                ref="refs/heads/main",
                sha=sha4,
                before_sha=sha3,
                repository="salimocasio-dev/field-notes",
                token="",
                skip_api=True,
                require_green_main=False,
            )
            self.assertEqual(rc4, 0)
            self.assertTrue(dec4.should_build)
            self.assertTrue(dec4.should_deploy)

    def test_deployments_api_filters_legacy_github_pages_and_handles_noop(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            sha0 = self._make_base_repo(root)

            def green_runs(head_sha: str, event: str = "push") -> dict[str, Any]:
                return {
                    "workflow_runs": [
                        {
                            "head_branch": "main",
                            "event": event,
                            "status": "completed",
                            "conclusion": "success",
                            "head_sha": head_sha,
                        }
                    ]
                }

            # Legacy github-pages app deployment on same SHA MUST NOT suppress first Actions deploy.
            def api_legacy_only(url: str, _token: str) -> Any:
                if "/deployments?" in url:
                    return [
                        {
                            "sha": sha0,
                            "statuses_url": "https://api.github.com/repos/o/r/deployments/1/statuses",
                            "performed_via_github_app": {"slug": "github-pages"},
                        }
                    ]
                if "/actions/workflows/coqui.yml/runs" in url:
                    return green_runs(sha0)
                raise AssertionError(f"unexpected URL: {url}")

            dec, rc = gate.evaluate_gate(
                repo_root=root,
                event="workflow_dispatch",
                ref="refs/heads/main",
                sha=sha0,
                before_sha="",
                repository="o/r",
                token="tok",
                api_get=api_legacy_only,
            )
            self.assertEqual(rc, 0)
            self.assertTrue(dec.should_build)
            self.assertTrue(dec.should_deploy)

            # Successful github-actions deployment on same SHA suppresses deploy.
            current_green_sha = sha0

            def api_actions_success(url: str, _token: str) -> Any:
                if "/deployments?" in url:
                    return [
                        {
                            "sha": sha0,
                            "statuses_url": "https://api.github.com/repos/o/r/deployments/2/statuses",
                            "performed_via_github_app": {"slug": "github-pages"},
                        },
                        {
                            "sha": sha0,
                            "statuses_url": "https://api.github.com/repos/o/r/deployments/3/statuses",
                            "performed_via_github_app": {"slug": "github-actions"},
                        },
                    ]
                if url.startswith("https://api.github.com/repos/o/r/deployments/3/statuses"):
                    self.assertIn("per_page=1", url)
                    return [{"state": "success"}]
                if "/actions/workflows/coqui.yml/runs" in url:
                    return green_runs(current_green_sha)
                raise AssertionError(f"unexpected URL: {url}")

            dec_same, rc_same = gate.evaluate_gate(
                repo_root=root,
                event="workflow_dispatch",
                ref="refs/heads/main",
                sha=sha0,
                before_sha="",
                repository="o/r",
                token="tok",
                api_get=api_actions_success,
            )
            self.assertEqual(rc_same, 0)
            self.assertFalse(dec_same.should_build)
            self.assertFalse(dec_same.should_deploy)

            # Force overrides already-deployed SHA (when main CI is green).
            dec_force, rc_force = gate.evaluate_gate(
                repo_root=root,
                event="workflow_dispatch",
                ref="refs/heads/main",
                sha=sha0,
                before_sha="",
                repository="o/r",
                token="tok",
                force=True,
                api_get=api_actions_success,
            )
            self.assertEqual(rc_force, 0)
            self.assertTrue(dec_force.should_build)
            self.assertTrue(dec_force.should_deploy)

            # Failed newest github-actions deployment does NOT suppress retry.
            def api_actions_failed(url: str, _token: str) -> Any:
                if "/deployments?" in url:
                    return [
                        {
                            "sha": sha0,
                            "statuses_url": "https://api.github.com/repos/o/r/deployments/4/statuses",
                            "performed_via_github_app": {"slug": "github-actions"},
                        }
                    ]
                if "/actions/workflows/coqui.yml/runs" in url:
                    return green_runs(sha0)
                return [{"state": "failure"}]

            dec_fail, rc_fail = gate.evaluate_gate(
                repo_root=root,
                event="workflow_dispatch",
                ref="refs/heads/main",
                sha=sha0,
                before_sha="",
                repository="o/r",
                token="tok",
                api_get=api_actions_failed,
            )
            self.assertEqual(rc_fail, 0)
            self.assertTrue(dec_fail.should_build)
            self.assertTrue(dec_fail.should_deploy)

            # workflow_dispatch with only non-site changes since deployed_sha -> no-op.
            _write_file(root / "coqui" / "requests" / "req1.md", "req\n")
            sha1 = _commit_all(root, "requests only")
            dec_dispatch_noop, rc_dispatch_noop = gate.evaluate_gate(
                repo_root=root,
                event="workflow_dispatch",
                ref="refs/heads/main",
                sha=sha1,
                before_sha="",
                repository="o/r",
                token="tok",
                api_get=api_actions_success,
            )
            self.assertEqual(rc_dispatch_noop, 0)
            self.assertFalse(dec_dispatch_noop.should_build)
            self.assertFalse(dec_dispatch_noop.should_deploy)

            # workflow_dispatch with coqui/ app change since deployed_sha -> build & deploy (when green on sha2).
            _write_file(root / "coqui" / "app" / "lib" / "main.dart", "void main() {}\n")
            sha2 = _commit_all(root, "app dart change")
            current_green_sha = sha2
            dec_dispatch_go, rc_dispatch_go = gate.evaluate_gate(
                repo_root=root,
                event="workflow_dispatch",
                ref="refs/heads/main",
                sha=sha2,
                before_sha="",
                repository="o/r",
                token="tok",
                api_get=api_actions_success,
            )
            self.assertEqual(rc_dispatch_go, 0)
            self.assertTrue(dec_dispatch_go.should_build)
            self.assertTrue(dec_dispatch_go.should_deploy)

    def test_deployments_api_error_warns_and_continues(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            sha = self._make_base_repo(root)
            stderr_buf = io.StringIO()

            def api_deployments_boom(url: str, _token: str) -> Any:
                if "/deployments?" in url:
                    raise urllib.error.URLError("temporary network error")
                if "/actions/workflows/coqui.yml/runs" in url:
                    return {
                        "workflow_runs": [
                            {
                                "head_branch": "main",
                                "event": "push",
                                "status": "completed",
                                "conclusion": "success",
                                "head_sha": sha,
                            }
                        ]
                    }
                raise AssertionError(f"unexpected URL: {url}")

            dec, rc = gate.evaluate_gate(
                repo_root=root,
                event="workflow_dispatch",
                ref="refs/heads/main",
                sha=sha,
                before_sha="",
                repository="o/r",
                token="tok",
                api_get=api_deployments_boom,
                stderr=stderr_buf,
            )
            self.assertEqual(rc, 0)
            self.assertTrue(dec.should_build)
            self.assertTrue(dec.should_deploy)
            self.assertIn("warning", stderr_buf.getvalue().lower())

    def test_is_coqui_main_ci_path_predicate(self) -> None:
        for p in (
            "coqui",
            "coqui/BUILD",
            "coqui/app/lib/main.dart",
            ".github/workflows/coqui.yml",
            ".github/scripts/coqui_ci_gate.sh",
            "./coqui/pubspec.yaml",
        ):
            with self.subTest(expected=True, path=p):
                self.assertTrue(gate.is_coqui_main_ci_path(p))

        for p in (
            "historia/audio/ready.json",
            "index.html",
            "prueba/index.html",
            "docs/readme.md",
            ".github/workflows/coqui-sitio.yml",
            "coqui_other/foo.dart",
        ):
            with self.subTest(expected=False, path=p):
                self.assertFalse(gate.is_coqui_main_ci_path(p))

    def test_parse_args_require_green_main_default_and_overrides(self) -> None:
        old_val = os.environ.pop("REQUIRE_GREEN_MAIN", None)
        try:
            self.assertTrue(gate.parse_args([]).require_green_main)
            self.assertFalse(gate.parse_args(["--no-require-green-main"]).require_green_main)
            self.assertTrue(gate.parse_args(["--require-green-main"]).require_green_main)

            for falsy in ("0", "false", "FALSE", "no", "off"):
                os.environ["REQUIRE_GREEN_MAIN"] = falsy
                self.assertFalse(gate.parse_args([]).require_green_main)
                self.assertTrue(gate.parse_args(["--require-green-main"]).require_green_main)

            os.environ["REQUIRE_GREEN_MAIN"] = "1"
            self.assertTrue(gate.parse_args([]).require_green_main)
            self.assertFalse(gate.parse_args(["--no-require-green-main"]).require_green_main)
        finally:
            if old_val is None:
                os.environ.pop("REQUIRE_GREEN_MAIN", None)
            else:
                os.environ["REQUIRE_GREEN_MAIN"] = old_val

    def test_green_main_ci_gate_passes_and_refuses_correctly(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            sha0 = self._make_base_repo(root)

            # Explicit disable returns True without API calls
            ok_off, msg_off = gate.check_main_ci_green(
                "o/r", sha0, "tok", require_green_main=False
            )
            self.assertTrue(ok_off)
            self.assertIn("disabled", msg_off)

            # Passes on green push or workflow_dispatch on exact sha (default require_green_main=True)
            for ev in ("push", "workflow_dispatch"):
                with self.subTest(pass_event=ev):
                    def api_green(url: str, _token: str, event_name: str = ev) -> Any:
                        self.assertIn(
                            "/repos/o/r/actions/workflows/coqui.yml/runs?branch=main&per_page=20",
                            url,
                        )
                        return {
                            "workflow_runs": [
                                {
                                    "head_branch": "main",
                                    "event": event_name,
                                    "status": "completed",
                                    "conclusion": "success",
                                    "head_sha": sha0,
                                }
                            ]
                        }

                    dec_ok, rc_ok = gate.evaluate_gate(
                        repo_root=root,
                        event="workflow_dispatch",
                        ref="refs/heads/main",
                        sha=sha0,
                        before_sha="",
                        repository="o/r",
                        token="tok",
                        skip_api=True,
                        api_get=api_green,
                    )
                    self.assertEqual(rc_ok, 0)
                    self.assertTrue(dec_ok.should_build)
                    self.assertTrue(dec_ok.should_deploy)

            # Passes when latest green run is an ancestor and only non-coqui files changed since
            _write_file(root / "historia" / "audio" / "ready.json", '{"v": 2}\n')
            _write_file(root / "index.html", "<html>updated</html>\n")
            sha_non_coqui = _commit_all(root, "historia audio and index.html")

            def api_green_on_sha0(_url: str, _token: str) -> Any:
                return {
                    "workflow_runs": [
                        {
                            "head_branch": "main",
                            "event": "push",
                            "status": "completed",
                            "conclusion": "success",
                            "head_sha": sha0,
                        }
                    ]
                }

            dec_anc, rc_anc = gate.evaluate_gate(
                repo_root=root,
                event="push",
                ref="refs/heads/main",
                sha=sha_non_coqui,
                before_sha=sha0,
                repository="o/r",
                token="tok",
                skip_api=True,
                api_get=api_green_on_sha0,
            )
            self.assertEqual(rc_anc, 0)
            self.assertTrue(dec_anc.should_build)
            self.assertTrue(dec_anc.should_deploy)

            # Refuses when coqui/BUILD changed since last green ancestor run
            _write_file(root / "coqui" / "BUILD", "18\n")
            sha_build = _commit_all(root, "bump coqui/BUILD")
            stderr_build = io.StringIO()
            dec_build, rc_build = gate.evaluate_gate(
                repo_root=root,
                event="push",
                ref="refs/heads/main",
                sha=sha_build,
                before_sha=sha_non_coqui,
                repository="o/r",
                token="tok",
                skip_api=True,
                api_get=api_green_on_sha0,
                stderr=stderr_build,
            )
            self.assertEqual(rc_build, 1)
            self.assertFalse(dec_build.should_build)
            self.assertFalse(dec_build.should_deploy)
            self.assertIn("coqui/BUILD", dec_build.reason)

            # Refuses when coqui/app/... changed since last green ancestor run
            _write_file(root / "coqui" / "app" / "lib" / "main.dart", "void main() {}\n")
            sha_app = _commit_all(root, "change coqui/app")
            stderr_app = io.StringIO()
            dec_app, rc_app = gate.evaluate_gate(
                repo_root=root,
                event="workflow_dispatch",
                ref="refs/heads/main",
                sha=sha_app,
                before_sha="",
                repository="o/r",
                token="tok",
                skip_api=True,
                api_get=api_green_on_sha0,
                stderr=stderr_app,
            )
            self.assertEqual(rc_app, 1)
            self.assertFalse(dec_app.should_build)
            self.assertFalse(dec_app.should_deploy)
            self.assertIn("coqui/app/lib/main.dart", dec_app.reason)

            # Refuses on red, pending (in_progress, queued), cancelled, empty, PR-only, missing token, API error
            refusal_cases: list[tuple[str, Any, str]] = [
                (
                    "failure",
                    lambda _u, _t: {
                        "workflow_runs": [
                            {
                                "head_branch": "main",
                                "event": "push",
                                "status": "completed",
                                "conclusion": "failure",
                                "head_sha": sha_app,
                            }
                        ]
                    },
                    "not green",
                ),
                (
                    "in_progress",
                    lambda _u, _t: {
                        "workflow_runs": [
                            {
                                "head_branch": "main",
                                "event": "push",
                                "status": "in_progress",
                                "conclusion": None,
                                "head_sha": sha_app,
                            }
                        ]
                    },
                    "pending",
                ),
                (
                    "queued",
                    lambda _u, _t: {
                        "workflow_runs": [
                            {
                                "head_branch": "main",
                                "event": "workflow_dispatch",
                                "status": "queued",
                                "conclusion": None,
                                "head_sha": sha_app,
                            }
                        ]
                    },
                    "pending",
                ),
                (
                    "cancelled",
                    lambda _u, _t: {
                        "workflow_runs": [
                            {
                                "head_branch": "main",
                                "event": "push",
                                "status": "completed",
                                "conclusion": "cancelled",
                                "head_sha": sha_app,
                            }
                        ]
                    },
                    "not green",
                ),
                (
                    "empty_runs",
                    lambda _u, _t: {"workflow_runs": []},
                    "no full 'coqui' workflow runs",
                ),
                (
                    "pr_only_runs",
                    lambda _u, _t: {
                        "workflow_runs": [
                            {
                                "head_branch": "main",
                                "event": "pull_request",
                                "status": "completed",
                                "conclusion": "success",
                                "head_sha": sha_app,
                            }
                        ]
                    },
                    "no full 'coqui' workflow runs",
                ),
                (
                    "api_error",
                    lambda _u, _t: (_ for _ in ()).throw(urllib.error.URLError("offline")),
                    "failed to query",
                ),
                (
                    "malformed_payload",
                    lambda _u, _t: {"unexpected": True},
                    "unexpected workflow runs payload",
                ),
            ]

            for label, fake_api, expected_substr in refusal_cases:
                with self.subTest(refusal=label):
                    err_buf = io.StringIO()
                    dec_bad, rc_bad = gate.evaluate_gate(
                        repo_root=root,
                        event="workflow_dispatch",
                        ref="refs/heads/main",
                        sha=sha_app,
                        before_sha="",
                        repository="o/r",
                        token="tok",
                        force=True,  # force=True MUST NOT bypass green-main check!
                        skip_api=True,
                        api_get=fake_api,
                        stderr=err_buf,
                    )
                    self.assertEqual(rc_bad, 1)
                    self.assertFalse(dec_bad.should_build)
                    self.assertFalse(dec_bad.should_deploy)
                    self.assertIn(expected_substr, dec_bad.reason)
                    self.assertIn("ERROR:", err_buf.getvalue())

            # Refuses when token is missing (even with force=True)
            err_tok = io.StringIO()
            dec_tok, rc_tok = gate.evaluate_gate(
                repo_root=root,
                event="workflow_dispatch",
                ref="refs/heads/main",
                sha=sha_app,
                before_sha="",
                repository="o/r",
                token="",
                force=True,
                skip_api=True,
                stderr=err_tok,
            )
            self.assertEqual(rc_tok, 1)
            self.assertFalse(dec_tok.should_build)
            self.assertFalse(dec_tok.should_deploy)
            self.assertIn("GITHUB_TOKEN", dec_tok.reason)


class StagePagesSiteTests(unittest.TestCase):
    def _populate_fixture(self, root: Path, app_dir: Path) -> None:
        _write_file(root / "index.html", "<!doctype html>root")
        _write_file(root / "historia" / "app.html", "<html>historia</html>")
        _write_file(root / "historia" / "datos" / "curso.json", '{"lecciones":[]}')
        _write_file(root / "historia" / "audio" / "ready.json", '{"hechos":{}}')
        _write_file(root / "historia" / "audio" / ".DS_Store", "junk")
        _write_file(root / "historia" / "escenas" / "__pycache__" / "x.pyc", "pyc")
        _write_file(root / "historia" / "tools" / "voz.py", "# excluded")
        _write_file(root / "historia" / "notas" / "secret.md", "# excluded")
        _write_file(root / "prueba" / "index.html", "<meta http-equiv='refresh'>")
        _write_file(root / "prueba" / "main.dart.js", "stale-16mb-binary")

        _write_file(app_dir / "index.html", "<html>app</html>")
        _write_file(app_dir / "main.dart.js", "console.log('build 17');")
        _write_file(app_dir / "canvaskit" / "canvaskit.js", "// ck")

    def test_stage_filters_verifies_and_hashes_deterministically(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repo = base / "repo"
            app_dir = base / "built_app"
            out_dir = base / "pages_out"
            gh_out = base / "gh_output.txt"
            self._populate_fixture(repo, app_dir)

            sha1, count1 = stage.stage_site(
                repo_root=repo, app_dir=app_dir, out_dir=out_dir, clean=False
            )
            self.assertGreaterEqual(count1, 7)
            self.assertEqual(len(sha1), 64)

            # Included files
            self.assertTrue((out_dir / "index.html").is_file())
            self.assertTrue((out_dir / "app" / "index.html").is_file())
            self.assertTrue((out_dir / "app" / "main.dart.js").is_file())
            self.assertTrue((out_dir / "historia" / "datos" / "curso.json").is_file())
            self.assertTrue((out_dir / "historia" / "audio" / "ready.json").is_file())
            self.assertTrue((out_dir / "prueba" / "index.html").is_file())

            # Excluded files/dirs
            self.assertFalse((out_dir / "historia" / "tools").exists())
            self.assertFalse((out_dir / "historia" / "notas").exists())
            self.assertFalse((out_dir / "historia" / "audio" / ".DS_Store").exists())
            self.assertFalse((out_dir / "historia" / "escenas" / "__pycache__").exists())
            self.assertFalse((out_dir / "prueba" / "main.dart.js").exists())

            # Refuses to overwrite non-empty out without --clean
            with self.assertRaises(ValueError):
                stage.stage_site(
                    repo_root=repo, app_dir=app_dir, out_dir=out_dir, clean=False
                )

            # Succeeds with --clean and produces identical deterministic digest
            sha2, count2 = stage.stage_site(
                repo_root=repo, app_dir=app_dir, out_dir=out_dir, clean=True
            )
            self.assertEqual(sha1, sha2)
            self.assertEqual(count1, count2)

            stage.write_github_output(str(gh_out), sha2, count2)
            out_text = gh_out.read_text(encoding="utf-8")
            self.assertIn(f"site_sha256={sha2}\n", out_text)
            self.assertIn(f"file_count={count2}\n", out_text)

            # Modifying a staged source file changes the digest
            _write_file(app_dir / "main.dart.js", "console.log('build 18');")
            sha3, _ = stage.stage_site(
                repo_root=repo, app_dir=app_dir, out_dir=out_dir, clean=True
            )
            self.assertNotEqual(sha1, sha3)

    def test_stage_missing_required_file_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repo = base / "repo"
            app_dir = base / "built_app"
            out_dir = base / "pages_out"
            self._populate_fixture(repo, app_dir)
            (repo / "historia" / "audio" / "ready.json").unlink()

            with self.assertRaises(ValueError) as ctx:
                stage.stage_site(
                    repo_root=repo, app_dir=app_dir, out_dir=out_dir, clean=True
                )
            self.assertIn("historia/audio/ready.json", str(ctx.exception))

    def test_stage_rejects_out_nested_inside_app_or_historia(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repo = base / "repo"
            app_dir = base / "built_app"
            self._populate_fixture(repo, app_dir)

            for bad_out in (
                app_dir / "nested_out",
                repo / "historia" / "nested_out",
                repo,
                app_dir,
                repo / "historia",
            ):
                with self.subTest(bad_out=str(bad_out)):
                    with self.assertRaises(ValueError) as ctx:
                        stage.stage_site(
                            repo_root=repo,
                            app_dir=app_dir,
                            out_dir=bad_out,
                            clean=True,
                        )
                    self.assertIn("overlaps", str(ctx.exception))

    def test_stage_refuses_symlinks_in_app_or_runtime_historia_but_ignores_excluded(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repo = base / "repo"
            app_dir = base / "built_app"
            out_dir = base / "pages_out"
            outside = base / "outside.txt"
            _write_file(outside, "sensitive")
            self._populate_fixture(repo, app_dir)

            # Symlinks inside excluded historia/tools/ and historia/notas/ are ignored.
            (repo / "historia" / "tools" / "link.txt").symlink_to(outside)
            (repo / "historia" / "notas" / "link.txt").symlink_to(outside)
            sha, count = stage.stage_site(
                repo_root=repo, app_dir=app_dir, out_dir=out_dir, clean=True
            )
            self.assertEqual(len(sha), 64)
            self.assertGreaterEqual(count, 7)

            # Symlink inside app_dir is refused.
            app_link = app_dir / "leak.txt"
            app_link.symlink_to(outside)
            with self.assertRaises(ValueError) as ctx_app:
                stage.stage_site(
                    repo_root=repo, app_dir=app_dir, out_dir=out_dir, clean=True
                )
            self.assertIn("symlink", str(ctx_app.exception).lower())
            app_link.unlink()

            # Symlink inside runtime historia/ is refused.
            his_link = repo / "historia" / "audio" / "leak.mp3"
            his_link.symlink_to(outside)
            with self.assertRaises(ValueError) as ctx_his:
                stage.stage_site(
                    repo_root=repo, app_dir=app_dir, out_dir=out_dir, clean=True
                )
            self.assertIn("symlink", str(ctx_his.exception).lower())
            his_link.unlink()

            # Symlinked directory inside runtime historia/ is also refused.
            outside_dir = base / "outside_dir"
            outside_dir.mkdir()
            his_dir_link = repo / "historia" / "linked_dir"
            his_dir_link.symlink_to(outside_dir)
            with self.assertRaises(ValueError) as ctx_dir:
                stage.stage_site(
                    repo_root=repo, app_dir=app_dir, out_dir=out_dir, clean=True
                )
            self.assertIn("symlink", str(ctx_dir.exception).lower())


class VozPublishPrTests(unittest.TestCase):
    def _setup_clone_with_origin(self, base: Path) -> tuple[Path, Path]:
        origin = base / "origin.git"
        origin.mkdir()
        _git(origin, "init", "-q", "--bare", "-b", "main")

        work = base / "work"
        work.mkdir()
        _init_repo(work)
        _write_file(work / "historia" / "audio" / "ready.json", '{"v":1}\n')
        _write_file(work / "historia" / "cuentos" / "s1.json", '{"clips":{}}\n')
        _commit_all(work, "initial")
        _git(work, "remote", "add", "origin", str(origin))
        _git(work, "push", "-q", "-u", "origin", "main")
        return origin, work

    def _install_fake_gh(self, bin_dir: Path, script_body: str) -> Path:
        bin_dir.mkdir(parents=True, exist_ok=True)
        gh_path = bin_dir / "gh"
        gh_path.write_text("#!/usr/bin/env bash\n" + script_body, encoding="utf-8")
        gh_path.chmod(gh_path.stat().st_mode | stat.S_IXUSR)
        return gh_path

    def _run_voz_script(
        self,
        work: Path,
        args: list[str],
        *,
        extra_env: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        if extra_env:
            env.update(extra_env)
        return subprocess.run(
            [sys.executable, str(SCRIPT_DIR / "voz_publish_pr.py"), "--repo-root", str(work), *args],
            capture_output=True,
            text=True,
            env=env,
            check=False,
        )

    def test_nothing_new_exits_cleanly_without_branch_or_push(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            origin, work = self._setup_clone_with_origin(Path(tmp))
            before_main = _git(origin, "rev-parse", "refs/heads/main")

            res = self._run_voz_script(work, ["--branch", "audio/voz-100"])
            self.assertEqual(res.returncode, 0, res.stderr)
            self.assertIn("nothing new", res.stdout)
            self.assertEqual(_git(work, "rev-parse", "--abbrev-ref", "HEAD"), "main")
            self.assertEqual(_git(origin, "rev-parse", "refs/heads/main"), before_main)
            self.assertEqual(_git(origin, "branch", "--list"), "* main")

    def test_pushes_audio_branch_and_opens_pr_without_touching_main(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            origin, work = self._setup_clone_with_origin(base)
            before_main = _git(origin, "rev-parse", "refs/heads/main")
            args_log = base / "gh_args.txt"
            summary = base / "summary.md"
            fake_bin = base / "bin"
            self._install_fake_gh(
                fake_bin,
                f'printf "%s\\n" "$@" > "{args_log}"\n'
                'echo "https://github.com/salimocasio-dev/field-notes/pull/999"\n',
            )

            _write_file(work / "historia" / "audio" / "ready.json", '{"v":2}\n')
            _write_file(work / "historia" / "muestras" / "clip_ñ.mp3", "mp3data")

            res = self._run_voz_script(
                work,
                [
                    "--modo",
                    "cuento",
                    "--branch",
                    "audio/voz-4242",
                    "--repository",
                    "salimocasio-dev/field-notes",
                    "--step-summary",
                    str(summary),
                ],
                extra_env={"PATH": f"{fake_bin}:{os.environ['PATH']}"},
            )
            self.assertEqual(res.returncode, 0, res.stderr)
            self.assertIn("https://github.com/salimocasio-dev/field-notes/pull/999", res.stdout)

            # Origin main MUST be untouched; new branch MUST exist on origin.
            self.assertEqual(_git(origin, "rev-parse", "refs/heads/main"), before_main)
            pushed_sha = _git(origin, "rev-parse", "refs/heads/audio/voz-4242")
            self.assertNotEqual(pushed_sha, before_main)
            commit_msg = _git(origin, "log", "-1", "--pretty=%s", "refs/heads/audio/voz-4242")
            self.assertEqual(commit_msg, "Audio: cuento")

            gh_args = args_log.read_text(encoding="utf-8")
            self.assertIn("pr\ncreate\n", gh_args)
            self.assertIn("--base\nmain\n", gh_args)
            self.assertIn("--head\naudio/voz-4242\n", gh_args)
            self.assertIn("--title\nAudio: cuento\n", gh_args)
            self.assertIn("pull/999", summary.read_text(encoding="utf-8"))

    def test_refuses_disallowed_staged_path_before_commit(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            origin, work = self._setup_clone_with_origin(Path(tmp))
            _write_file(work / "historia" / "cuentos" / "s1.json", '{"clips":{"a":1}}\n')
            _git(work, "add", "historia/cuentos/s1.json")

            res = self._run_voz_script(work, ["--branch", "audio/voz-bad"])
            self.assertEqual(res.returncode, 1)
            self.assertIn("disallowed staged paths", res.stderr)
            self.assertIn("historia/cuentos/s1.json", res.stderr)
            self.assertEqual(_git(origin, "branch", "--list"), "* main")

    def test_actions_pr_permission_error_exits_zero_with_compare_url(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            origin, work = self._setup_clone_with_origin(base)
            summary = base / "summary.md"
            fake_bin = base / "bin"
            self._install_fake_gh(
                fake_bin,
                'echo "pull request create failed: GraphQL: GitHub Actions is not permitted to create or approve pull requests. (createPullRequest)" >&2\n'
                "exit 1\n",
            )

            _write_file(work / "historia" / "audio" / "clip1.mp3", "audio")
            res = self._run_voz_script(
                work,
                [
                    "--modo",
                    "muestras",
                    "--branch",
                    "audio/voz-5555",
                    "--repository",
                    "salimocasio-dev/field-notes",
                    "--step-summary",
                    str(summary),
                ],
                extra_env={"PATH": f"{fake_bin}:{os.environ['PATH']}"},
            )
            self.assertEqual(res.returncode, 0, res.stderr)
            expected_url = (
                "https://github.com/salimocasio-dev/field-notes/compare/main...audio/voz-5555?expand=1"
            )
            self.assertIn("::notice::", res.stdout)
            self.assertIn(expected_url, res.stdout)
            self.assertIn(expected_url, summary.read_text(encoding="utf-8"))
            # Branch was safely pushed!
            self.assertTrue(_git(origin, "rev-parse", "refs/heads/audio/voz-5555"))

    def test_unexpected_gh_error_exits_nonzero(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            _, work = self._setup_clone_with_origin(base)
            fake_bin = base / "bin"
            self._install_fake_gh(
                fake_bin,
                'echo "HTTP 502 Bad Gateway" >&2\nexit 1\n',
            )
            _write_file(work / "historia" / "audio" / "clip2.mp3", "audio")
            res = self._run_voz_script(
                work,
                ["--branch", "audio/voz-6666"],
                extra_env={"PATH": f"{fake_bin}:{os.environ['PATH']}"},
            )
            self.assertNotEqual(res.returncode, 0)
            self.assertIn("HTTP 502", res.stderr)

    def test_dry_run_and_main_branch_guard(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            origin, work = self._setup_clone_with_origin(Path(tmp))
            _write_file(work / "historia" / "audio" / "clip3.mp3", "audio")

            # Refuses pushing to main
            res_main = self._run_voz_script(work, ["--branch", "main"])
            self.assertEqual(res_main.returncode, 1)
            self.assertIn("protected/base branch", res_main.stderr)

            # Dry run does not commit or push
            res_dry = self._run_voz_script(work, ["--branch", "audio/voz-dry", "--dry-run"])
            self.assertEqual(res_dry.returncode, 0, res_dry.stderr)
            self.assertIn("dry-run:", res_dry.stdout)
            self.assertEqual(_git(work, "rev-parse", "--abbrev-ref", "HEAD"), "main")
            self.assertEqual(_git(origin, "branch", "--list"), "* main")

    def test_default_branch_name_includes_run_attempt_when_set(self) -> None:
        self.assertEqual(
            voz_pr.default_branch_name("12345", "1"),
            "audio/voz-12345-a1",
        )
        self.assertEqual(
            voz_pr.default_branch_name("12345", "2"),
            "audio/voz-12345-a2",
        )
        self.assertEqual(
            voz_pr.default_branch_name("12345", ""),
            "audio/voz-12345",
        )
        self.assertRegex(
            voz_pr.default_branch_name("", ""),
            r"^audio/voz-\d{8}T\d{6}Z$",
        )

        # End-to-end CLI check using GITHUB_RUN_ID + GITHUB_RUN_ATTEMPT env vars
        with tempfile.TemporaryDirectory() as tmp:
            _, work = self._setup_clone_with_origin(Path(tmp))
            _write_file(work / "historia" / "audio" / "clip4.mp3", "audio")
            res = self._run_voz_script(
                work,
                ["--dry-run"],
                extra_env={"GITHUB_RUN_ID": "98765", "GITHUB_RUN_ATTEMPT": "2"},
            )
            self.assertEqual(res.returncode, 0, res.stderr)
            self.assertIn("audio/voz-98765-a2", res.stdout)


class WorkflowStaticValidationTests(unittest.TestCase):
    USES_RE = re.compile(r"^\s*-?\s*uses:\s*([^\s#]+)", re.M)
    PINNED_SHA_RE = re.compile(r"^[^@]+@[0-9a-f]{40}$")

    def _assert_all_actions_pinned(self, workflow_text: str, name: str) -> None:
        uses = self.USES_RE.findall(workflow_text)
        self.assertTrue(uses, f"{name} should reference at least one action")
        for ref in uses:
            with self.subTest(workflow=name, uses=ref):
                self.assertRegex(ref, self.PINNED_SHA_RE)

    def test_coqui_sitio_workflow_contract(self) -> None:
        wf_path = REPO_ROOT / ".github" / "workflows" / "coqui-sitio.yml"
        text = wf_path.read_text(encoding="utf-8")
        self._assert_all_actions_pinned(text, "coqui-sitio.yml")

        # Never pushes to main or requests contents: write
        self.assertNotIn("git push", text)
        self.assertNotRegex(
            text,
            re.compile(r"^\s*contents:\s*write\b", re.M),
            msg="coqui-sitio must not request contents: write",
        )

        # Required least-privilege permissions + Pages deployment
        for perm in (
            r"^\s*contents:\s*read\b",
            r"^\s*actions:\s*read\b",
            r"^\s*checks:\s*read\b",
            r"^\s*deployments:\s*read\b",
            r"^\s*pages:\s*write\b",
            r"^\s*id-token:\s*write\b",
        ):
            self.assertRegex(text, re.compile(perm, re.M))

        self.assertRegex(text, re.compile(r"^\s*name:\s*github-pages\b", re.M))
        self.assertIn("python3 .github/scripts/sitio_publish_gate.py", text)
        self.assertIn("python3 .github/scripts/stage_pages_site.py", text)
        self.assertIn("actions/configure-pages@", text)
        self.assertIn("actions/upload-pages-artifact@", text)
        self.assertIn("actions/deploy-pages@", text)

    def test_voz_workflow_contract_and_dry_voz_compatibility(self) -> None:
        wf_path = REPO_ROOT / ".github" / "workflows" / "voz.yml"
        text = wf_path.read_text(encoding="utf-8")
        self._assert_all_actions_pinned(text, "voz.yml")

        # No inline git push in workflow YAML; delegates to voz_publish_pr.py
        self.assertNotIn("git push", text)
        self.assertIn("python3 .github/scripts/voz_publish_pr.py", text)
        self.assertIn("GITHUB_RUN_ATTEMPT: ${{ github.run_attempt }}", text)

        # Required permissions, concurrency, and paid-audio environment
        self.assertRegex(text, re.compile(r"^\s*contents:\s*write\b", re.M))
        self.assertRegex(text, re.compile(r"^\s*pull-requests:\s*write\b", re.M))
        self.assertRegex(text, re.compile(r"^\s*concurrency:\s*voz\b", re.M))
        self.assertRegex(text, re.compile(r"^\s*environment:\s*paid-audio\b", re.M))

        # Exact env lines parsed by coqui/tool/dry_voz.py
        for key in ("MODO", "V_NARR", "V_ABUELA", "V_TU", "RATE"):
            with self.subTest(dry_voz_key=key):
                matched = re.search(
                    r"^\s*" + key + r":\s*\$\{\{\s*inputs\.\w+(?:\s*\|\|\s*'[^']*')?\s*\}\}",
                    text,
                    re.M,
                )
                self.assertIsNotNone(matched, f"dry_voz.py expects {key} in voz.yml")


if __name__ == "__main__":
    unittest.main()
