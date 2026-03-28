# Claude Code Statusline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Rust binary that renders a 2-line powerline statusline for Claude Code with model, git branch, context window, and rate limit info themed in Catppuccin Mocha.

**Architecture:** Single Rust binary reads JSON from stdin, runs `git branch --show-current` (file-cached), computes countdown timers, and prints ANSI-colored powerline output to stdout. No TUI framework — raw escape sequences only.

**Tech Stack:** Rust, serde + serde_json, std::time, ANSI 24-bit color escapes

**Spec:** `docs/superpowers/specs/2026-03-21-claude-statusline-design.md`

---

## File Structure

```
tools/claude-statusline/
├── Cargo.toml              # Package manifest (serde, serde_json)
├── src/
│   ├── main.rs             # Entry: read stdin JSON, get git branch, render lines, print
│   ├── data.rs             # Serde structs matching Claude Code's JSON schema
│   ├── colors.rs           # Catppuccin Mocha RGB constants + threshold function
│   ├── countdown.rs        # Format seconds-remaining into "(2h 14m)" strings
│   ├── git.rs              # git branch --show-current with /tmp file cache
│   └── segments.rs         # Powerline segment builder (bg/fg, separator, progress bar)
```

---

### Task 1: Project Scaffold + Data Structs

**Files:**
- Create: `tools/claude-statusline/Cargo.toml`
- Create: `tools/claude-statusline/src/main.rs`
- Create: `tools/claude-statusline/src/data.rs`

- [ ] **Step 1: Create Cargo.toml**

```toml
[package]
name = "claude-statusline"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = { version = "1", features = ["derive"] }
serde_json = "1"

[profile.release]
strip = true
lto = true
```

- [ ] **Step 2: Create data.rs with serde structs**

```rust
use serde::Deserialize;

#[derive(Deserialize)]
pub struct StatusData {
    pub model: Option<Model>,
    pub context_window: Option<ContextWindow>,
    pub rate_limits: Option<RateLimits>,
    pub cwd: Option<String>,
}

#[derive(Deserialize)]
pub struct Model {
    pub display_name: String,
}

#[derive(Deserialize)]
pub struct ContextWindow {
    pub used_percentage: Option<f64>,
}

#[derive(Deserialize)]
pub struct RateLimits {
    pub five_hour: Option<RateWindow>,
    pub seven_day: Option<RateWindow>,
}

#[derive(Deserialize)]
pub struct RateWindow {
    pub used_percentage: f64,
    pub resets_at: u64,
}
```

- [ ] **Step 3: Create minimal main.rs that parses stdin**

```rust
mod data;

use std::io::Read;

fn main() {
    let mut input = String::new();
    if std::io::stdin().read_to_string(&mut input).is_err() {
        return;
    }
    let status: data::StatusData = match serde_json::from_str(&input) {
        Ok(d) => d,
        Err(_) => return,
    };
    // Placeholder: print model name
    let model = status
        .model
        .as_ref()
        .map(|m| m.display_name.as_str())
        .unwrap_or("—");
    println!("{}", model);
}
```

- [ ] **Step 4: Verify it compiles and parses JSON**

Run from `tools/claude-statusline/`:
```bash
cargo build
echo '{"model":{"display_name":"Opus"},"context_window":{"used_percentage":42},"cwd":"/tmp"}' | cargo run
```
Expected: prints `Opus`

- [ ] **Step 5: Commit**

```bash
git add tools/claude-statusline/
git commit -m "feat(statusline): scaffold Rust project with JSON data structs"
```

---

### Task 2: Colors + Threshold Logic

**Files:**
- Create: `tools/claude-statusline/src/colors.rs`
- Modify: `tools/claude-statusline/src/main.rs` (add `mod colors;`)

- [ ] **Step 1: Create colors.rs**

```rust
#[derive(Clone, Copy)]
pub struct Rgb(pub u8, pub u8, pub u8);

// Catppuccin Mocha palette
pub const BASE: Rgb = Rgb(30, 30, 46);
pub const MAUVE: Rgb = Rgb(203, 166, 247);
pub const GREEN: Rgb = Rgb(166, 227, 161);
pub const YELLOW: Rgb = Rgb(249, 226, 175);
pub const RED: Rgb = Rgb(243, 139, 168);

/// Returns background color based on percentage thresholds.
pub fn threshold_bg(pct: f64) -> Rgb {
    if pct >= 80.0 {
        RED
    } else if pct >= 50.0 {
        YELLOW
    } else {
        GREEN
    }
}
```

