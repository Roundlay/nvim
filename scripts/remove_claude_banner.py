"""git-filter-repo commit callback that removes the banner inserted by
Anthropic/Claude auto-generated commits.

It strips lines like:

    🤖 Generated with [Claude Code](https://claude.ai/code)
    Co-Authored-By: Claude <noreply@anthropic.com>

The textual replacement ":robot:" for the emoji is also recognised.
"""

import re
from typing import List


_BANNER_RE = re.compile(r"^\s*(?:🤖|:robot:)\s*Generated with \[Claude Code\]", re.IGNORECASE)
_COAUTHOR_RE = re.compile(
    r"^Co-Authored-By:\s*Claude\s*<noreply@anthropic\.com>\s*$", re.IGNORECASE
)


def _clean_message(message_bytes: bytes) -> bytes:
    """Return *message_bytes* with the Claude banner removed."""

    text = message_bytes.decode("utf-8", errors="surrogateescape")
    lines: List[str] = text.splitlines()
    cleaned: List[str] = []

    skip_blank_after_banner = False

    for line in lines:
        if _BANNER_RE.match(line):
            skip_blank_after_banner = True
            continue

        if _COAUTHOR_RE.match(line):
            continue

        if skip_blank_after_banner and line.strip() == "":
            skip_blank_after_banner = False
            continue

        cleaned.append(line)

    if not any(l.strip() for l in cleaned):
        cleaned = ["Cleanup: remove automated Claude banner"]

    return "\n".join(cleaned).encode("utf-8", errors="surrogateescape")


def commit_callback(commit):
    commit.message = _clean_message(commit.message)


Commit = commit_callback

