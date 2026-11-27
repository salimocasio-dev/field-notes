#!/usr/bin/env python3
"""Unit and integration tests for `coqui/tool/plan_tests.py` and `coqui/tool/test_all.sh`.

Stdlib-only Python 3.12 (`unittest`).
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

TOOL_DIR = Path(__file__).resolve().parents[1]
COQUI_DIR = TOOL_DIR.parent
REPO_ROOT = COQUI_DIR.parent
sys.path.insert(0, str(TOOL_DIR))

import plan_tests  # noqa: E402


def _write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def _clean_env(extra: dict[str, str] | None = None) -> dict[str, str]:
    env = os.environ.copy()
    for key in ("COQUI_FULL_SUITE", "COQUI_CHANGED_PATHS_FILE", "COQUI_CI_EVENT"):
        env.pop(key, None)
    if extra:
        env.update(extra)
    return env


class SyntheticWorkspaceTests(unittest.TestCase):
    def _create_workspace(
        self,
        root: Path,
        *,
        scenes_depends_on_ui: bool = True,
    ) -> Path:
        coqui = root / "coqui"
        _write(
            coqui / "pubspec.yaml",
            """
name: synth_workspace
# comment line
workspace:
  - app
  - packages/core/coqui_contracts # inline comment
  - 'packages/core/coqui_ui'
  - "packages/core/coqui_scenes"
  - packages/core/coqui_testing
  - packages/features/feature_alpha
  - packages/features/feature_beta
  - packages/no_tests_pkg
""",
        )
        _write(
            coqui / "app" / "pubspec.yaml",
            """
name: app
environment:
  sdk: ^3.14.0
  flutter: 3.50.0
dependencies:
  flutter:
    sdk: flutter
  coqui_contracts: any
  coqui_ui: any
  feature_alpha: any
  feature_beta: any
dev_dependencies:
  coqui_testing: any
  flutter_test:
    sdk: flutter
""",
        )
        (coqui / "app" / "test").mkdir(parents=True, exist_ok=True)

        _write(
            coqui / "packages/core/coqui_contracts/pubspec.yaml",
            """
name: coqui_contracts
environment:
  sdk: ^3.14.0
dependencies:
  collection: ^1.19.1
""",
        )
        (coqui / "packages/core/coqui_contracts/test").mkdir(parents=True, exist_ok=True)

        _write(
            coqui / "packages/core/coqui_ui/pubspec.yaml",
            """
name: "coqui_ui"
environment:
  sdk: ^3.14.0
dependencies:
  flutter:
    sdk: flutter # flutter sdk
  coqui_contracts: any
""",
        )
        (coqui / "packages/core/coqui_ui/test").mkdir(parents=True, exist_ok=True)

        scenes_ui_line = "  coqui_ui: any\n" if scenes_depends_on_ui else ""
        _write(
            coqui / "packages/core/coqui_scenes/pubspec.yaml",
            f"""
name: coqui_scenes
environment:
  sdk: ^3.14.0
  flutter: 3.50.0
dependencies:
  flutter:
    sdk: flutter
  coqui_contracts: any
{scenes_ui_line}dev_dependencies:
  coqui_testing: any
""",
        )
        (coqui / "packages/core/coqui_scenes/test").mkdir(parents=True, exist_ok=True)

        _write(
            coqui / "packages/core/coqui_testing/pubspec.yaml",
            """
name: coqui_testing
environment:
  sdk: ^3.14.0
dependencies:
  coqui_contracts: any
""",
        )
        (coqui / "packages/core/coqui_testing/test").mkdir(parents=True, exist_ok=True)

        _write(
            coqui / "packages/features/feature_alpha/pubspec.yaml",
            """
name: feature_alpha
environment:
  sdk: ^3.14.0
dependencies:
  coqui_ui: any
  coqui_scenes: any
dev_dependencies:
  coqui_testing: any
""",
        )
        (coqui / "packages/features/feature_alpha/test").mkdir(parents=True, exist_ok=True)

        _write(
            coqui / "packages/features/feature_beta/pubspec.yaml",
            """
name: feature_beta
environment:
  sdk: ^3.14.0
dependencies:
  coqui_contracts: any
""",
        )
        (coqui / "packages/features/feature_beta/test").mkdir(parents=True, exist_ok=True)

        _write(
            coqui / "packages/no_tests_pkg/pubspec.yaml",
            """
