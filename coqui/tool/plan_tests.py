#!/usr/bin/env python3
"""Plan selective or full Coquí CI checks from changed repo paths.

Dynamically parses `coqui/pubspec.yaml` and every workspace member's
`pubspec.yaml`, builds the reverse-dependency graph (covering both
`dependencies` and `dev_dependencies`), classifies changed repo-relative
paths, and outputs a structured execution plan (JSON or human-readable).

Stdlib-only Python 3.12 (no third-party YAML libraries required).
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import deque
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence


FULL_TRIGGER_EXACT_PATHS = frozenset(
    {
        "coqui/pubspec.yaml",
        "coqui/pubspec.lock",
        "coqui/.flutter-version",
        "coqui/analysis_options.yaml",
        "coqui/BUILD",
        ".github/workflows/coqui.yml",
        ".github/scripts/coqui_ci_gate.sh",
    }
)

HISTORIA_DATA_PREFIXES = (
    "historia/datos",
    "historia/cuentos",
    "historia/libros",
)


@dataclass(frozen=True)
class PackageInfo:
    name: str
    rel_dir: str
    dependencies: tuple[str, ...]
    dev_dependencies: tuple[str, ...]
    is_flutter: bool
    has_test_dir: bool

    def to_plan_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "rel_dir": self.rel_dir,
            "is_flutter": self.is_flutter,
        }


@dataclass(frozen=True)
class SkippedPackage:
    name: str
    rel_dir: str
    reason: str

    def to_dict(self) -> dict[str, str]:
        return {
            "name": self.name,
            "rel_dir": self.rel_dir,
            "reason": self.reason,
        }


@dataclass(frozen=True)
class SkippedStep:
    step: str
    reason: str

    def to_dict(self) -> dict[str, str]:
        return {
            "step": self.step,
            "reason": self.reason,
        }


@dataclass(frozen=True)
class TestPlan:
    mode: str
    reasons: tuple[str, ...]
    changed_packages: tuple[str, ...]
    full_triggers: tuple[str, ...]
    run_dart_checks: bool
    run_boundaries_only: bool
    run_tool_tests: bool
    run_content_checks: bool
    run_data_checks: bool
    run_previa_check: bool
    run_web_build: bool
    packages_to_test: tuple[PackageInfo, ...]
    skipped_packages: tuple[SkippedPackage, ...]
    skipped_steps: tuple[SkippedStep, ...]

    def to_dict(self) -> dict[str, Any]:
        return {
            "mode": self.mode,
            "reasons": list(self.reasons),
            "changed_packages": list(self.changed_packages),
            "full_triggers": list(self.full_triggers),
            "run_dart_checks": self.run_dart_checks,
            "run_boundaries_only": self.run_boundaries_only,
            "run_tool_tests": self.run_tool_tests,
            "run_content_checks": self.run_content_checks,
            "run_data_checks": self.run_data_checks,
            "run_previa_check": self.run_previa_check,
            "run_web_build": self.run_web_build,
            "packages_to_test": [p.to_plan_dict() for p in self.packages_to_test],
            "skipped_packages": [p.to_dict() for p in self.skipped_packages],
            "skipped_steps": [s.to_dict() for s in self.skipped_steps],
        }


def _strip_yaml_comment(line: str) -> str:
    """Strip an unquoted YAML `# ...` comment from a single line."""
    in_single = False
    in_double = False
    escaped = False
    for idx, ch in enumerate(line):
        if in_double:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_double = False
            continue
        if in_single:
            if ch == "'":
                in_single = False
            continue
        if ch == '"':
            in_double = True
        elif ch == "'":
            in_single = True
        elif ch == "#" and (idx == 0 or line[idx - 1].isspace()):
            return line[:idx]
    return line


def _unquote_yaml_scalar(value: str) -> str:
    """Unquote a simple YAML scalar value."""
    s = value.strip()
    if len(s) >= 2 and s[0] == '"' and s[-1] == '"':
        inner = s[1:-1]
        return inner.replace('\\"', '"').replace("\\\\", "\\")
    if len(s) >= 2 and s[0] == "'" and s[-1] == "'":
        return s[1:-1].replace("''", "'")
    return s


def _split_yaml_key_value(stripped: str) -> tuple[str, str] | None:
    """Split a YAML mapping entry `key: value` into `(key, value)`."""
    in_single = False
    in_double = False
    escaped = False
    for idx, ch in enumerate(stripped):
        if in_double:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_double = False
            continue
        if in_single:
            if ch == "'":
                in_single = False
            continue
        if ch == '"':
            in_double = True
        elif ch == "'":
            in_single = True
        elif ch == ":" and (idx + 1 == len(stripped) or stripped[idx + 1].isspace()):
            key = _unquote_yaml_scalar(stripped[:idx])
            val = stripped[idx + 1 :].strip()
            return key, val
    return None


def _normalize_rel_dir(raw: str) -> str:
    norm = raw.strip().replace("\\", "/")
    while norm.startswith("./"):
        norm = norm[2:]
    return norm.strip("/")


def normalize_repo_path(path: str) -> str:
    """Normalize a repo-relative path to POSIX format without leading `./` or `/`."""
    norm = path.replace("\\", "/").strip()
    while norm.startswith("./"):
        norm = norm[2:]
    return norm.lstrip("/").rstrip("/")


def _matches_prefix(path: str, prefix: str) -> bool:
    return path == prefix or path.startswith(prefix + "/")


def parse_workspace_members(pubspec_path: Path) -> list[str]:
    """Parse the `workspace:` list from `<coqui_dir>/pubspec.yaml`."""
    if not pubspec_path.is_file():
        raise ValueError(f"missing workspace pubspec: {pubspec_path}")

    members: list[str] = []
    in_workspace = False
    for raw_line in pubspec_path.read_text(encoding="utf-8").splitlines():
        cleaned = _strip_yaml_comment(raw_line).rstrip()
        if not cleaned.strip():
            continue
        indent = len(cleaned) - len(cleaned.lstrip(" "))
        stripped = cleaned.lstrip(" ")

        if indent == 0:
            kv = _split_yaml_key_value(stripped)
            if kv is not None and kv[0] == "workspace":
                in_workspace = True
                inline_val = kv[1].strip()
                if inline_val.startswith("[") and inline_val.endswith("]"):
                    inner = inline_val[1:-1].strip()
                    if inner:
                        for item in inner.split(","):
                            rel = _normalize_rel_dir(_unquote_yaml_scalar(item))
                            if rel:
                                members.append(rel)
                    in_workspace = False
            else:
                in_workspace = False
            continue

        if in_workspace and stripped.startswith("-"):
            rest = stripped[1:].strip()
            rel = _normalize_rel_dir(_unquote_yaml_scalar(rest))
            if rel:
                members.append(rel)

    if not members:
        raise ValueError(f"no workspace members found in {pubspec_path}")
    return members


def _inline_flow_mapping_has_flutter_sdk(val: str) -> bool:
    s = val.strip()
    if not (s.startswith("{") and s.endswith("}")):
        return False
    inner = s[1:-1]
    for part in inner.split(","):
        kv = _split_yaml_key_value(part.strip())
        if kv is not None and kv[0] == "sdk" and _unquote_yaml_scalar(kv[1]) == "flutter":
            return True
    return False


def parse_package_pubspec(coqui_dir: Path, rel_dir: str) -> PackageInfo:
    """Parse one workspace member's `pubspec.yaml`."""
    pubspec_path = coqui_dir / rel_dir / "pubspec.yaml"
    if not pubspec_path.is_file():
        raise ValueError(f"missing member pubspec: {pubspec_path}")

    name: str | None = None
    dependencies: list[str] = []
    dev_dependencies: list[str] = []
    has_env_flutter = False
    has_dep_flutter_sdk = False

    section: str | None = None
    section_child_indent: int | None = None
    current_dep_section: str | None = None

    for raw_line in pubspec_path.read_text(encoding="utf-8").splitlines():
        cleaned = _strip_yaml_comment(raw_line).rstrip()
        if not cleaned.strip():
            continue
        indent = len(cleaned) - len(cleaned.lstrip(" "))
        stripped = cleaned.lstrip(" ")

        if indent == 0:
            section = None
            section_child_indent = None
            current_dep_section = None
            kv = _split_yaml_key_value(stripped)
            if kv is None:
                continue
            key, val = kv
            if key == "name":
                name = _unquote_yaml_scalar(val)
            elif key in {"environment", "dependencies", "dev_dependencies"}:
                if val.strip() in {"", "|", ">"}:
                    section = key
                elif val.strip().startswith("{") and val.strip().endswith("}"):
                    # Inline mapping like `dependencies: {}`
                    inner = val.strip()[1:-1].strip()
                    if inner:
                        for part in inner.split(","):
                            sub_kv = _split_yaml_key_value(part.strip())
                            if sub_kv is None:
                                continue
                            sub_k, sub_v = sub_kv
                            if key == "environment" and sub_k == "flutter":
                                has_env_flutter = True
                            elif key == "dependencies":
                                dependencies.append(sub_k)
                                if _inline_flow_mapping_has_flutter_sdk(sub_v):
                                    has_dep_flutter_sdk = True
                            elif key == "dev_dependencies":
                                dev_dependencies.append(sub_k)
            continue

        if section is None:
            continue

        # Ignore sequence items under unexpected sections
        if stripped.startswith("-"):
            continue

        if section_child_indent is None:
            section_child_indent = indent

        if indent == section_child_indent:
            kv = _split_yaml_key_value(stripped)
            if kv is None:
                continue
            key, val = kv
            if section == "environment":
                if key == "flutter":
                    has_env_flutter = True
            elif section == "dependencies":
                dependencies.append(key)
                current_dep_section = "dependencies"
                if _inline_flow_mapping_has_flutter_sdk(val):
                    has_dep_flutter_sdk = True
            elif section == "dev_dependencies":
                dev_dependencies.append(key)
                current_dep_section = "dev_dependencies"
                if _inline_flow_mapping_has_flutter_sdk(val):
                    has_dep_flutter_sdk = True
        elif indent > section_child_indent:
            # Nested mapping under a dependency entry (e.g. `sdk: flutter`)
            if current_dep_section in {"dependencies", "dev_dependencies"}:
                kv = _split_yaml_key_value(stripped)
                if kv is not None and kv[0] == "sdk" and _unquote_yaml_scalar(kv[1]) == "flutter":
                    has_dep_flutter_sdk = True

    if not name:
        raise ValueError(f"pubspec missing top-level `name:`: {pubspec_path}")

    return PackageInfo(
        name=name,
        rel_dir=rel_dir,
        dependencies=tuple(dependencies),
        dev_dependencies=tuple(dev_dependencies),
        is_flutter=has_dep_flutter_sdk or has_env_flutter,
        has_test_dir=(coqui_dir / rel_dir / "test").is_dir(),
    )


