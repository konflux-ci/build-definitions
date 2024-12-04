#!/usr/bin/env python
import argparse
import json
import re
from itertools import groupby
from pathlib import Path
from typing import Any, Iterable, Iterator, TypedDict


class PackageRule(TypedDict):
    groupName: str
    matchFileNames: list[str]


def get_renovate_packagerules(codeowners_content: str) -> Iterator[PackageRule]:
    lines = map(str.strip, codeowners_content.splitlines())
    rules: list[PackageRule] = []

    for isempty, lines_group in groupby(lines, key=lambda line: not line):
        if not isempty and (rule := _process_owner_group(lines_group)):
            rules.append(rule)

    rules.sort(key=lambda rule: rule["groupName"])

    for groupname, rules_group in groupby(rules, key=lambda rule: rule["groupName"]):
        merged_patterns = set()
        for rule in rules_group:
            merged_patterns.update(rule["matchFileNames"])
        yield {"groupName": groupname, "matchFileNames": sorted(merged_patterns)}


def _process_owner_group(group: Iterable[str]) -> PackageRule | None:
    """Process a group of CODEOWNERS.

    If the group has a '# renovate groupName=' directive, return a packageRules object.
    Otherwise, return None.
    """
    renovate_directive_pat = re.compile(r"#\s*renovate\s+groupName=(.*)")

    patterns = []
    groupname = None

    for line in group:
        if not line.startswith("#"):
            pattern, *_ = line.split(maxsplit=1)
            patterns.append(pattern)
        elif m := renovate_directive_pat.match(line):
            groupname = m.group(1)

    if not groupname:
        return None

    patterns = list(map(_codeowners_pattern_to_glob_pattern, patterns))
    return {"groupName": groupname, "matchFileNames": patterns}



def _codeowners_pattern_to_glob_pattern(codeowners_pattern: str) -> str:
    if codeowners_pattern.startswith("/"):
        glob_pattern = codeowners_pattern.lstrip("/")
    else:
        glob_pattern = f"**/{codeowners_pattern}"

    if not glob_pattern.endswith("**") and any(p.is_dir() for p in Path().glob(glob_pattern)):
        glob_pattern += "/**"

    return glob_pattern


def merge_to_existing_rules(
    existing_rules: Iterable[dict[str, Any]], new_rules: Iterable[PackageRule]
) -> list[dict[str, Any]]:
    merged_rules = list(existing_rules)
    for new_rule in new_rules:
        for i, existing_rule in enumerate(merged_rules):
            if existing_rule.get("groupName") == new_rule["groupName"]:
                merged_rules[i] = existing_rule | new_rule
                break
        else:
            merged_rules.append(dict(new_rule))

    return merged_rules


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--output-file", type=Path)
    args = ap.parse_args()

    output_file: Path | None = args.output_file

    codeowners_path = Path("CODEOWNERS")
    renovate_json_path = Path("renovate.json")

    codeowners_package_rules = get_renovate_packagerules(codeowners_path.read_text())

    renovate_json = json.loads(renovate_json_path.read_text())

    package_rules = merge_to_existing_rules(
        renovate_json.get("packageRules", []),
        codeowners_package_rules,
    )

    renovate_json["packageRules"] = package_rules
    if output_file:
        with output_file.open("w") as f:
            print(json.dumps(renovate_json, indent=2), file=f)
    else:
        print(json.dumps(renovate_json, indent=2))


if __name__ == "__main__":
    main()
