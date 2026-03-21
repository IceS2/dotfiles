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