- [ ] **Step 2: Add `mod colors;` to main.rs**

Add `mod colors;` after the existing `mod data;` line.

- [ ] **Step 3: Verify it compiles**

```bash
cargo build
```

- [ ] **Step 4: Commit**

```bash
git add tools/claude-statusline/src/colors.rs tools/claude-statusline/src/main.rs
git commit -m "feat(statusline): add Catppuccin Mocha palette and threshold logic"
```

---

### Task 3: Countdown Formatting

**Files:**
- Create: `tools/claude-statusline/src/countdown.rs`
- Modify: `tools/claude-statusline/src/main.rs` (add `mod countdown;`)

- [ ] **Step 1: Create countdown.rs**

```rust
use std::time::{SystemTime, UNIX_EPOCH};

/// Format a `resets_at` Unix timestamp into a countdown string.
/// Returns strings like "(2h 14m)", "(14m)", "(4d 12h)", or "(resetting)".
pub fn format_countdown(resets_at: u64) -> String {
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();

    if resets_at <= now {
        return "(resetting)".to_string();
    }

    let remaining = resets_at - now;
    let minutes = remaining / 60;
    let hours = minutes / 60;
    let days = hours / 24;

    if days > 0 {
        format!("({}d {}h)", days, hours % 24)
    } else if hours > 0 {
        format!("({}h {}m)", hours, minutes % 60)
    } else {
        format!("({}m)", minutes.max(1))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::{SystemTime, UNIX_EPOCH};

    fn now_secs() -> u64 {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs()
    }

    #[test]
    fn past_timestamp_shows_resetting() {
        assert_eq!(format_countdown(0), "(resetting)");
        assert_eq!(format_countdown(now_secs() - 60), "(resetting)");
    }

    #[test]
    fn minutes_only() {
        let result = format_countdown(now_secs() + 14 * 60 + 30);
        assert_eq!(result, "(14m)");
    }

    #[test]
    fn hours_and_minutes() {
        let result = format_countdown(now_secs() + 2 * 3600 + 14 * 60 + 30);
        assert_eq!(result, "(2h 14m)");
    }

    #[test]
    fn days_and_hours() {
        let result = format_countdown(now_secs() + 4 * 86400 + 12 * 3600 + 30 * 60);
        assert_eq!(result, "(4d 12h)");
    }

    #[test]
    fn very_small_remaining_shows_1m() {
        let result = format_countdown(now_secs() + 5);
        assert_eq!(result, "(1m)");
    }
}
```

- [ ] **Step 2: Add `mod countdown;` to main.rs**

Add `mod countdown;` after `mod colors;`.

- [ ] **Step 3: Run tests**

```bash
cargo test
```
Expected: all 5 tests pass.

- [ ] **Step 4: Commit**

```bash
git add tools/claude-statusline/src/countdown.rs tools/claude-statusline/src/main.rs
git commit -m "feat(statusline): add countdown formatting with tests"
```

---

### Task 4: Git Branch with File-Based Cache

**Files:**
- Create: `tools/claude-statusline/src/git.rs`
- Modify: `tools/claude-statusline/src/main.rs` (add `mod git;`)

- [ ] **Step 1: Create git.rs**

