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
