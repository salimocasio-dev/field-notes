#!/usr/bin/env python3
"""Stage the Coquí static site directory for GitHub Pages artifact upload.

Stdlib-only Python 3.12 script invoked by `.github/workflows/coqui-sitio.yml`.
Combines the repo root landing page, the freshly built Flutter web app, the
runtime `historia/` tree (excluding `historia/tools/` and `historia/notas/`),
and the lightweight `prueba/index.html` redirect into one clean directory.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import sys
from pathlib import Path

REQUIRED_STAGED_FILES = (
    "index.html",
    "app/index.html",
    "app/main.dart.js",
    "historia/datos/curso.json",
    "historia/audio/ready.json",
)

HISTORIA_TOP_EXCLUDES = frozenset({"tools", "notas"})
ANY_DEPTH_EXCLUDES = frozenset({"__pycache__", ".DS_Store"})


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        while True:
            chunk = fh.read(65536)
            if not chunk:
                break
            digest.update(chunk)
    return digest.hexdigest()


def compute_site_digest(out_dir: Path) -> tuple[str, int]:
    """Compute a deterministic SHA-256 over all files in `out_dir`."""
    files = sorted(
        (p for p in out_dir.rglob("*") if p.is_file()),
        key=lambda p: p.relative_to(out_dir).as_posix(),
    )
    outer = hashlib.sha256()
    for path in files:
        rel = path.relative_to(out_dir).as_posix()
        file_digest = _sha256_file(path)
        outer.update(rel.encode("utf-8"))
        outer.update(b"\0")
        outer.update(file_digest.encode("ascii"))
        outer.update(b"\n")
    return outer.hexdigest(), len(files)


def _is_same_or_parent(candidate: Path, target: Path) -> bool:
    try:
        target.relative_to(candidate)
        return True
    except ValueError:
        return False


def stage_site(
    *,
    repo_root: Path,
    app_dir: Path,
    out_dir: Path,
    clean: bool = False,
) -> tuple[str, int]:
    """Validate inputs, stage the Pages site into `out_dir`, and return `(sha256, file_count)`."""
    repo_root = repo_root.resolve()
    app_dir = app_dir.resolve()
    out_dir = out_dir.resolve()

    if _is_same_or_parent(out_dir, repo_root) or _is_same_or_parent(out_dir, app_dir):
        raise ValueError(
            f"refusing to use --out {out_dir}: overlaps with --repo-root or --app-dir"
        )

    root_index = repo_root / "index.html"
    historia_dir = repo_root / "historia"
    app_index = app_dir / "index.html"
    app_main_js = app_dir / "main.dart.js"

    if not root_index.is_file():
        raise ValueError(f"missing required repo file: {root_index}")
    if not historia_dir.is_dir():
        raise ValueError(f"missing required historia directory: {historia_dir}")
    if not app_index.is_file():
        raise ValueError(f"missing required built app file: {app_index}")
    if not app_main_js.is_file():
        raise ValueError(f"missing required built app file: {app_main_js}")

    if out_dir.exists():
        if out_dir.is_file() or out_dir.is_symlink():
            if not clean:
                raise ValueError(
                    f"output path {out_dir} exists; pass --clean to replace it"
                )
            out_dir.unlink()
        elif out_dir.is_dir():
            if any(out_dir.iterdir()):
                if not clean:
                    raise ValueError(
                        f"output directory {out_dir} is not empty; pass --clean to replace it"
                    )
                shutil.rmtree(out_dir)

    out_dir.mkdir(parents=True, exist_ok=True)

    # 1. Root landing page
    shutil.copy2(root_index, out_dir / "index.html")

    # 2. Built Flutter web app
    shutil.copytree(app_dir, out_dir / "app")

    # 3. Runtime historia/ tree (excluding top-level tools/ and notas/, plus cache/junk)
    historia_resolved = historia_dir.resolve()

    def _ignore_historia(directory: str, names: list[str]) -> set[str]:
        ignored = {name for name in names if name in ANY_DEPTH_EXCLUDES}
        if Path(directory).resolve() == historia_resolved:
            ignored.update(name for name in names if name in HISTORIA_TOP_EXCLUDES)
        return ignored

    shutil.copytree(historia_dir, out_dir / "historia", ignore=_ignore_historia)

    # 4. Lightweight /prueba/ -> ../app/ redirect only (no stale prueba binaries)
    prueba_index = repo_root / "prueba" / "index.html"
    if prueba_index.is_file():
        prueba_out = out_dir / "prueba"
        prueba_out.mkdir(parents=True, exist_ok=True)
        shutil.copy2(prueba_index, prueba_out / "index.html")

    # 5. Verify required runtime files are present in staged output
    missing = [
        rel for rel in REQUIRED_STAGED_FILES if not (out_dir / rel).is_file()
    ]
    if missing:
        raise ValueError(
            "staged Pages site is missing required runtime files: "
            + ", ".join(missing)
        )

    return compute_site_digest(out_dir)


def write_github_output(output_path: str, site_sha256: str, file_count: int) -> None:
    if not output_path:
        return
    with open(output_path, "a", encoding="utf-8") as fh:
        fh.write(f"site_sha256={site_sha256}\n")
        fh.write(f"file_count={file_count}\n")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    default_root = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(
        description="Stage the Coquí static site directory for GitHub Pages."
    )
    parser.add_argument("--repo-root", type=Path, default=default_root)
    parser.add_argument("--app-dir", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument(
        "--clean",
        action="store_true",
        default=False,
        help="Remove existing --out directory before staging.",
    )
    parser.add_argument(
        "--github-output", default=os.environ.get("GITHUB_OUTPUT", "")
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        site_sha256, file_count = stage_site(
            repo_root=args.repo_root,
            app_dir=args.app_dir,
            out_dir=args.out,
            clean=args.clean,
        )
    except (ValueError, OSError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    write_github_output(args.github_output, site_sha256, file_count)
    print(
        f"stage_pages_site: staged {file_count} files in {args.out} "
        f"(sha256={site_sha256})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
