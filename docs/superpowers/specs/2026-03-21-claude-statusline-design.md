# Claude Code Statusline — Design Spec

## Overview

A Rust-based powerline statusline for Claude Code's built-in status bar feature. Displays model info, git branch, context window usage, and rate limits across 2 lines with Catppuccin Mocha theming and color-coded thresholds.

## Layout

```
✦  Opus   main   42% ██████░░░░
 5h: 23% (2h 14m)   7d: 41% (4d 12h)
```

- Line 1: Session identity + development context + context health
- Line 2: Rate limit consumption with reset countdowns
- Degrades to single line when rate limit data is absent (API key users)

## Segments

### Line 1

| # | Content | Icon | Data Source | Background |
|---|---------|------|-------------|------------|
| 1 | Model name | `✦ ` | `model.display_name` | Mauve #cba6f7 |
| 2 | Git branch | ` ` | `git branch --show-current` (in `cwd`) | Green #a6e3a1 |
| 3 | Context window | ` ` | `context_window.used_percentage` | Threshold-colored |

- Segment 1 combines the `✦` sparkle and model name into one segment (shared Mauve background)
- Segment 3 includes a 10-character progress bar: filled `█` + empty `░`

### Line 2

| # | Content | Icon | Data Source | Background |
|---|---------|------|-------------|------------|
| 4 | 5-hour rate limit | `󰓅 ` | `rate_limits.five_hour` | Threshold-colored |
| 5 | 7-day rate limit | `󰓅 ` | `rate_limits.seven_day` | Threshold-colored |

- Each shows percentage (rounded to integer) + countdown in parentheses
- Entire line hidden when `rate_limits` is absent from JSON
- If only one window is present, show a single segment on line 2

## Color Thresholds

Applied to context window (segment 3) and both rate limit segments (4, 5):

| Range | Background | Text Color |
|-------|-----------|------------|
| 0-49% | Green #a6e3a1 | Base #1e1e2e |
| 50-79% | Yellow #f9e2af | Base #1e1e2e |
| 80-100% | Red #f38ba8 | Base #1e1e2e |

## Powerline Separators

- Use `\u{E0B0}` (Powerline right arrow) between segments
- Separator foreground = left segment's background
- Separator background = right segment's background (or terminal default for last segment)
- Both lines start with an arrow from terminal default bg into first segment's bg
- Both lines end with an arrow from last segment's bg into terminal default bg

## Countdown Format

Computed from `resets_at` Unix timestamp minus current time:

| Remaining | Format | Example |
|-----------|--------|---------|
| >= 24h | `{d}d {h}h` | `(4d 12h)` |
| 1h - 24h | `{h}h {m}m` | `(2h 14m)` |
| < 1h | `{m}m` | `(14m)` |
| <= 0 (past) | `resetting` | `(resetting)` |

## Graceful Degradation

| Condition | Behavior |
|-----------|----------|
| `rate_limits` absent | Single line output (line 2 hidden) |
| `context_window.used_percentage` null | Show `0%` with empty bar `░░░░░░░░░░` |
| `git branch --show-current` fails or empty (detached HEAD) | Show `—` as branch name |
| `model` absent | Show `—` |

## Technical Implementation

### Language & Dependencies

- **Language:** Rust (2-10ms startup, single binary)
- **Crates:**
  - `serde` + `serde_json` — JSON deserialization from stdin
  - No TUI framework — raw ANSI escape sequences via `print!()`
  - No chrono — `std::time::SystemTime` + integer arithmetic for countdowns

### Data Flow

1. Claude Code pipes JSON to the binary's stdin (on every assistant message, debounced 300ms)
2. Binary deserializes JSON into typed structs
3. Runs `git branch --show-current` in `cwd` directory (result cached to file for 5 seconds)
4. Computes countdown strings from `resets_at` timestamps
5. Renders ANSI-colored powerline segments to stdout (1 or 2 lines)

### JSON Input Structure (relevant fields)

```json
{
  "model": { "display_name": "Opus" },
  "context_window": {
    "used_percentage": 42,
    "context_window_size": 200000
  },
  "rate_limits": {
    "five_hour": { "used_percentage": 23.5, "resets_at": 1738425600 },
    "seven_day": { "used_percentage": 41.2, "resets_at": 1738857600 }
  },
  "cwd": "/home/ice/.dotfiles"
}
```

### Git Caching

Each invocation is a new process — in-memory caching is impossible. Use file-based caching:

- Cache file: `/tmp/claude-statusline-git-cache` (JSON: `{"branch": "main", "cwd": "/path", "ts": 1234567890}`)
- On each invocation, read cache file; if `cwd` matches and age < 5 seconds, use cached branch
- Otherwise run `git branch --show-current` in `cwd`, write result + timestamp to cache file
- On failure or empty output (detached HEAD), return `"—"` (do not cache failures)

### Branch Name Truncation

- Max 20 characters; truncate with `…` if longer
- Example: `feature/JIRA-12345-au…`

### ANSI Output

- Use `\x1b[38;2;R;G;Bm` for 24-bit foreground color
- Use `\x1b[48;2;R;G;Bm` for 24-bit background color
- Use `\x1b[0m` to reset at end of each line
- Each line is a separate `println!()` call

### Binary Location & Integration

- Build target: `~/.claude/statusline` (single binary)
- Claude Code config in `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline"
  }
}
```

### Project Structure

```
tools/claude-statusline/
├── Cargo.toml
├── src/
│   ├── main.rs          # Entry point: read stdin, parse, render
│   ├── data.rs          # Serde structs for JSON input
│   ├── segments.rs      # Segment rendering (powerline, colors, bars)
│   ├── countdown.rs     # Countdown formatting from timestamps
│   ├── git.rs           # Git branch with file-based caching
│   └── colors.rs        # Catppuccin Mocha palette constants
```

## Catppuccin Mocha Palette (used colors)

| Name | Hex | Usage |
|------|-----|-------|
| Base | #1e1e2e | Dark text on colored backgrounds |
| Mauve | #cba6f7 | Model segment background |
| Green | #a6e3a1 | Git branch bg, healthy threshold |
| Yellow | #f9e2af | Warning threshold |
| Red | #f38ba8 | Critical threshold |
