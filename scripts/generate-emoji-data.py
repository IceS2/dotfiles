#!/usr/bin/env python3
"""
Generate emoji-data.json from Unicode emoji-test.txt (v16.0).
Output: quickshell/data/emoji-data.json — flat array, compact JSON.
"""

import json
import re
import urllib.request
from pathlib import Path

EMOJI_TEST_URL = "https://unicode.org/Public/emoji/16.0/emoji-test.txt"
OUTPUT_PATH = Path(__file__).parent.parent / "quickshell" / "data" / "emoji-data.json"

CATEGORY_MAP = {
    "Smileys & Emotion": "Smileys",
    "People & Body": "People",
    "Component": None,  # skip
    "Animals & Nature": "Animals",
    "Food & Drink": "Food",
    "Travel & Places": "Travel",
    "Activities": "Activities",
    "Objects": "Objects",
    "Symbols": "Symbols",
    "Flags": "Flags",
}


def fetch_emoji_test() -> str:
    print(f"Downloading {EMOJI_TEST_URL} ...")
    with urllib.request.urlopen(EMOJI_TEST_URL) as response:
        return response.read().decode("utf-8")


def parse_emoji_test(text: str) -> list[dict]:
    emojis = []
    current_group = None

    for line in text.splitlines():
        # Detect group header
        group_match = re.match(r"^# group: (.+)$", line)
        if group_match:
            current_group = group_match.group(1).strip()
            continue

        # Skip comments and blank lines
        if not line or line.startswith("#"):
            continue

        # Skip if group should be omitted
        if current_group is None:
            continue
        category = CATEGORY_MAP.get(current_group)
        if category is None:
            continue

        # Parse emoji line:
        # <codepoints> ; <status> # <emoji> E<version> <name>
        match = re.match(
            r"^[0-9A-F ]+\s*;\s*(fully-qualified)\s*#\s*(\S+)\s+E[\d.]+\s+(.+)$",
            line,
        )
        if not match:
            continue

        _status, char, name = match.group(1), match.group(2), match.group(3)
        name = name.strip().lower()

        # Build keywords from name words (filter words ≤1 char)
        keywords = [w for w in name.split() if len(w) > 1]

        emojis.append(
            {
                "char": char,
                "name": name,
                "keywords": keywords,
                "category": category,
                "type": "emoji",
            }
        )

    return emojis


def main():
    text = fetch_emoji_test()
    emojis = parse_emoji_test(text)

    print(f"Parsed {len(emojis)} fully-qualified emoji entries")

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(emojis, f, ensure_ascii=False, separators=(",", ":"))

    size_kb = OUTPUT_PATH.stat().st_size / 1024
    print(f"Written to {OUTPUT_PATH} ({size_kb:.1f} KB)")

    # Quick sanity check
    with open(OUTPUT_PATH, encoding="utf-8") as f:
        data = json.load(f)
    assert len(data) == len(emojis), "Round-trip count mismatch"
    sample = data[0]
    assert all(k in sample for k in ("char", "name", "keywords", "category", "type"))
    print(f"Sanity check passed. Sample entry: {sample}")


if __name__ == "__main__":
    main()
