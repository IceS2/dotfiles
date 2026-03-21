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
        .stderr(std::process::Stdio::null())
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