```rust
use std::io::Write;
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};

const CACHE_PATH: &str = "/tmp/claude-statusline-git-cache";
const CACHE_TTL_SECS: u64 = 5;
const MAX_BRANCH_LEN: usize = 20;

/// Get current git branch for `cwd`, using a file-based cache.
pub fn get_branch(cwd: &str) -> String {
    if let Some(cached) = read_cache(cwd) {
        return cached;
    }
    let branch = run_git(cwd);
    if !branch.is_empty() {
        write_cache(cwd, &branch);
    }
    if branch.is_empty() {
        "\u{2014}".to_string() // em dash
    } else {
        truncate_branch(&branch)
    }
}

fn now_secs() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

fn read_cache(cwd: &str) -> Option<String> {
    let content = std::fs::read_to_string(CACHE_PATH).ok()?;
    let val: serde_json::Value = serde_json::from_str(&content).ok()?;
    let cached_cwd = val.get("cwd")?.as_str()?;
    let ts = val.get("ts")?.as_u64()?;
    let branch = val.get("branch")?.as_str()?;
    if cached_cwd == cwd && now_secs() - ts < CACHE_TTL_SECS {
        Some(truncate_branch(branch))
    } else {
        None
    }
}

fn write_cache(cwd: &str, branch: &str) {
    let cache = serde_json::json!({
        "branch": branch,
        "cwd": cwd,
        "ts": now_secs(),
    });
    if let Ok(mut f) = std::fs::File::create(CACHE_PATH) {
        let _ = f.write_all(cache.to_string().as_bytes());
    }
}

fn run_git(cwd: &str) -> String {
    Command::new("git")
        .args(["branch", "--show-current"])
        .current_dir(cwd)
        .output()
        .ok()
        .and_then(|o| {
            if o.status.success() {
                Some(String::from_utf8_lossy(&o.stdout).trim().to_string())
            } else {
                None
            }
        })
        .unwrap_or_default()
}

fn truncate_branch(branch: &str) -> String {
    if branch.chars().count() > MAX_BRANCH_LEN {
        let truncated: String = branch.chars().take(MAX_BRANCH_LEN - 1).collect();
        format!("{}\u{2026}", truncated) // ellipsis
    } else {
        branch.to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn truncate_short_branch_unchanged() {
        assert_eq!(truncate_branch("main"), "main");
    }

    #[test]
    fn truncate_long_branch_adds_ellipsis() {
        let long = "feature/JIRA-12345-implement-auth";
        let result = truncate_branch(long);
        assert!(result.chars().count() == MAX_BRANCH_LEN);
        assert!(result.ends_with('\u{2026}'));
    }

    #[test]
    fn truncate_exact_length_unchanged() {
        let exact: String = "a".repeat(MAX_BRANCH_LEN);
        assert_eq!(truncate_branch(&exact), exact);
    }
}
```

- [ ] **Step 2: Add `mod git;` to main.rs**

Add `mod git;` after `mod countdown;`.

- [ ] **Step 3: Run tests**

```bash
cargo test
```
Expected: all tests pass (countdown + git truncation).

- [ ] **Step 4: Commit**

```bash
git add tools/claude-statusline/src/git.rs tools/claude-statusline/src/main.rs
git commit -m "feat(statusline): add git branch lookup with file-based cache"
```

---

### Task 5: Segment Rendering (Powerline Builder)

**Files:**
- Create: `tools/claude-statusline/src/segments.rs`
- Modify: `tools/claude-statusline/src/main.rs` (add `mod segments;`)

- [ ] **Step 1: Create segments.rs**

```rust
use crate::colors::Rgb;

const POWERLINE_ARROW: char = '\u{E0B0}';

/// ANSI 24-bit foreground color escape.
fn fg(Rgb(r, g, b): Rgb) -> String {
    format!("\x1b[38;2;{r};{g};{b}m")
}

/// ANSI 24-bit background color escape.
fn bg(Rgb(r, g, b): Rgb) -> String {
    format!("\x1b[48;2;{r};{g};{b}m")
}

const RESET: &str = "\x1b[0m";

/// Build a progress bar string: `██████░░░░`
pub fn progress_bar(pct: f64, width: usize) -> String {
    let filled = ((pct / 100.0) * width as f64).round() as usize;
    let filled = filled.min(width);
    let empty = width - filled;
    format!("{}{}", "█".repeat(filled), "░".repeat(empty))
}

/// A powerline segment with text and background color.
pub struct Segment {
    pub text: String,
    pub bg_color: Rgb,
    pub fg_color: Rgb,
}

/// Render a line of powerline segments to an ANSI string.
pub fn render_line(segments: &[Segment]) -> String {
    let mut out = String::new();
    for (i, seg) in segments.iter().enumerate() {
        // Leading arrow: previous bg (or default) -> this bg
        if i == 0 {
            // Arrow from terminal default into first segment
            out.push_str(&fg(seg.bg_color));
            out.push(POWERLINE_ARROW);
        } else {
            // Arrow from previous segment bg into this segment bg
            out.push_str(&fg(segments[i - 1].bg_color));
            out.push_str(&bg(seg.bg_color));
            out.push(POWERLINE_ARROW);
        }
        // Segment content
        out.push_str(&bg(seg.bg_color));
        out.push_str(&fg(seg.fg_color));
        out.push_str(&seg.text);
    }
    // Trailing arrow: last segment bg -> terminal default
    if let Some(last) = segments.last() {
        out.push_str(RESET);
        out.push_str(&fg(last.bg_color));
        out.push(POWERLINE_ARROW);
        out.push_str(RESET);
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn progress_bar_0_percent() {
        assert_eq!(progress_bar(0.0, 10), "░░░░░░░░░░");
    }

    #[test]
    fn progress_bar_50_percent() {
        assert_eq!(progress_bar(50.0, 10), "█████░░░░░");
    }

    #[test]
    fn progress_bar_100_percent() {
        assert_eq!(progress_bar(100.0, 10), "██████████");
    }

    #[test]
    fn progress_bar_42_percent() {
        assert_eq!(progress_bar(42.0, 10), "████░░░░░░");
    }

    #[test]
    fn render_line_produces_output() {
        let segments = vec![
            Segment {
                text: " test ".to_string(),
                bg_color: Rgb(100, 100, 100),
                fg_color: Rgb(0, 0, 0),
            },
        ];
        let result = render_line(&segments);
        assert!(result.contains("test"));
        assert!(result.contains('\u{E0B0}'));
    }
}
```

