#!/usr/bin/env python3
"""
Generate nerdfonts-data.json from Nerd Fonts glyphnames.json.
Output: quickshell/data/nerdfonts-data.json — flat array, compact JSON.
"""

import json
import urllib.request
from pathlib import Path

GLYPHNAMES_URL = "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/glyphnames.json"
OUTPUT_PATH = Path(__file__).parent.parent / "quickshell" / "data" / "nerdfonts-data.json"

PREFIX_CATEGORY_MAP = {
    "md-": "Material Design",
    "fa-": "Font Awesome",
    "dev-": "Devicons",
    "cod-": "Codicons",
    "weather-": "Weather",
    "oct-": "Octicons",
    "pom-": "Pomicons",
    "pl-": "Powerline",
    "ple-": "Powerline Extra",
    "extra-": "Powerline Extra",
    "seti-": "Seti",
    "custom-": "Custom",
    "iec-": "IEC Power",
    "linux-": "Linux",
    "fae-": "Font Awesome Ext",
    "indent-": "Indentation",
    "indentation-": "Indentation",
}


def fetch_glyphnames() -> dict:
    print(f"Downloading {GLYPHNAMES_URL} ...")
    with urllib.request.urlopen(GLYPHNAMES_URL) as response:
        return json.loads(response.read().decode("utf-8"))


def get_category(glyph_name: str) -> str:
    for prefix, category in PREFIX_CATEGORY_MAP.items():
        if glyph_name.startswith(prefix):
            return category
    return "Other"


def get_readable_name(glyph_name: str) -> str:
    """Strip prefix and replace dashes/underscores with spaces, lowercase."""
    for prefix in PREFIX_CATEGORY_MAP:
        if glyph_name.startswith(prefix):
            stripped = glyph_name[len(prefix):]
            return stripped.replace("-", " ").replace("_", " ").lower()
    # No known prefix — use full name with separators replaced
    return glyph_name.replace("-", " ").replace("_", " ").lower()


def parse_glyphnames(data: dict) -> list[dict]:
    icons = []

    for glyph_name, entry in data.items():
        # Skip the METADATA key
        if glyph_name == "METADATA":
            continue

        code = entry.get("code")
        if not code:
            continue

        char = chr(int(code, 16))
        category = get_category(glyph_name)
        name = get_readable_name(glyph_name)
        keywords = [w for w in name.split() if len(w) > 1]

        icons.append(
            {
                "char": char,
                "name": name,
                "keywords": keywords,
                "category": category,
                "type": "icon",
            }
        )

    # Sort by category then name
    icons.sort(key=lambda x: (x["category"], x["name"]))
    return icons


def main():
    data = fetch_glyphnames()
    icons = parse_glyphnames(data)

    print(f"Parsed {len(icons)} Nerd Fonts glyph entries")

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(icons, f, ensure_ascii=False, separators=(",", ":"))

    size_kb = OUTPUT_PATH.stat().st_size / 1024
    print(f"Written to {OUTPUT_PATH} ({size_kb:.1f} KB)")

    # Quick sanity check
    with open(OUTPUT_PATH, encoding="utf-8") as f:
        loaded = json.load(f)
    assert len(loaded) == len(icons), "Round-trip count mismatch"
    sample = loaded[0]
    assert all(k in sample for k in ("char", "name", "keywords", "category", "type"))
    assert sample["type"] == "icon"
    print(f"Sanity check passed. Sample entry: {sample}")

    # Category breakdown
    from collections import Counter
    cats = Counter(e["category"] for e in loaded)
    print("\nCategory breakdown:")
    for cat, count in sorted(cats.items()):
        print(f"  {cat}: {count}")


if __name__ == "__main__":
    main()