def discover_workspace_packages(coqui_dir: Path) -> tuple[PackageInfo, ...]:
    """Discover all workspace packages in declaration order."""
    member_dirs = parse_workspace_members(coqui_dir / "pubspec.yaml")
    return tuple(parse_package_pubspec(coqui_dir, rel_dir) for rel_dir in member_dirs)


def build_reverse_dependency_graph(
    packages: Sequence[PackageInfo],
) -> dict[str, set[str]]:
    """Build `rev_deps[dep_name] -> set[dependent_name]` across workspace members."""
    workspace_names = {pkg.name for pkg in packages}
    rev_deps: dict[str, set[str]] = {pkg.name: set() for pkg in packages}
    for pkg in packages:
        for dep in (*pkg.dependencies, *pkg.dev_dependencies):
            if dep in workspace_names and dep != pkg.name:
                rev_deps[dep].add(pkg.name)
    return rev_deps


def transitive_dependents(
    packages: Sequence[PackageInfo],
    rev_deps: Mapping[str, set[str]],
    seed_names: Iterable[str],
) -> list[str]:
    """BFS over `rev_deps` returning all reachable workspace packages in workspace order."""
    workspace_names = {pkg.name for pkg in packages}
    visited: set[str] = set()
    queue: deque[str] = deque()
    for seed in seed_names:
        if seed in workspace_names and seed not in visited:
            visited.add(seed)
            queue.append(seed)

    while queue:
        current = queue.popleft()
        for dependent in sorted(rev_deps.get(current, ())):
            if dependent not in visited:
                visited.add(dependent)
                queue.append(dependent)

    return [pkg.name for pkg in packages if pkg.name in visited]


