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
