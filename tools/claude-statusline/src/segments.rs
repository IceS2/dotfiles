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