def find_app_shell_package(packages: Sequence[PackageInfo]) -> PackageInfo | None:
    """Dynamically locate the app shell workspace package."""
    for pkg in packages:
        if pkg.rel_dir == "app":
            return pkg
    for pkg in packages:
        if pkg.name == "app":
            return pkg
    return None


def _full_plan(
    packages: Sequence[PackageInfo],
    *,
    reasons: Sequence[str],
    changed_packages: Sequence[str] = (),
    full_triggers: Sequence[str] = (),
) -> TestPlan:
    return TestPlan(
        mode="full",
        reasons=tuple(reasons),
        changed_packages=tuple(changed_packages),
        full_triggers=tuple(full_triggers),
        run_dart_checks=True,
        run_boundaries_only=False,
        run_tool_tests=True,
        run_content_checks=True,
        run_data_checks=True,
        run_previa_check=False,
        run_web_build=True,
        packages_to_test=tuple(p for p in packages if p.has_test_dir),
        skipped_packages=(),
        skipped_steps=(),
    )


def plan_from_paths(
    coqui_dir: Path,
    changed_paths: Iterable[str] | None,
    *,
    force_full: bool = False,
) -> TestPlan:
    """Compute the Coquí test execution plan for `changed_paths`."""
    packages = discover_workspace_packages(coqui_dir)
    rev_deps = build_reverse_dependency_graph(packages)
    app_pkg = find_app_shell_package(packages)
    testable_packages = [p for p in packages if p.has_test_dir]

    if force_full or changed_paths is None:
        return _full_plan(
            packages,
            reasons=("full suite requested (default or push to main)",),
        )

    members_longest_first = sorted(
        packages,
        key=lambda p: len(p.rel_dir),
        reverse=True,
    )
    scenes_pkg = next((p for p in packages if p.name == "coqui_scenes"), None)
    pixel_pkg = next((p for p in packages if p.name == "coqui_pixel"), None)

    full_triggers: list[str] = []
    full_triggers_seen: set[str] = set()
    changed_packages_set: set[str] = set()
    has_previa_changes = False
    has_content_changes = False
    has_historia_data_changes = False
    has_coqui_meta_changes = False

    def add_full_trigger(path: str) -> None:
        if path not in full_triggers_seen:
            full_triggers_seen.add(path)
            full_triggers.append(path)

    for raw in changed_paths:
        stripped_raw = raw.strip()
        if not stripped_raw:
            continue
        # Fail-safe: git `core.quotepath=true` emits C-quoted paths for non-ASCII
        # names. Never let an undecoded quoted path fall through to `skip`.
        if stripped_raw.startswith('"'):
            add_full_trigger(stripped_raw)
            continue

        p = normalize_repo_path(stripped_raw)
        if not p:
            continue

        # 1. Explicit full-suite triggers
        if (
            _matches_prefix(p, "coqui/tool")
            or p in FULL_TRIGGER_EXACT_PATHS
            or (
                _matches_prefix(p, "coqui/ref")
                and not _matches_prefix(p, "coqui/ref/pp")
            )
        ):
            add_full_trigger(p)
            continue

        # 2. Workspace member paths (longest prefix match first)
        matched_member: PackageInfo | None = None
        for member in members_longest_first:
            if _matches_prefix(p, f"coqui/{member.rel_dir}"):
                matched_member = member
                break
        if matched_member is not None:
            if matched_member.name == "coqui_contracts":
                add_full_trigger(p)
            else:
                changed_packages_set.add(matched_member.name)
                if _matches_prefix(p, "coqui/app/assets/previa"):
                    has_previa_changes = True
            continue

        # 3. Scene & pixel-engine reference paths (`coqui/ref/pp/*`)
        if _matches_prefix(p, "coqui/ref/pp"):
            seeded = False
            if pixel_pkg is not None:
                changed_packages_set.add(pixel_pkg.name)
                seeded = True
            if scenes_pkg is not None:
                changed_packages_set.add(scenes_pkg.name)
                seeded = True
            if not seeded:
                add_full_trigger(p)
            continue

        # 4. Coquí metadata paths
        if _matches_prefix(p, "coqui/requests") or p == "coqui/AGENTS.md":
            has_coqui_meta_changes = True
            continue

        # 5. Fail-safe: any other path under `coqui/` or equal to `coqui`
        if _matches_prefix(p, "coqui"):
            add_full_trigger(p)
            continue

        # 6. Content paths
        if _matches_prefix(p, "content"):
            has_content_changes = True
            continue

        # 7. Historia data paths (also exercised by coqui_content's real_tree_test.dart)
        if any(_matches_prefix(p, prefix) for prefix in HISTORIA_DATA_PREFIXES):
            has_historia_data_changes = True
            content_pkg = next((m for m in packages if m.name == "coqui_content"), None)
            if content_pkg is not None:
                changed_packages_set.add(content_pkg.name)
            continue

        # 8. Other repo paths (docs/*, README.md, AGENTS.md, other .github/*): ignored

    changed_packages = [p.name for p in packages if p.name in changed_packages_set]

    if full_triggers:
        shown = ", ".join(full_triggers[:5])
        if len(full_triggers) > 5:
            shown += f", ... (+{len(full_triggers) - 5} more)"
        return _full_plan(
            packages,
            reasons=(f"full-suite trigger path(s) changed: {shown}",),
            changed_packages=changed_packages,
            full_triggers=full_triggers,
        )

    if changed_packages:
        selected_names = set(transitive_dependents(packages, rev_deps, changed_packages))
        if app_pkg is not None:
            selected_names.add(app_pkg.name)

        packages_to_test = tuple(p for p in testable_packages if p.name in selected_names)
        changed_label = ", ".join(changed_packages)
        skip_pkg_reason = f"does not depend on changed package(s): {changed_label}"
        skipped_packages = tuple(
            SkippedPackage(name=p.name, rel_dir=p.rel_dir, reason=skip_pkg_reason)
            for p in testable_packages
            if p.name not in selected_names
        )

        run_content_checks = has_content_changes or has_historia_data_changes
        run_data_checks = has_historia_data_changes
        run_previa_check = has_previa_changes and not run_data_checks

        skipped_steps: list[SkippedStep] = [
            SkippedStep(step="tool_tests", reason="coqui/tool/ unchanged"),
        ]
        if not run_content_checks:
            skipped_steps.append(
                SkippedStep(
                    step="content_checks",
                    reason="no content/ or historia/ data changed",
                )
            )
        if not run_data_checks:
            skipped_steps.append(
                SkippedStep(
                    step="data_checks",
                    reason="no historia/ data changed",
                )
            )
        skipped_steps.append(
            SkippedStep(
                step="web_build",
                reason="selective PR run; full web build runs on push to main and full-suite triggers",
            )
        )

        reasons = [
            f"changed package(s): {changed_label}; running transitive dependents and app shell"
        ]
        if has_previa_changes and run_previa_check:
            reasons.append("coqui/app/assets/previa/ changed; running make_previa check")
        if has_historia_data_changes:
            reasons.append("historia/ data changed; running data and content checks")
        elif has_content_changes:
            reasons.append("content/ changed; running content checks")

        return TestPlan(
            mode="selective",
            reasons=tuple(reasons),
            changed_packages=tuple(changed_packages),
            full_triggers=(),
            run_dart_checks=True,
            run_boundaries_only=False,
            run_tool_tests=False,
            run_content_checks=run_content_checks,
            run_data_checks=run_data_checks,
            run_previa_check=run_previa_check,
            run_web_build=False,
            packages_to_test=packages_to_test,
            skipped_packages=skipped_packages,
            skipped_steps=tuple(skipped_steps),
        )

    if has_content_changes or has_historia_data_changes:
        run_data_checks = has_historia_data_changes
        run_boundaries_only = has_coqui_meta_changes
        dart_skip_reason = (
            "content + coqui metadata change; running boundary check only (no package suites)"
            if has_coqui_meta_changes
            else "content-only change; skipping Dart/Flutter checks"
        )
        skipped_steps = [
            SkippedStep(
                step="dart_checks",
                reason=dart_skip_reason,
            ),
            SkippedStep(
                step="tool_tests",
                reason="content-only change; skipping tool Dart tests",
            ),
        ]
        if not run_data_checks:
            skipped_steps.append(
                SkippedStep(
                    step="data_checks",
                    reason="content/-only change; skipping historia/ repaso & palabras-solas checks",
                )
            )
        skipped_steps.append(
            SkippedStep(
                step="web_build",
                reason="content-only change; skipping web build",
            )
        )
        skipped_packages = tuple(
            SkippedPackage(
                name=p.name,
                rel_dir=p.rel_dir,
                reason="content-only change; skipping Dart package suites",
            )
            for p in testable_packages
        )
        reasons = []
        if has_content_changes:
            reasons.append("content/ changed without Dart package changes")
        if has_historia_data_changes:
            reasons.append("historia/ data changed without Dart package changes")
        if has_coqui_meta_changes:
            reasons.append(
                "coqui metadata paths also changed (coqui/requests/ or coqui/AGENTS.md); running boundary check"
            )
        return TestPlan(
            mode="content_only",
            reasons=tuple(reasons),
            changed_packages=(),
            full_triggers=(),
            run_dart_checks=False,
            run_boundaries_only=run_boundaries_only,
            run_tool_tests=False,
            run_content_checks=True,
            run_data_checks=run_data_checks,
            run_previa_check=False,
            run_web_build=False,
            packages_to_test=(),
            skipped_packages=skipped_packages,
            skipped_steps=tuple(skipped_steps),
        )

    if has_coqui_meta_changes:
        skipped_steps = [
            SkippedStep(
                step="dart_checks",
                reason="coqui metadata-only change (coqui/requests/ or coqui/AGENTS.md); running boundary check only",
            ),
            SkippedStep(
                step="tool_tests",
                reason="coqui metadata-only change; skipping tool tests",
            ),
            SkippedStep(
                step="content_checks",
                reason="no content/ or historia/ data changed",
            ),
            SkippedStep(
                step="data_checks",
                reason="no historia/ data changed",
            ),
            SkippedStep(
                step="web_build",
                reason="coqui metadata-only change; skipping web build",
            ),
        ]
        skipped_packages = tuple(
            SkippedPackage(
                name=p.name,
                rel_dir=p.rel_dir,
                reason="coqui metadata-only change; skipping Dart package suites",
            )
            for p in testable_packages
        )
        return TestPlan(
            mode="meta_only",
            reasons=(
                "only coqui metadata paths changed (coqui/requests/ or coqui/AGENTS.md); running boundary check only",
            ),
            changed_packages=(),
            full_triggers=(),
            run_dart_checks=False,
            run_boundaries_only=True,
            run_tool_tests=False,
            run_content_checks=False,
            run_data_checks=False,
            run_previa_check=False,
            run_web_build=False,
            packages_to_test=(),
            skipped_packages=skipped_packages,
            skipped_steps=tuple(skipped_steps),
        )

    skip_reason = "no Coquí or content paths changed"
    skipped_steps = [
        SkippedStep(step="dart_checks", reason=skip_reason),
        SkippedStep(step="tool_tests", reason=skip_reason),
        SkippedStep(step="content_checks", reason=skip_reason),
        SkippedStep(step="data_checks", reason=skip_reason),
        SkippedStep(step="web_build", reason=skip_reason),
    ]
    skipped_packages = tuple(
        SkippedPackage(name=p.name, rel_dir=p.rel_dir, reason=skip_reason)
        for p in testable_packages
    )
    return TestPlan(
        mode="skip",
        reasons=(skip_reason,),
        changed_packages=(),
        full_triggers=(),
        run_dart_checks=False,
        run_boundaries_only=False,
        run_tool_tests=False,
        run_content_checks=False,
        run_data_checks=False,
        run_previa_check=False,
        run_web_build=False,
        packages_to_test=(),
        skipped_packages=skipped_packages,
        skipped_steps=tuple(skipped_steps),
    )


