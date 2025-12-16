#!/usr/bin/env python
"""Script for managing task versions and changelogs."""

# <TEMPLATED FILE!>
# This file comes from the templates at https://github.com/konflux-ci/task-repo-shared-ci.
# Please consider sending a PR upstream instead of editing the file directly.
# See the SHARED-CI.md document in this repo for more details.

from __future__ import annotations

import argparse
import functools
import os
import re
import subprocess
import sys
import textwrap
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Iterable, Iterator, Literal, Mapping, Self

SCRIPT_PATH = sys.argv[0]
VERSION_LABEL = "app.kubernetes.io/version"


# --- Utilities ---


class VersioningError(Exception):
    """Base type for versioning related errors."""


def run_cmd(cmd: list[str]) -> str:
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"{cmd[0]} failed ({cmd}):\n{textwrap.indent(proc.stderr, '  ')}")
    return proc.stdout


@dataclass
class TaskFile:
    """A task/{task_name}/**/{task_name}.yaml file."""

    path: Path

    @property
    def task_dir(self) -> Path:
        task_name = self.path.stem
        return Path("task") / task_name

    def read(self) -> TaskContent:
        return TaskContent(self.path.read_text())

    def read_at_base_ref(self, base_ref: str) -> TaskContent:
        content = run_cmd(["git", "show", f"{base_ref}:{self.path}"])
        return TaskContent(content)


def is_task_file(path: Path) -> bool:
    """Does the path match the task/{task_name}/**/{task_name}.yaml format?"""
    match path.parts:
        case ["task", task_dir, *_, task_file] if task_file.endswith(".yaml"):
            task_name = task_file.removesuffix(".yaml")
            return task_name == task_dir
        case _:
            return False


@dataclass
class TaskContent:
    """The YAML content of a task file. Processed as raw text to avoid dependencies."""

    content: str

    @property
    def version(self) -> str | None:
        version, _ = self._version_with_line_number
        return version

    @property
    def version_line(self) -> int | None:
        _, line_number = self._version_with_line_number
        return line_number

    def require_valid_version(self) -> Version:
        if not self.version:
            raise VersioningError(f"Missing {VERSION_LABEL} label")
        return Version.parse(self.version)

    @functools.cached_property
    def _version_with_line_number(self) -> tuple[str | None, int | None]:
        version_line_re = re.compile(
            rf"""^\s*["']?{re.escape(VERSION_LABEL)}["']?\s*:\s*["']?([^"'\s#]+)"""
        )
        for i, line in enumerate(self.content.splitlines(), start=1):
            if match := version_line_re.match(line):
                version = match.group(1)
                return version, i

        return None, None


class VersionParseError(VersioningError, ValueError):
    """Invalid version string."""


@dataclass(frozen=True)
@functools.total_ordering
class Version:
    """Represents x.y[.z] version numbers.

    Two main properties:
    - When comparing (ordering/equality), treats x.y as x.y.0
    - Preservers round-trip formatting: s == str(Version.parse(s))
    """

    major: int
    minor: int
    patch: int | None = None

    def __lt__(self, other: Self) -> bool:
        return self._tuple() < other._tuple()

    def __eq__(self, other: Any) -> bool:
        return isinstance(other, Version) and self._tuple() == other._tuple()

    def __hash__(self) -> int:
        return hash(self._tuple())

    def __str__(self) -> str:
        s = f"{self.major}.{self.minor}"
        if self.patch is not None:
            s += f".{self.patch}"
        return s

    @classmethod
    def parse(cls, version_str: str) -> Self:
        if not re.fullmatch(r"\d+\.\d+(\.\d+)?", version_str):
            raise VersionParseError(f"Invalid version: {version_str}")

        parts = map(int, version_str.split("."))
        return cls(*parts)

    def _tuple(self) -> tuple[int, ...]:
        return self.major, self.minor, self.patch or 0


FileStatus = Literal["added", "modified"]


