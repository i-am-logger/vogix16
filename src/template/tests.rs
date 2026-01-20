//! Tests for template module

use super::*;
use std::collections::HashMap;
use std::io::Write;
use tempfile::NamedTempFile;

fn sample_colors() -> HashMap<String, String> {
    let mut colors = HashMap::new();
    colors.insert("base00".to_string(), "#1e1e2e".to_string());
    colors.insert("base01".to_string(), "#181825".to_string());
    colors.insert("base02".to_string(), "#313244".to_string());
    colors.insert("base03".to_string(), "#45475a".to_string());
    colors.insert("base04".to_string(), "#585b70".to_string());
    colors.insert("base05".to_string(), "#cdd6f4".to_string());
    colors.insert("base06".to_string(), "#f5e0dc".to_string());
    colors.insert("base07".to_string(), "#b4befe".to_string());
    colors.insert("base08".to_string(), "#f38ba8".to_string());
    colors.insert("base09".to_string(), "#fab387".to_string());
    colors.insert("base0A".to_string(), "#f9e2af".to_string());
    colors.insert("base0B".to_string(), "#a6e3a1".to_string());
    colors.insert("base0C".to_string(), "#94e2d5".to_string());
    colors.insert("base0D".to_string(), "#89b4fa".to_string());
    colors.insert("base0E".to_string(), "#cba6f7".to_string());
    colors.insert("base0F".to_string(), "#f2cdcd".to_string());
    colors
}

#[test]
fn test_render_template_string_simple() {
    let colors = sample_colors();
    let template = r##"background = "{{ colors.base00 }}""##;

    let result = render_template_string(template, &colors).unwrap();
    assert_eq!(result, "background = \"#1e1e2e\"");
}

#[test]
fn test_render_template_string_multiple_colors() {
    let colors = sample_colors();
    let template = r##"[colors.primary]
background = "{{ colors.base00 }}"
foreground = "{{ colors.base05 }}"

[colors.normal]
red = "{{ colors.base08 }}"
green = "{{ colors.base0B }}""##;

    let result = render_template_string(template, &colors).unwrap();
    assert!(result.contains("background = \"#1e1e2e\""));
    assert!(result.contains("foreground = \"#cdd6f4\""));
    assert!(result.contains("red = \"#f38ba8\""));
    assert!(result.contains("green = \"#a6e3a1\""));
}

#[test]
fn test_render_template_string_preserves_non_template_content() {
    let colors = sample_colors();
    let template = r##"[font]
size = 12

[colors.primary]
background = "{{ colors.base00 }}""##;

    let result = render_template_string(template, &colors).unwrap();
    assert!(result.contains("[font]"));
    assert!(result.contains("size = 12"));
    assert!(result.contains("background = \"#1e1e2e\""));
}

#[test]
fn test_render_template_string_missing_variable() {
    let colors = sample_colors();
    let template = r##"background = "{{ colors.nonexistent }}""##;

    let result = render_template_string(template, &colors);
    // Tera errors on missing variables by default (strict mode)
    assert!(result.is_err());
}

#[test]
fn test_render_template_string_invalid_syntax() {
    let colors = sample_colors();
    // Missing closing braces
    let template = r##"background = "{{ colors.base00 }""##;

    let result = render_template_string(template, &colors);
    assert!(result.is_err());
}

#[test]
fn test_render_template_from_file() {
    let colors = sample_colors();

    let mut template_file = NamedTempFile::new().unwrap();
    write!(
        template_file,
        "[colors.primary]\nbackground = \"{{{{ colors.base00 }}}}\"\nforeground = \"{{{{ colors.base05 }}}}\""
    )
    .unwrap();

    let result = render_template(template_file.path(), &colors).unwrap();
    assert!(result.contains("background = \"#1e1e2e\""));
    assert!(result.contains("foreground = \"#cdd6f4\""));
}

#[test]
fn test_render_template_file_not_found() {
    let colors = sample_colors();
    let result = render_template("/nonexistent/template.vogix", &colors);
    assert!(result.is_err());
}

#[test]
fn test_full_alacritty_template() {
    let colors = sample_colors();
    let template = r##"[colors.primary]
background = "{{ colors.base00 }}"
foreground = "{{ colors.base05 }}"

[colors.cursor]
cursor = "{{ colors.base05 }}"
text = "{{ colors.base00 }}"

[colors.normal]
black = "{{ colors.base00 }}"
red = "{{ colors.base08 }}"
green = "{{ colors.base0B }}"
yellow = "{{ colors.base0A }}"
blue = "{{ colors.base0D }}"
magenta = "{{ colors.base0E }}"
cyan = "{{ colors.base0C }}"
white = "{{ colors.base05 }}"

[colors.bright]
black = "{{ colors.base03 }}"
red = "{{ colors.base08 }}"
green = "{{ colors.base0B }}"
yellow = "{{ colors.base0A }}"
blue = "{{ colors.base0D }}"
magenta = "{{ colors.base0E }}"
cyan = "{{ colors.base0C }}"
white = "{{ colors.base07 }}""##;

    let result = render_template_string(template, &colors).unwrap();

    // Verify key color mappings
    assert!(result.contains("background = \"#1e1e2e\""));
    assert!(result.contains("foreground = \"#cdd6f4\""));
    assert!(result.contains("red = \"#f38ba8\""));
    assert!(result.contains("green = \"#a6e3a1\""));
    assert!(result.contains("blue = \"#89b4fa\""));
}