def format_human_dict(data: Mapping[str, Any]) -> str:
    """Format a serialized TestPlan dict into a clear human-readable report."""
    lines: list[str] = [
        "== Coquí test plan",
        f"Mode: {data['mode']}",
    ]
    reasons = data.get("reasons") or []
    if reasons:
        lines.append("Reason(s):")
        for reason in reasons:
            lines.append(f"  - {reason}")

    changed_pkgs = data.get("changed_packages") or []
    if changed_pkgs:
        lines.append(f"Changed package(s): {', '.join(changed_pkgs)}")

    full_triggers = data.get("full_triggers") or []
    if full_triggers:
        lines.append(f"Full-suite trigger(s): {', '.join(full_triggers)}")

    will_run_steps: list[str] = []
    if data.get("run_dart_checks"):
        will_run_steps.append(
            "dart_checks (pinned Flutter, pub get, make_scenes, check_boundaries, dart format, flutter analyze)"
        )
    elif data.get("run_boundaries_only"):
        will_run_steps.append("boundaries_only (pinned Flutter, check_boundaries)")
    if data.get("run_tool_tests"):
        will_run_steps.append("tool_tests (dart test tool/test, test_plan_tests.py)")
    if data.get("run_data_checks"):
        will_run_steps.append("data_checks (make_repaso, arrastra, make_palabras_solas, make_previa)")
    elif data.get("run_previa_check"):
        will_run_steps.append("previa_check (test_make_previa.py)")
    if data.get("run_content_checks"):
        will_run_steps.append("content_checks (test_split_stories.py, split_stories.py check)")
    if data.get("run_web_build"):
        will_run_steps.append("web_build (flutter build web --no-web-resources-cdn)")

    lines.append("Steps to run:")
    if will_run_steps:
        for step_desc in will_run_steps:
            lines.append(f"  - {step_desc}")
    else:
        lines.append("  - (none)")

    pkgs_to_test = data.get("packages_to_test") or []
    lines.append(f"Packages to test ({len(pkgs_to_test)}):")
    if pkgs_to_test:
        for pkg in pkgs_to_test:
            kind = "flutter" if pkg.get("is_flutter") else "dart vm+chrome"
            lines.append(f"  - {pkg['name']} ({pkg['rel_dir']}, {kind})")
    else:
        lines.append("  - (none)")

    skipped_steps = data.get("skipped_steps") or []
    lines.append(f"Skipped steps ({len(skipped_steps)}):")
    if skipped_steps:
        for item in skipped_steps:
            lines.append(f"  - {item['step']}: {item['reason']}")
    else:
        lines.append("  - (none)")

    skipped_pkgs = data.get("skipped_packages") or []
    lines.append(f"Skipped packages ({len(skipped_pkgs)}):")
    if skipped_pkgs:
        for item in skipped_pkgs:
            lines.append(f"  - {item['name']} ({item['rel_dir']}): {item['reason']}")
    else:
        lines.append("  - (none)")

    return "\n".join(lines)