- [ ] **Step 2: Add `mod segments;` to main.rs**

Add `mod segments;` after `mod git;`.

- [ ] **Step 3: Run tests**

```bash
cargo test
```
Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add tools/claude-statusline/src/segments.rs tools/claude-statusline/src/main.rs
git commit -m "feat(statusline): add powerline segment renderer with progress bar"
```

---

### Task 6: Wire Everything Together in main.rs

**Files:**
- Modify: `tools/claude-statusline/src/main.rs`

- [ ] **Step 1: Replace main.rs with full rendering logic**

```rust
mod colors;
mod countdown;
mod data;
mod git;
mod segments;

use std::io::Read;

use colors::{threshold_bg, BASE, GREEN, MAUVE};
use countdown::format_countdown;
use segments::{progress_bar, render_line, Segment};

fn main() {
    let mut input = String::new();
    if std::io::stdin().read_to_string(&mut input).is_err() {
        return;
    }
    let status: data::StatusData = match serde_json::from_str(&input) {
        Ok(d) => d,
        Err(_) => return,
    };

    // -- Line 1: ✦ Model | Branch | Context% bar --
    let model_name = status
        .model
        .as_ref()
        .map(|m| m.display_name.as_str())
        .unwrap_or("\u{2014}");

    let branch = status
        .cwd
        .as_deref()
        .map(git::get_branch)
        .unwrap_or_else(|| "\u{2014}".to_string());

    let ctx_pct = status
        .context_window
        .as_ref()
        .and_then(|c| c.used_percentage)
        .unwrap_or(0.0);
    let ctx_bar = progress_bar(ctx_pct, 10);
    let ctx_bg = threshold_bg(ctx_pct);

    let line1 = render_line(&[
        Segment {
            text: format!(" \u{2726}  {} ", model_name),
            bg_color: MAUVE,
            fg_color: BASE,
        },
        Segment {
            text: format!("  {} ", branch),
            bg_color: GREEN,
            fg_color: BASE,
        },
        Segment {
            text: format!("  {}% {} ", (ctx_pct.round().clamp(0.0, 100.0)) as u32, ctx_bar),
            bg_color: ctx_bg,
            fg_color: BASE,
        },
    ]);
    println!("{line1}");

    // -- Line 2: 5h rate | 7d rate (only if rate_limits present) --
    let rate_limits = match &status.rate_limits {
        Some(rl) => rl,
        None => return,
    };

    let mut line2_segments: Vec<Segment> = Vec::new();

    if let Some(five) = &rate_limits.five_hour {
        let cd = format_countdown(five.resets_at);
        let pct = five.used_percentage;
        line2_segments.push(Segment {
            text: format!(" 󰓅 5h: {}% {} ", (pct.round().clamp(0.0, 100.0)) as u32, cd),
            bg_color: threshold_bg(pct),
            fg_color: BASE,
        });
    }

    if let Some(seven) = &rate_limits.seven_day {
        let cd = format_countdown(seven.resets_at);
        let pct = seven.used_percentage;
        line2_segments.push(Segment {
            text: format!(" 󰓅 7d: {}% {} ", (pct.round().clamp(0.0, 100.0)) as u32, cd),
            bg_color: threshold_bg(pct),
            fg_color: BASE,
        });
    }

    if !line2_segments.is_empty() {
        println!("{}", render_line(&line2_segments));
    }
}
```

- [ ] **Step 2: Test with full JSON input**

```bash
echo '{"model":{"display_name":"Opus"},"context_window":{"used_percentage":42},"rate_limits":{"five_hour":{"used_percentage":23.5,"resets_at":'"$(( $(date +%s) + 8040 ))"'},"seven_day":{"used_percentage":41.2,"resets_at":'"$(( $(date +%s) + 388800 ))"'}},"cwd":"/home/ice/.dotfiles"}' | cargo run
```
Expected: 2-line powerline output with colored segments, progress bar, countdowns.

- [ ] **Step 3: Test graceful degradation — no rate limits**

```bash
echo '{"model":{"display_name":"Sonnet"},"context_window":{"used_percentage":85},"cwd":"/tmp"}' | cargo run
```
Expected: single line, context bar in red (85% > 80%).

- [ ] **Step 4: Test graceful degradation — minimal JSON**

```bash
echo '{}' | cargo run
```
Expected: single line with dashes for model and branch, 0% context bar.

- [ ] **Step 5: Run all tests**

```bash
cargo test
```
Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add tools/claude-statusline/src/main.rs
git commit -m "feat(statusline): wire all components into full powerline renderer"
```