@dataclass(frozen=True)
class ChangeSet:
    """Represents the relevant changes between current state and base ref."""

    _changes: Mapping[Path, FileStatus]

    @classmethod
    def for_base_ref(cls, base_ref: str) -> Self:
        # committed changes
        diff_output = run_cmd(["git", "diff", "--name-status", f"{base_ref}...HEAD"])
        # uncommitted changes (staged, unstaged, untracked)
        status_output = run_cmd(["git", "status", "--porcelain"])

        file_statuses: dict[Path, FileStatus] = {}

        for line in diff_output.splitlines() + status_output.splitlines():
            status, filepath, *_ = line.split()
            filepath = Path(filepath)

            if "A" in status or status == "??":
                # ?? == untracked, treat as added
                file_statuses[filepath] = "added"
            elif "M" in status:
                # The file may have been added in a commit and then modified in the working tree
                # and/or index. Want to treat this as added => added takes precedence over modified.
                file_statuses.setdefault(filepath, "modified")

        return cls(file_statuses)

    def status(self, path: Path) -> FileStatus | None:
        return self._changes.get(path)

    def did_change(self, path: Path) -> bool:
        return path in self._changes

    def get_task_files(self) -> list[TaskFile]:
        return [TaskFile(path) for path in self._changes if is_task_file(path)]


def list_task_files(paths: Iterable[Path]) -> list[TaskFile]:
    """List the task files found in or under 'paths'.

    - Pick the paths that are regular files and match the task file path pattern
    - Recursively search for task files in paths that are directories
    """
    task_paths = []
    for path in paths:
        if path.is_dir():
            task_paths.extend(filter(is_task_file, path.rglob("*.yaml")))
        elif is_task_file(path):
            task_paths.append(path)

    task_paths.sort()
    return [TaskFile(p) for p in task_paths]


ResultKind = Literal["info", "warning", "error"]


@dataclass(frozen=True)
class Result:
    kind: ResultKind
    message: str
    path: Path
    line: int | None = None

    def format_gh(self) -> str:
        kind = self.kind
        if kind == "info":
            kind = "notice"

        attrs = [f"file={self.path}"]
        if self.line is not None:
            attrs.append(f"line={self.line}")
        elif self.path.is_file():
            # Need this anyway to make the result appear in the changed files view in the GitHub UI
            attrs.append("line=1")

        return f"::{kind} {','.join(attrs)}::{self.message}"

    def format_plain(self, use_color: bool = True) -> str:
        if use_color:
            match self.kind:
                case "info":
                    color = "\033[1;37m"  # bold white
                case "warning":
                    color = "\033[1;33m"  # bold yellow
                case "error":
                    color = "\033[1;31m"  # bold red
            reset = "\033[0m"
        else:
            color = ""
            reset = ""

        attrs = [str(self.path)]
        if self.line is not None:
            attrs.append(str(self.line))

        return f"{color}{self.kind.title()}{reset}: {':'.join(attrs)}: {self.message}"


# --- CLI ---


def check(base_ref: str = "main", paths: list[Path] | None = None) -> Iterator[Result]:
    """Check versioning requirements for tasks in the changeset."""
    changeset = ChangeSet.for_base_ref(base_ref)
    if paths:
        task_files = list_task_files(paths)
    else:
        task_files = changeset.get_task_files()

    for task_file in task_files:
        status = changeset.status(task_file.path)
        if not status:
            yield Result(
                "info",
                f"File did not change between {base_ref} and HEAD, nothing to check",
                task_file.path,
            )
            continue

        task_content = task_file.read()
        result_kind: ResultKind = "warning" if status == "modified" else "error"

        try:
            task_content.require_valid_version()
        except VersioningError as e:
            yield Result(result_kind, str(e), task_file.path, task_content.version_line)

        changelog_path = task_file.task_dir / "CHANGELOG.md"
        changelog_exists = changelog_path.exists()
        if not changelog_exists:
            yield Result(
                result_kind,
                f"CHANGELOG.md missing at {changelog_path}. Use '{SCRIPT_PATH} new-changelog {task_file.task_dir}' to create one.",
                task_file.path,
            )

        # For modified tasks, also check that the version label and the CHANGELOG.md changed
        if status == "modified":
            has_version = task_content.version is not None
            if has_version and task_content.version == task_file.read_at_base_ref(base_ref).version:
                yield Result(
                    "warning",
                    f"{VERSION_LABEL} label is unchanged. CI pipeline may skip building the task.",
                    task_file.path,
                    task_content.version_line,
                )
            if changelog_exists and not changeset.did_change(changelog_path):
                yield Result(
                    "warning",
                    f"CHANGELOG.md at {changelog_path} is unchanged. Please consider updating it.",
                    task_file.path,
                )