name: no_tests_pkg
environment:
  sdk: ^3.14.0
dependencies:
  coqui_ui: any
""",
        )
        return coqui

    def test_dynamic_pubspec_parsing_and_reverse_graph_reacts_to_edge_removal(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            coqui = self._create_workspace(Path(tmp), scenes_depends_on_ui=True)
            pkgs = plan_tests.discover_workspace_packages(coqui)
            by_name = {p.name: p for p in pkgs}

            self.assertEqual(
                [p.name for p in pkgs],
                [
                    "app",
                    "coqui_contracts",
                    "coqui_ui",
                    "coqui_scenes",
                    "coqui_testing",
                    "feature_alpha",
                    "feature_beta",
                    "no_tests_pkg",
                ],
            )
            self.assertTrue(by_name["app"].is_flutter)
            self.assertTrue(by_name["coqui_ui"].is_flutter)
            self.assertFalse(by_name["coqui_contracts"].is_flutter)
            self.assertFalse(by_name["coqui_testing"].is_flutter)
            self.assertFalse(by_name["no_tests_pkg"].has_test_dir)
            self.assertIn("coqui_testing", by_name["coqui_scenes"].dev_dependencies)

            # With coqui_scenes -> coqui_ui edge present: coqui_ui change selects coqui_scenes
            plan_with_edge = plan_tests.plan_from_paths(
                coqui, ["coqui/packages/core/coqui_ui/lib/a.dart"]
            )
            self.assertEqual(plan_with_edge.mode, "selective")
            self.assertEqual(
                [p.name for p in plan_with_edge.packages_to_test],
                ["app", "coqui_ui", "coqui_scenes", "feature_alpha"],
            )

            # Remove edge coqui_scenes -> coqui_ui in pubspec.yaml; coqui_scenes must disappear!
            self._create_workspace(Path(tmp), scenes_depends_on_ui=False)
            plan_without_edge = plan_tests.plan_from_paths(
                coqui, ["coqui/packages/core/coqui_ui/lib/a.dart"]
            )
            self.assertEqual(plan_without_edge.mode, "selective")
            self.assertEqual(
                [p.name for p in plan_without_edge.packages_to_test],
                ["app", "coqui_ui", "feature_alpha"],
            )
            self.assertIn(
                "coqui_scenes",
                [s.name for s in plan_without_edge.skipped_packages],
            )

            # dev_dependencies edge: changing coqui_testing selects coqui_scenes, feature_alpha, app
            plan_dev = plan_tests.plan_from_paths(
                coqui, ["coqui/packages/core/coqui_testing/lib/fakes.dart"]
            )
            self.assertEqual(
                [p.name for p in plan_dev.packages_to_test],
                ["app", "coqui_scenes", "coqui_testing", "feature_alpha"],
            )

    def test_previa_asset_change_enables_previa_check(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            coqui = self._create_workspace(Path(tmp))
            plan = plan_tests.plan_from_paths(
                coqui, ["coqui/app/assets/previa/cuentos/la-lluvia.json"]
            )
            self.assertEqual(plan.mode, "selective")
            self.assertTrue(plan.run_dart_checks)
            self.assertTrue(plan.run_previa_check)
            self.assertFalse(plan.run_data_checks)
            self.assertEqual([p.name for p in plan.packages_to_test], ["app"])


class RealWorkspacePlanTests(unittest.TestCase):
    def test_feature_words_single_file_runs_only_feature_words_and_app(self) -> None:
        plan = plan_tests.plan_from_paths(
            COQUI_DIR,
            ["coqui/packages/features/feature_words/lib/src/wording.dart"],
        )
        self.assertEqual(plan.mode, "selective")
        self.assertTrue(plan.run_dart_checks)
        self.assertFalse(plan.run_boundaries_only)
        self.assertFalse(plan.run_tool_tests)
        self.assertFalse(plan.run_content_checks)
        self.assertFalse(plan.run_data_checks)
        self.assertFalse(plan.run_previa_check)
        self.assertFalse(plan.run_web_build)
        self.assertEqual(
            [p.name for p in plan.packages_to_test],
            ["app", "feature_words"],
        )
        skipped_names = {p.name for p in plan.skipped_packages}
        self.assertIn("coqui_scenes", skipped_names)
        self.assertIn("coqui_story_checks", skipped_names)
        self.assertIn("feature_story", skipped_names)
        self.assertNotIn("feature_words", skipped_names)
        self.assertNotIn("app", skipped_names)
        for sp in plan.skipped_packages:
            self.assertIn("feature_words", sp.reason)
        skipped_step_names = {s.step for s in plan.skipped_steps}
        self.assertIn("web_build", skipped_step_names)
        self.assertIn("tool_tests", skipped_step_names)

        human = plan_tests.format_human(plan)
        self.assertIn("Mode: selective", human)
        self.assertIn("Skipped packages", human)
        self.assertIn("coqui_scenes", human)
        self.assertIn("web_build", human)

    def test_coqui_pixel_dependents(self) -> None:
        plan = plan_tests.plan_from_paths(
            COQUI_DIR,
            ["coqui/packages/core/coqui_pixel/lib/coqui_pixel.dart"],
        )
        self.assertEqual(plan.mode, "selective")
        self.assertEqual(
            {p.name for p in plan.packages_to_test},
            {
                "coqui_pixel",
                "coqui_scenes",
                "feature_map",
                "feature_story",
                "coqui_story_checks",
                "app",
            },
        )

    def test_coqui_ui_dependents(self) -> None:
        plan = plan_tests.plan_from_paths(
            COQUI_DIR,
            ["coqui/packages/core/coqui_ui/lib/coqui_ui.dart"],
        )
        self.assertEqual(plan.mode, "selective")
        self.assertEqual(
            {p.name for p in plan.packages_to_test},
            {
                "coqui_ui",
                "coqui_testing",
                "coqui_scenes",
                "feature_map",
                "feature_story",
                "feature_review",
                "feature_words",
                "feature_library",
                "feature_speaking",
                "feature_profile",
                "coqui_story_checks",
                "app",
            },
        )

    def test_coqui_testing_dev_dependents(self) -> None:
        plan = plan_tests.plan_from_paths(
            COQUI_DIR,
            ["coqui/packages/core/coqui_testing/lib/coqui_testing.dart"],
        )
        self.assertEqual(plan.mode, "selective")
        selected = {p.name for p in plan.packages_to_test}
        self.assertIn("coqui_testing", selected)
        self.assertIn("coqui_scenes", selected)
        self.assertIn("feature_words", selected)
        self.assertIn("feature_story", selected)
        self.assertIn("coqui_story_checks", selected)
        self.assertIn("app", selected)
        self.assertNotIn("coqui_pixel", selected)
        self.assertNotIn("coqui_progress", selected)

    def test_feature_story_dependents(self) -> None:
        plan = plan_tests.plan_from_paths(
            COQUI_DIR,
            ["coqui/packages/features/feature_story/lib/feature_story.dart"],
        )
        self.assertEqual(plan.mode, "selective")
        self.assertEqual(
            {p.name for p in plan.packages_to_test},
            {"feature_story", "coqui_story_checks", "app"},
        )

    def test_ref_pp_maps_to_coqui_scenes(self) -> None:
        plan = plan_tests.plan_from_paths(
            COQUI_DIR,
            ["coqui/ref/pp/frente/set.json"],
        )
        self.assertEqual(plan.mode, "selective")
        self.assertEqual(
            {p.name for p in plan.packages_to_test},
            {"coqui_scenes", "feature_story", "coqui_story_checks", "app"},
        )

    def test_feature_words_plus_requests_and_docs_stays_selective(self) -> None:
        plan = plan_tests.plan_from_paths(
            COQUI_DIR,
            [
                "coqui/packages/features/feature_words/lib/src/wording.dart",
                "coqui/requests/999-test.md",
                "docs/readme.md",
            ],
        )
        self.assertEqual(plan.mode, "selective")
        self.assertEqual(
            [p.name for p in plan.packages_to_test],
            ["app", "feature_words"],
        )

    def test_content_only_skips_all_dart_packages_and_web_build(self) -> None:
        plan = plan_tests.plan_from_paths(
            COQUI_DIR,
            [
                "content/games/la-lluvia.json",
                "content/lines/es/la-lluvia.json",
            ],
        )
        self.assertEqual(plan.mode, "content_only")
        self.assertFalse(plan.run_dart_checks)
        self.assertFalse(plan.run_boundaries_only)
        self.assertFalse(plan.run_tool_tests)
        self.assertTrue(plan.run_content_checks)
        self.assertFalse(plan.run_data_checks)
        self.assertFalse(plan.run_previa_check)
        self.assertFalse(plan.run_web_build)
        self.assertEqual(plan.packages_to_test, ())
        self.assertGreaterEqual(len(plan.skipped_packages), 17)

    def test_historia_data_runs_coqui_content_and_data_checks(self) -> None:
        plan = plan_tests.plan_from_paths(
            COQUI_DIR,
            ["historia/datos/repaso.json"],
        )
        self.assertEqual(plan.mode, "selective")
        self.assertTrue(plan.run_dart_checks)
        self.assertTrue(plan.run_content_checks)
        self.assertTrue(plan.run_data_checks)
        self.assertEqual(
            {p.name for p in plan.packages_to_test},
            {"coqui_content", "app"},
        )

    def test_full_suite_triggers(self) -> None:
        trigger_paths = [
            "coqui/tool/test_all.sh",
            "coqui/pubspec.yaml",
            "coqui/pubspec.lock",
            "coqui/.flutter-version",
            "coqui/analysis_options.yaml",
            "coqui/BUILD",
            "coqui/packages/core/coqui_contracts/lib/coqui_contracts.dart",
            ".github/workflows/coqui.yml",
            ".github/scripts/coqui_ci_gate.sh",
            "coqui/ref/other/spec.txt",
            "coqui/extra.yaml",
        ]
        all_pkgs = plan_tests.discover_workspace_packages(COQUI_DIR)
        expected_count = sum(1 for p in all_pkgs if p.has_test_dir)
        for path in trigger_paths:
            with self.subTest(trigger=path):
                plan = plan_tests.plan_from_paths(COQUI_DIR, [path])
                self.assertEqual(plan.mode, "full")
                self.assertTrue(plan.run_dart_checks)
                self.assertTrue(plan.run_tool_tests)
                self.assertTrue(plan.run_content_checks)
                self.assertTrue(plan.run_data_checks)
                self.assertTrue(plan.run_web_build)
                self.assertEqual(len(plan.packages_to_test), expected_count)
                self.assertEqual(plan.skipped_packages, ())

        # Default (changed_paths=None) and force_full=True
        default_plan = plan_tests.plan_from_paths(COQUI_DIR, None)
        self.assertEqual(default_plan.mode, "full")
        self.assertTrue(default_plan.run_web_build)

        forced_plan = plan_tests.plan_from_paths(
            COQUI_DIR, ["docs/readme.md"], force_full=True
        )
        self.assertEqual(forced_plan.mode, "full")
        self.assertTrue(forced_plan.run_web_build)

    def test_meta_only_and_skip_modes(self) -> None:
        for meta_path in ("coqui/requests/r.md", "coqui/AGENTS.md"):
            with self.subTest(meta_path=meta_path):
                plan = plan_tests.plan_from_paths(COQUI_DIR, [meta_path])
                self.assertEqual(plan.mode, "meta_only")
                self.assertFalse(plan.run_dart_checks)
                self.assertTrue(plan.run_boundaries_only)
                self.assertFalse(plan.run_tool_tests)
                self.assertFalse(plan.run_content_checks)
                self.assertFalse(plan.run_data_checks)
                self.assertFalse(plan.run_web_build)
                self.assertEqual(plan.packages_to_test, ())

        for skip_paths in (["docs/readme.md"], []):
            with self.subTest(skip_paths=skip_paths):
                plan = plan_tests.plan_from_paths(COQUI_DIR, skip_paths)
                self.assertEqual(plan.mode, "skip")
                self.assertFalse(plan.run_dart_checks)
                self.assertFalse(plan.run_boundaries_only)
                self.assertFalse(plan.run_tool_tests)
                self.assertFalse(plan.run_content_checks)
                self.assertFalse(plan.run_data_checks)
                self.assertFalse(plan.run_web_build)
                self.assertEqual(plan.packages_to_test, ())

    def test_cli_changed_file_missing_and_empty(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            missing = Path(tmp) / "does_not_exist.txt"
            rc = plan_tests.main(["--changed-file", str(missing)])
            self.assertEqual(rc, 2)

            empty = Path(tmp) / "empty.txt"
            empty.write_text("", encoding="utf-8")
            proc = subprocess.run(
                [
                    sys.executable,
                    str(TOOL_DIR / "plan_tests.py"),
                    "--changed-file",
                    str(empty),
                    "--format",
                    "json",
                ],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(proc.returncode, 0, proc.stderr)
            data = json.loads(proc.stdout)
            self.assertEqual(data["mode"], "skip")


class TestAllShIntegrationTests(unittest.TestCase):
    def _run_test_all(
        self,
        args: list[str],
        *,
        cwd: Path = REPO_ROOT,
        extra_env: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash", str(TOOL_DIR / "test_all.sh"), *args],
            cwd=str(cwd),
            env=_clean_env(extra_env),
            capture_output=True,
            text=True,
            check=False,
        )

    def test_dry_run_flags_and_env_vars(self) -> None:
        # 1. --changed single feature
        res = self._run_test_all(
            [
                "--dry-run",
                "--changed",
                "coqui/packages/features/feature_words/lib/src/wording.dart",
            ]
        )
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertIn("Mode: selective", res.stdout)
        self.assertIn("feature_words (packages/features/feature_words", res.stdout)
        self.assertIn("app (app", res.stdout)
        self.assertIn("Packages to test (2):", res.stdout)

        # 2. --changed-file relative path resolved against caller cwd (repo root)
        with tempfile.TemporaryDirectory() as tmp:
            rel_file = Path(tmp) / "changed.txt"
            rel_file.write_text(
                "coqui/packages/features/feature_story/lib/feature_story.dart\n",
                encoding="utf-8",
            )
            rel_arg = os.path.relpath(rel_file, REPO_ROOT)
            res_file = self._run_test_all(["--dry-run", "--changed-file", rel_arg])
            self.assertEqual(res_file.returncode, 0, res_file.stderr)
            self.assertIn("Mode: selective", res_file.stdout)
            self.assertIn("Packages to test (3):", res_file.stdout)
            self.assertIn("coqui_story_checks", res_file.stdout)

            # 3. COQUI_CHANGED_PATHS_FILE env var
            res_env = self._run_test_all(
                ["--dry-run"],
                extra_env={"COQUI_CHANGED_PATHS_FILE": rel_arg},
            )
            self.assertEqual(res_env.returncode, 0, res_env.stderr)
            self.assertIn("Mode: selective", res_env.stdout)
            self.assertIn("Packages to test (3):", res_env.stdout)

            # 4. COQUI_FULL_SUITE=1 overrides COQUI_CHANGED_PATHS_FILE
            res_env_full = self._run_test_all(
                ["--dry-run"],
                extra_env={
                    "COQUI_FULL_SUITE": "1",
                    "COQUI_CHANGED_PATHS_FILE": rel_arg,
                },
            )
            self.assertEqual(res_env_full.returncode, 0, res_env_full.stderr)
            self.assertIn("Mode: full", res_env_full.stdout)

        # 5. --full and default (no args) both choose full mode
        res_full = self._run_test_all(["--dry-run", "--full"])
        self.assertEqual(res_full.returncode, 0, res_full.stderr)
        self.assertIn("Mode: full", res_full.stdout)

        res_default = self._run_test_all(["--dry-run"])
        self.assertEqual(res_default.returncode, 0, res_default.stderr)
        self.assertIn("Mode: full", res_default.stdout)

        # 6. Unknown option exits 2
        res_bad = self._run_test_all(["--not-a-real-flag"])
        self.assertEqual(res_bad.returncode, 2)

    def test_real_execution_content_only_runs_split_stories_and_skips_dart(self) -> None:
        res = self._run_test_all(
            ["--changed", "content/games/la-lluvia.json"],
            cwd=REPO_ROOT,
        )
        self.assertEqual(res.returncode, 0, f"stdout:\n{res.stdout}\nstderr:\n{res.stderr}")
        self.assertIn("Mode: content_only", res.stdout)
        self.assertIn("== content: split_stories.py", res.stdout)
        self.assertIn("== all planned checks passed (mode=content_only)", res.stdout)
        self.assertNotIn("== flutter analyze", res.stdout)
        self.assertNotIn("== flutter build web", res.stdout)


if __name__ == "__main__":
    unittest.main()
