#!/usr/bin/env python3
"""Run GoShipKit verification commands selected from changed repository paths."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote


SCOPES = ("docs", "server", "web", "desktop", "mobile", "compose", "all")
LINK_PATTERN = re.compile(r"\[[^\]]+\]\(([^)]+)\)")


def run(
    command: list[str],
    cwd: Path,
    environment_overrides: dict[str, str] | None = None,
) -> None:
    executable = command[0]
    resolved = shutil.which(executable)
    if resolved is None:
        raise RuntimeError(f"required command is not installed: {executable}")
    print(f"\n> ({cwd}) {' '.join(command)}", flush=True)
    invocation = command
    if os.name == "nt" and Path(resolved).suffix.lower() in {".bat", ".cmd"}:
        invocation = [
            os.environ.get("COMSPEC", "cmd.exe"),
            "/d",
            "/s",
            "/c",
            subprocess.list2cmdline([resolved, *command[1:]]),
        ]
    environment = os.environ.copy()
    environment.update(environment_overrides or {})
    if executable == "flutter":
        flutter_root = Path(resolved).resolve().parent.parent.as_posix()
        git_config_count = int(environment.get("GIT_CONFIG_COUNT", "0"))
        environment[f"GIT_CONFIG_KEY_{git_config_count}"] = "safe.directory"
        environment[f"GIT_CONFIG_VALUE_{git_config_count}"] = flutter_root
        environment["GIT_CONFIG_COUNT"] = str(git_config_count + 1)
    subprocess.run(invocation, cwd=cwd, check=True, env=environment)


def output(command: list[str], cwd: Path) -> list[str]:
    result = subprocess.run(
        command,
        cwd=cwd,
        check=True,
        capture_output=True,
        text=True,
    )
    return [line.strip().replace("\\", "/") for line in result.stdout.splitlines() if line.strip()]


def changed_paths(root: Path) -> list[str]:
    changed = output(["git", "diff", "--name-only", "HEAD"], root)
    untracked = output(["git", "ls-files", "--others", "--exclude-standard"], root)
    return sorted(set(changed + untracked))


def classify(paths: list[str]) -> set[str]:
    scopes: set[str] = set()
    for path in paths:
        if path.startswith("server/"):
            scopes.add("server")
            if path.startswith("server/migrations/"):
                scopes.add("compose")
        elif path.startswith("apps/mobile/"):
            scopes.add("mobile")
        elif path.startswith("apps/desktop/"):
            scopes.update(("desktop", "web"))
        elif path.startswith("apps/web/") or path.startswith("packages/"):
            scopes.add("web")
        elif path.startswith("deploy/") or path in {"compose.yml", ".env.example"}:
            scopes.add("compose")
        elif path == "go.work":
            scopes.update(("server", "desktop"))
        elif (
            path.startswith("docs/")
            or path.startswith(".agents/")
            or path.endswith(".md")
        ):
            scopes.add("docs")
        elif path in {"package.json", "pnpm-lock.yaml", "pnpm-workspace.yaml"}:
            scopes.add("web")
        else:
            scopes.update(("docs", "server", "web", "desktop", "mobile", "compose"))
    return scopes


def verify_markdown_links(root: Path) -> None:
    broken: list[str] = []
    for markdown in root.rglob("*.md"):
        if any(part in {".git", "node_modules"} for part in markdown.parts):
            continue
        content = markdown.read_text(encoding="utf-8")
        for match in LINK_PATTERN.finditer(content):
            raw_target = match.group(1).strip().strip("<>")
            if raw_target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            target = unquote(raw_target.split("#", 1)[0])
            if not target or "${" in target:
                continue
            if not (markdown.parent / target).resolve().exists():
                broken.append(f"{markdown.relative_to(root)} -> {target}")
    if broken:
        raise RuntimeError("broken local Markdown links:\n" + "\n".join(broken))
    print("Markdown local links: OK")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--scope",
        action="append",
        choices=SCOPES,
        help="verification scope; repeat for multiple scopes (default: infer from worktree)",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = Path(
        subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
    )

    paths = changed_paths(root)
    scopes = set(args.scope or classify(paths))
    if "all" in scopes:
        scopes = {"docs", "server", "web", "desktop", "mobile", "compose"}
    if not scopes:
        raise RuntimeError("no changed paths detected; pass --scope explicitly")

    print("Changed paths:")
    for path in paths or ["(clean worktree; explicit scope)"]:
        print(f"- {path}")
    print("Scopes: " + ", ".join(sorted(scopes)))

    run(["git", "diff", "--check"], root)
    if "docs" in scopes:
        verify_markdown_links(root)
    if "server" in scopes:
        run(["go", "vet", "./..."], root / "server")
        run(["go", "test", "./..."], root / "server")
    if "web" in scopes:
        run(["corepack", "pnpm", "typecheck"], root)
        run(["corepack", "pnpm", "build"], root)
    if "desktop" in scopes:
        run(["go", "test", "./..."], root / "apps" / "desktop")
    if "mobile" in scopes:
        run(["flutter", "analyze"], root / "apps" / "mobile")
        run(["flutter", "test"], root / "apps" / "mobile")
    if "compose" in scopes:
        compose_environment: dict[str, str] = {}
        if not os.environ.get("POSTGRES_PASSWORD"):
            print("Compose validation: using an ephemeral placeholder password.")
            compose_environment["POSTGRES_PASSWORD"] = "goshipkit-verification-only"
        run(
            ["docker", "compose", "config", "--quiet"],
            root,
            compose_environment,
        )

    print("\nSelected GoShipKit verification passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"\nVerification failed: {error}", file=sys.stderr)
        raise SystemExit(1)
