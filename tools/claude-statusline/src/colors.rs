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
