//! Custom Tera template filters for color manipulation
//!
//! These filters transform color values during template rendering.

use std::collections::HashMap;
use tera::Value;

/// Convert hex color to RGB format for applications like ripgrep
///
/// Input: "#RRGGBB" -> Output: "0xRR,0xGG,0xBB"
///
/// # Example
/// ```ignore
/// {{ colors.red | hex_to_rgb }}  // "#FF5733" -> "0xFF,0x57,0x33"
/// ```
pub fn hex_to_rgb(value: &Value, _args: &HashMap<String, Value>) -> tera::Result<Value> {
    let hex = value
        .as_str()
        .ok_or_else(|| tera::Error::msg("hex_to_rgb expects a string"))?;

    let clean = hex.trim_start_matches('#');
    if clean.len() != 6 {
        return Err(tera::Error::msg(format!(
            "hex_to_rgb expects 6 hex digits, got: {}",
            hex
        )));
    }

    let r = &clean[0..2];
    let g = &clean[2..4];
    let b = &clean[4..6];

    Ok(Value::String(format!("0x{},0x{},0x{}", r, g, b)))
}

/// Strip the # prefix from a hex color
///
/// Input: "#RRGGBB" -> Output: "RRGGBB"
///
/// # Example
/// ```ignore
/// {{ colors.blue | strip_hash }}  // "#1e90ff" -> "1e90ff"
/// ```
pub fn strip_hash(value: &Value, _args: &HashMap<String, Value>) -> tera::Result<Value> {
    let hex = value
        .as_str()
        .ok_or_else(|| tera::Error::msg("strip_hash expects a string"))?;

    Ok(Value::String(hex.trim_start_matches('#').to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hex_to_rgb_uppercase() {
        let value = Value::String("#FF5733".to_string());
        let result = hex_to_rgb(&value, &HashMap::new()).unwrap();
        assert_eq!(result, Value::String("0xFF,0x57,0x33".to_string()));
    }

    #[test]
    fn test_hex_to_rgb_lowercase() {
        let value = Value::String("#abcdef".to_string());
        let result = hex_to_rgb(&value, &HashMap::new()).unwrap();
        assert_eq!(result, Value::String("0xab,0xcd,0xef".to_string()));
    }

    #[test]
    fn test_hex_to_rgb_invalid_length() {
        let value = Value::String("#FFF".to_string());
        let result = hex_to_rgb(&value, &HashMap::new());
        assert!(result.is_err());
    }

    #[test]
    fn test_strip_hash() {
        let value = Value::String("#1e90ff".to_string());
        let result = strip_hash(&value, &HashMap::new()).unwrap();
        assert_eq!(result, Value::String("1e90ff".to_string()));
    }

    #[test]
    fn test_strip_hash_no_hash() {
        let value = Value::String("1e90ff".to_string());
        let result = strip_hash(&value, &HashMap::new()).unwrap();
        assert_eq!(result, Value::String("1e90ff".to_string()));
    }
}
