mod colors;
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