def new_changelog(paths: list[Path]) -> Iterator[Result]:
    """Create CHANGELOG.md for tasks that don't have one."""
    task_dirs = {task_file.task_dir for task_file in list_task_files(paths)}
    max_version_by_task_dir: dict[Path, Version] = {}

    # Find highest version for each task
    for task_dir in sorted(task_dirs):
        changelog_path = task_dir / "CHANGELOG.md"
        if changelog_path.exists():
            yield Result("info", f"{changelog_path} already exists, skipping", task_dir)
            continue

        for task_file in list_task_files([task_dir]):
            task_content = task_file.read()
            try:
                version = task_content.require_valid_version()
            except VersioningError as e:
                yield Result(
                    "error",
                    f"{e}. Cannot determine current version for {task_dir}.",
                    task_file.path,
                    task_content.version_line,
                )
                max_version_by_task_dir.pop(task_dir, None)
                break

            max_version = max_version_by_task_dir.get(task_dir)
            if not max_version or version > max_version:
                max_version_by_task_dir[task_dir] = version

    # Write the changelogs
    for task_dir, version in max_version_by_task_dir.items():
        if version <= Version(0, 1):
            task_name = task_dir.name
            added_what = f"The initial version of the `{task_name}` task!"
        else:
            added_what = "Started tracking changes in this file."

        changelog_path = task_dir / "CHANGELOG.md"
        changelog_path.write_text(_new_changelog_content(str(version), added_what))
        yield Result("info", f"Created CHANGELOG.md at {changelog_path}", task_dir)


def _new_changelog_content(version: str, added_what: str) -> str:
    return textwrap.dedent(
        f"""\
        # Changelog

        ## Unreleased

        <!--
        When you make changes without bumping the version right away, document them here.
        If that's not something you ever plan to do, consider removing this section.
        -->

        *Nothing yet.*

        ## {version}

        ### Added

        - {added_what}
        """
    )


def make_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Versioning script for managing task versions")
    subcommands = parser.add_subparsers(title="subcommands", required=True)

    def set_command(
        subparser: argparse.ArgumentParser, cmd: Callable[..., Iterable[Result]]
    ) -> None:
        subparser.set_defaults(__cmd__=cmd)

    check_parser = subcommands.add_parser("check", help="Check versioning requirements")
    check_parser.add_argument("--base-ref", default="main", help="Base git ref (default: main)")
    check_parser.add_argument(
        "paths", nargs="*", type=Path, metavar="path", help="Files/directories to handle"
    )
    set_command(check_parser, check)

    new_changelog_parser = subcommands.add_parser("new-changelog", help="Create CHANGELOG.md")
    new_changelog_parser.add_argument(
        "paths", nargs="+", type=Path, metavar="path", help="Files/directories to handle"
    )
    set_command(new_changelog_parser, new_changelog)

    return parser


def main() -> int:
    """Run the CLI."""
    parser = make_parser()
    args = vars(parser.parse_args())
    cmd = args.pop("__cmd__")

    results: Iterable[Result] = cmd(**args)
    exitcode = 0

    in_gh_actions = os.getenv("GITHUB_ACTIONS") == "true"
    stderr_is_tty = sys.stderr.isatty()

    for result in results:
        if in_gh_actions:
            print(result.format_gh(), file=sys.stderr)
        else:
            print(result.format_plain(use_color=stderr_is_tty), file=sys.stderr)

        if result.kind == "error":
            exitcode = 1

    return exitcode


if __name__ == "__main__":
    sys.exit(main())