def format_human(plan: TestPlan) -> str:
    return format_human_dict(plan.to_dict())


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    default_coqui_dir = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description="Plan selective or full Coquí CI checks from changed repo paths."
    )
    parser.add_argument(
        "--coqui-dir",
        type=Path,
        default=default_coqui_dir,
        help="Path to the coqui/ workspace directory (default: parent of tool/).",
    )
    parser.add_argument(
        "--full",
        action="store_true",
        help="Force the full check suite regardless of changed paths.",
    )
    parser.add_argument(
        "--changed",
        action="append",
        default=None,
        metavar="PATH",
        help="Changed repo-relative path (repeatable).",
    )
    parser.add_argument(
        "--changed-file",
        type=Path,
        default=None,
        metavar="FILE",
        help="File containing newline-separated changed repo-relative paths.",
    )
    parser.add_argument(
        "--format",
        choices=("json", "human"),
        default="json",
        help="Output format (default: json).",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)

    changed_paths: list[str] | None = None
    if args.changed_file is not None:
        if not args.changed_file.is_file():
            print(
                f"Error: --changed-file does not exist: {args.changed_file}",
                file=sys.stderr,
            )
            return 2
        changed_paths = args.changed_file.read_text(encoding="utf-8").splitlines()

    if args.changed is not None:
        if changed_paths is None:
            changed_paths = []
        changed_paths.extend(args.changed)

    try:
        plan = plan_from_paths(
            args.coqui_dir.resolve(),
            changed_paths,
            force_full=args.full,
        )
    except ValueError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    if args.format == "json":
        print(json.dumps(plan.to_dict(), indent=2, sort_keys=False))
    else:
        print(format_human(plan))
    return 0


if __name__ == "__main__":
    sys.exit(main())