// Integration tests for actual template files
#[test]
fn test_render_base16_alacritty_template_file() {
    let template_path = std::path::Path::new("templates/base16/alacritty.toml.vogix");
    if !template_path.exists() {
        // Skip if templates not present (e.g., in CI without full checkout)
        return;
    }

    let colors = sample_colors();
    let result = render_template(template_path, &colors).unwrap();

    // Verify the template renders correctly
    assert!(result.contains("background = \"#1e1e2e\""));
    assert!(result.contains("foreground = \"#cdd6f4\""));
    assert!(result.contains("[colors.primary]"));
    assert!(result.contains("[colors.normal]"));
    assert!(result.contains("[colors.bright]"));
}

fn sample_vogix16_colors() -> HashMap<String, String> {
    let mut colors = HashMap::new();
    // Monochromatic
    colors.insert("background".to_string(), "#262626".to_string());
    colors.insert("background_surface".to_string(), "#333333".to_string());
    colors.insert("background_selection".to_string(), "#4d4d4d".to_string());
    colors.insert("foreground_comment".to_string(), "#666666".to_string());
    colors.insert("foreground_border".to_string(), "#808080".to_string());
    colors.insert("foreground_text".to_string(), "#cccccc".to_string());
    colors.insert("foreground_heading".to_string(), "#e6e6e6".to_string());
    colors.insert("foreground_bright".to_string(), "#ffffff".to_string());
    // Functional
    colors.insert("danger".to_string(), "#e06c75".to_string());
    colors.insert("warning".to_string(), "#e5c07b".to_string());
    colors.insert("notice".to_string(), "#d19a66".to_string());
    colors.insert("success".to_string(), "#98c379".to_string());
    colors.insert("active".to_string(), "#56b6c2".to_string());
    colors.insert("link".to_string(), "#61afef".to_string());
    colors.insert("highlight".to_string(), "#c678dd".to_string());
    colors.insert("special".to_string(), "#be5046".to_string());
    colors
}

#[test]
fn test_render_vogix16_alacritty_template_file() {
    let template_path = std::path::Path::new("templates/vogix16/alacritty.toml.vogix");
    if !template_path.exists() {
        return;
    }

    let colors = sample_vogix16_colors();
    let result = render_template(template_path, &colors).unwrap();

    // Verify semantic color mappings
    assert!(result.contains("background = \"#262626\""));
    assert!(result.contains("foreground = \"#cccccc\""));
    assert!(result.contains("red = \"#e06c75\"")); // danger
    assert!(result.contains("green = \"#98c379\"")); // success
}

fn sample_ansi16_colors() -> HashMap<String, String> {
    let mut colors = HashMap::new();
    colors.insert("background".to_string(), "#1d1f21".to_string());
    colors.insert("foreground".to_string(), "#c5c8c6".to_string());
    colors.insert("cursor_bg".to_string(), "#c5c8c6".to_string());
    colors.insert("cursor_fg".to_string(), "#1d1f21".to_string());
    colors.insert("selection_bg".to_string(), "#373b41".to_string());
    colors.insert("selection_fg".to_string(), "#c5c8c6".to_string());
    // Normal colors
    colors.insert("color00".to_string(), "#1d1f21".to_string());
    colors.insert("color01".to_string(), "#cc6666".to_string());
    colors.insert("color02".to_string(), "#b5bd68".to_string());
    colors.insert("color03".to_string(), "#f0c674".to_string());
    colors.insert("color04".to_string(), "#81a2be".to_string());
    colors.insert("color05".to_string(), "#b294bb".to_string());
    colors.insert("color06".to_string(), "#8abeb7".to_string());
    colors.insert("color07".to_string(), "#c5c8c6".to_string());
    // Bright colors
    colors.insert("color08".to_string(), "#969896".to_string());
    colors.insert("color09".to_string(), "#cc6666".to_string());
    colors.insert("color10".to_string(), "#b5bd68".to_string());
    colors.insert("color11".to_string(), "#f0c674".to_string());
    colors.insert("color12".to_string(), "#81a2be".to_string());
    colors.insert("color13".to_string(), "#b294bb".to_string());
    colors.insert("color14".to_string(), "#8abeb7".to_string());
    colors.insert("color15".to_string(), "#ffffff".to_string());
    colors
}

#[test]
fn test_render_ansi16_alacritty_template_file() {
    let template_path = std::path::Path::new("templates/ansi16/alacritty.toml.vogix");
    if !template_path.exists() {
        return;
    }

    let colors = sample_ansi16_colors();
    let result = render_template(template_path, &colors).unwrap();

    // Verify ANSI color mappings
    assert!(result.contains("background = \"#1d1f21\""));
    assert!(result.contains("foreground = \"#c5c8c6\""));
    assert!(result.contains("red = \"#cc6666\"")); // color01
    assert!(result.contains("green = \"#b5bd68\"")); // color02
}

#[test]
fn test_hex_to_rgb_filter() {
    let mut colors = HashMap::new();
    colors.insert("red".to_string(), "#FF5733".to_string());

    let template = "{{ colors.red | hex_to_rgb }}";
    let result = render_template_string(template, &colors).unwrap();

    assert_eq!(result, "0xFF,0x57,0x33");
}

#[test]
fn test_strip_hash_filter() {
    let mut colors = HashMap::new();
    colors.insert("blue".to_string(), "#1e90ff".to_string());

    let template = "{{ colors.blue | strip_hash }}";
    let result = render_template_string(template, &colors).unwrap();

    assert_eq!(result, "1e90ff");
}

#[test]
fn test_hex_to_rgb_filter_lowercase() {
    let mut colors = HashMap::new();
    colors.insert("color".to_string(), "#abcdef".to_string());

    let template = "{{ colors.color | hex_to_rgb }}";
    let result = render_template_string(template, &colors).unwrap();

    assert_eq!(result, "0xab,0xcd,0xef");
}
