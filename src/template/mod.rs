//! Template rendering for theme configurations
//!
//! Uses Tera template engine with custom filters for color manipulation.
//!
//! # Module Structure
//! - `filters`: Custom Tera filters (hex_to_rgb, strip_hash)
//! - `render`: Core rendering functions
//!
//! # Template Syntax
//! Templates use Jinja2/Tera syntax:
//! ```text
//! background = "{{ colors.base00 }}"
//! foreground = "{{ colors.base05 }}"
//! rgb_color = "{{ colors.red | hex_to_rgb }}"
//! ```

pub mod filters;
mod render;
#[cfg(test)]
mod tests;

// Re-export public API
pub use render::render_template;

// Used by tests
#[cfg(test)]
pub use render::render_template_string;
