#!/usr/bin/env python3
"""
git_commit_msg_scrub.py

Report or rewrite git commit messages by removing lines that contain
configured substrings (default: Claude/Opus/Anthropic/Claude Code).

Examples:
  Report commit IDs that contain default patterns:
    ./tools/git_commit_msg_scrub.py report

  Report with custom patterns only:
    ./tools/git_commit_msg_scrub.py report --no-defaults --pattern "Claude" --pattern "Anthropic"

  Rewrite all history, stripping matching lines:
    ./tools/git_commit_msg_scrub.py rewrite

Notes:
  - "rewrite" performs a history rewrite and will change commit IDs.
  - You will need to force-push and coordinate with collaborators.
"""

from __future__ import annotations

import argparse
import os
import shlex
import subprocess
import sys


DEFAULT_PATTERNS = [
    "Claude",
    "Opus",
    "Anthropic",
    "Claude Code",
]


def run_git(args, text_input=None):
    return subprocess.run(
        ["git"] + args,
        check=True,
        text=True,
        input=text_input,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def dedupe_preserve_order(items):
    seen = set()
    out = []
    for item in items:
        if item in seen:
            continue
        out.append(item)
        seen.add(item)
    return out


def build_patterns(raw_patterns, use_defaults):
    patterns = []
    if use_defaults:
        patterns.extend(DEFAULT_PATTERNS)
    patterns.extend(raw_patterns)
    patterns = [p for p in patterns if p]
    return dedupe_preserve_order(patterns)


def build_matcher(patterns, case_sensitive):
    if case_sensitive:
        def matches(line):
            for pat in patterns:
                if pat in line:
                    return True
            return False
        return matches

    lowered = [pat.lower() for pat in patterns]

    def matches(line):
        text = line.lower()
        for pat in lowered:
            if pat in text:
                return True
        return False

    return matches


def filter_message(message, match_line):
    if message == "":
        return message
    trailing_newline = message.endswith("\n")
    lines = message.splitlines()
    kept = [line for line in lines if not match_line(line)]
    filtered = "\n".join(kept)
    if trailing_newline:
        filtered += "\n"
    return filtered


def iter_commits(rev):
    args = ["log", "--format=%H%x00%B%x00"]
    if rev:
        if rev == "--all":
            args.append("--all")
        else:
            args.append(rev)
    else:
        args.append("--all")
    output = run_git(args).stdout
    fields = output.split("\0")
    limit = len(fields) - 1
    for idx in range(0, limit, 2):
        commit_id = fields[idx]
        message = fields[idx + 1]
        if not commit_id:
            continue
        yield commit_id, message


def report_commits(patterns, case_sensitive, rev, include_subject, show_lines):
    matcher = build_matcher(patterns, case_sensitive)
    for commit_id, message in iter_commits(rev):
        lines = message.splitlines()
        offenders = [line for line in lines if matcher(line)]
        if not offenders:
            continue
        if include_subject:
            subject = lines[0] if lines else ""
            print(f"{commit_id} {subject}")
        else:
            print(commit_id)
        if show_lines:
            for line in offenders:
                print(f"  {line}")


def filter_message_from_env():
    raw = os.environ.get("GIT_SCRUB_PATTERNS", "")
    use_defaults = os.environ.get("GIT_SCRUB_USE_DEFAULTS", "0") == "1"
    case_sensitive = os.environ.get("GIT_SCRUB_CASE_SENSITIVE", "0") == "1"
    patterns = build_patterns(raw.split("\n"), use_defaults)
    matcher = build_matcher(patterns, case_sensitive)
    original = sys.stdin.read()
    sys.stdout.write(filter_message(original, matcher))


def rewrite_history(patterns, case_sensitive, rev, force):
    if not patterns:
        print("No patterns provided; nothing to rewrite.", file=sys.stderr)
        return 2
    script_path = os.path.realpath(__file__)
    msg_filter = f"{shlex.quote(sys.executable)} {shlex.quote(script_path)} --filter-message"
    cmd = ["git", "filter-branch"]
    if force:
        cmd.append("-f")
    cmd.extend(["--msg-filter", msg_filter, "--"])
    if rev == "--all":
        cmd.append("--all")
    else:
        cmd.append(rev)
    env = os.environ.copy()
    env["FILTER_BRANCH_SQUELCH_WARNING"] = "1"
    env["GIT_SCRUB_PATTERNS"] = "\n".join(patterns)
    env["GIT_SCRUB_USE_DEFAULTS"] = "0"
    env["GIT_SCRUB_CASE_SENSITIVE"] = "1" if case_sensitive else "0"
    subprocess.run(cmd, check=True, env=env)
    return 0


def parse_args(argv):
    parser = argparse.ArgumentParser(
        description="Report or rewrite git commit messages by removing lines that match substrings.",
    )
    parser.add_argument(
        "--pattern",
        action="append",
        default=[],
        help="Substring to match; can be provided multiple times.",
    )
    parser.add_argument(
        "--no-defaults",
        action="store_true",
        help="Disable default patterns.",
    )
    parser.add_argument(
        "--case-sensitive",
        action="store_true",
        help="Use case-sensitive matching.",
    )
    parser.add_argument(
        "--rev",
        default="--all",
        help="Git revision range to scan/rewrite (default: --all).",
    )
    parser.add_argument(
        "--filter-message",
        action="store_true",
        help=argparse.SUPPRESS,
    )
    subparsers = parser.add_subparsers(dest="command")

    report_parser = subparsers.add_parser("report", help="List commits containing matching lines.")
    report_parser.add_argument(
        "--include-subject",
        action="store_true",
        help="Include commit subject after the commit ID.",
    )
    report_parser.add_argument(
        "--show-lines",
        action="store_true",
        help="Show the offending lines under each commit ID.",
    )

    rewrite_parser = subparsers.add_parser("rewrite", help="Rewrite history, removing matching lines.")
    rewrite_parser.add_argument(
        "--force",
        action="store_true",
        help="Pass -f to git filter-branch.",
    )

    args = parser.parse_args(argv)
    if args.filter_message:
        return args
    if args.command is None:
        parser.error("missing command (report|rewrite)")
    return args


def main(argv):
    args = parse_args(argv)
    if args.filter_message:
        filter_message_from_env()
        return 0

    patterns = build_patterns(args.pattern, not args.no_defaults)
    if not patterns:
        print("No patterns provided. Use --pattern or allow defaults.", file=sys.stderr)
        return 2

    if args.command == "report":
        report_commits(
            patterns=patterns,
            case_sensitive=args.case_sensitive,
            rev=args.rev,
            include_subject=args.include_subject,
            show_lines=args.show_lines,
        )
        return 0

    if args.command == "rewrite":
        return rewrite_history(
            patterns=patterns,
            case_sensitive=args.case_sensitive,
            rev=args.rev,
            force=args.force,
        )

    print(f"Unknown command: {args.command}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