---

### Task 7: Build Release Binary + Configure Claude Code

**Files:**
- Modify: `tools/claude-statusline/Cargo.toml` (verify release profile)

- [ ] **Step 1: Build optimized release binary**

```bash
cd tools/claude-statusline && cargo build --release
```

- [ ] **Step 2: Copy binary to ~/.claude/statusline**

```bash
cp tools/claude-statusline/target/release/claude-statusline ~/.claude/statusline
```

- [ ] **Step 3: Verify binary works standalone**

```bash
echo '{"model":{"display_name":"Opus"},"context_window":{"used_percentage":42},"cwd":"/home/ice/.dotfiles"}' | ~/.claude/statusline
```
Expected: powerline output.

- [ ] **Step 4: Add install.sh for the module**

Create `tools/claude-statusline/install.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/helpers.sh"

log_header "Claude Statusline"

# Build release binary
if command -v cargo &>/dev/null; then
    log_info "Building claude-statusline..."
    (cd "$SCRIPT_DIR" && cargo build --release --quiet)
    cp "$SCRIPT_DIR/target/release/claude-statusline" "$HOME/.claude/statusline"
    log_ok "Installed to ~/.claude/statusline"
else
    log_warn "cargo not found, skipping claude-statusline build"
fi
```

```bash
chmod +x tools/claude-statusline/install.sh
```

- [ ] **Step 5: Configure Claude Code statusline setting**

Add to `~/.claude/settings.json` (manually or via `/statusline` command):

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline"
  }
}
```

- [ ] **Step 6: Commit**

```bash
git add tools/claude-statusline/
git commit -m "feat(statusline): release build, install script, Claude Code integration"
```

---

### Task 8: End-to-End Verification

- [ ] **Step 1: Restart Claude Code (or start a new session)**

The statusline should appear at the bottom of the terminal after the first assistant message.

- [ ] **Step 2: Verify line 1 displays correctly**

Check: sparkle icon, model name (Mauve bg), git branch (Green bg), context % with progress bar.

- [ ] **Step 3: Verify line 2 displays correctly**

Check: 5h and 7d rate limits with countdowns (if on Pro/Max plan). If on API key, only line 1 should show.

- [ ] **Step 4: Verify threshold colors change**

As context usage grows through the session, the context segment should shift from green → yellow → red.

- [ ] **Step 5: Verify powerline arrows render correctly**

Ensure the Nerd Font `\u{E0B0}` arrows show between segments with proper color transitions. If arrows appear as boxes/squares, the terminal font doesn't include powerline glyphs.
