# Vogix

> Functional colors for minimalist minds.

A minimalist design system that focuses on functional color usage. Vogix16 uses a carefully defined color palette where colors are primarily reserved for functional elements like status indicators, interactive controls, and system states.

![Vogix Theme Visualization](./vogix-theme-visual.svg)

## Philosophy

Vogix follows a "less is more" approach to design:

- Colors are used intentionally and only where they provide functional value
- Interface surfaces use a monochromatic color scale (which may be any color family, not just gray)
- True distinct colors are reserved for elements that benefit from clear visual distinction
- Dark and light variants maintain the same semantic color meanings

## Vogix16 Definition

Vogix16 is inspired by Base16, but with key differences:

### Base Colors (Monochromatic UI Foundation)
- **base00**: Background - Primary surface color (darkest in dark mode, lightest in light mode)
- **base01**: Alternative Surfaces - Secondary panels, cards, subtle containers
- **base02**: Subtle Highlights - Hover states, inactive selections, subtle differentiators
- **base03**: Muted Elements - Secondary information, disabled content, placeholders
- **base04**: Borders & Dividers - Separators, outlines, structural elements
- **base05**: Body Text - Primary content text and interface elements
- **base06**: Emphasized Content - Headings, highlighted content, important text
- **base07**: High Contrast Elements - Highest visibility elements (lightest in dark mode, darkest in light mode)

### Functional Colors (Semantic Purpose Colors)
- **base08**: Error/Danger - Error states, destructive actions, critical alerts
- **base09**: Warning/Caution - Warning indicators, important notifications, cautionary elements
- **base0A**: Notice/Attention - Status notifications, announcements, noteworthy information
- **base0B**: Success/Confirmed - Success states, completed actions, positive indicators
- **base0C**: Active/Current - Current selection, active element, focused content
- **base0D**: Information/Interactive - Clickable elements, links, primary actions, informational content
- **base0E**: Focus/Highlight - Focus indicators, highlighted content, secondary actions
- **base0F**: Special States - System messages, specialized indicators, tertiary elements

### Key Differences from Base16

1. **Monochromatic Base**: The base colors (base00-base07) form a monochromatic scale but aren't limited to grayscale. They can be any color family (green, blue, sepia, etc.), as long as they form a cohesive progression from darkest to lightest (or vice versa for light themes).

2. **Dark and Light Variants**: Themes have both dark and light variants. In dark variants, base00 is the darkest color and base07 is the lightest. In light variants, this is reversed: base00 is the lightest and base07 is the darkest.

3. **Strict Functional Color Usage**: Colors are assigned based on semantic function rather than aesthetics. Error states are always represented by base08 (red tones), warnings by base09 (orange/amber tones), etc., ensuring consistent meaning across all interfaces.

## Creating Themes

Themes in Vogix are defined with 16 colors:

### Dark Theme Example (Blue-based)

```
# Blue monochromatic scale from dark to light
base00 = "#0a1721" # Darkest blue-black (background)
base01 = "#112636" # Very dark blue
base02 = "#1e3a54" # Dark blue
base03 = "#335a7c" # Medium-dark blue
base04 = "#5382a8" # Medium blue
base05 = "#7ba9d0" # Medium-light blue
base06 = "#a8cde9" # Light blue
base07 = "#deeef8" # Very light blue (text)

# Functional colors
base08 = "#e55a5a" # Error - bright red
base09 = "#e5995a" # Warning - orange
base0A = "#e5d15a" # Notice - yellow
base0B = "#5ae55a" # Success - green
base0C = "#5ae5e5" # Selection - cyan
base0D = "#5a9de5" # Information - blue
base0E = "#a85ae5" # Focus - purple
base0F = "#e55ab3" # Special - pink
```

### Light Theme Example (Same theme family)

```
# Blue monochromatic scale from light to dark (inverted)
base00 = "#f5faff" # Very light blue-white (background)
base01 = "#deeef8" # Very light blue
base02 = "#a8cde9" # Light blue
base03 = "#7ba9d0" # Medium-light blue
base04 = "#5382a8" # Medium blue
base05 = "#335a7c" # Medium-dark blue 
base06 = "#1e3a54" # Dark blue
base07 = "#0a1721" # Darkest blue-black (text)

# Functional colors (adjusted for light backgrounds)
base08 = "#d12f2f" # Error - darker red
base09 = "#cb7832" # Warning - darker orange
base0A = "#b9a431" # Notice - darker yellow
base0B = "#2a8c2a" # Success - darker green
base0C = "#2a8c8c" # Selection - darker cyan
base0D = "#2970b6" # Information - darker blue
base0E = "#7436b6" # Focus - darker purple
base0F = "#b6367a" # Special - darker pink
```

## License

Creative Commons Attribution-NonCommercial-ShareAlike (CC BY-NC-SA)

This work is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/).
