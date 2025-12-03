{ lib }:

# Helper function to generate ripgrep color configuration from semantic colors
# Returns ripgrep config file content (for use in ~/.ripgreprc or RIPGREP_CONFIG_PATH)
#
# Ripgrep color format: --colors='type:attribute:value'
# - type: path, line, column, match, highlight
# - attribute: fg, bg, style
# - value: RGB hex (0xRR,0xGG,0xBB) or color name
#
# Vogix16 Philosophy for ripgrep:
# - Monochromatic for structure (path, line, column)
# - Semantic colors ONLY for matches/highlights (what user needs to find)
colors: let
  # Helper to convert hex color to ripgrep RGB format
  # Input: "#RRGGBB" -> Output: "0xRR,0xGG,0xBB"
  hexToRgb = hex: let
    # Remove # prefix if present
    clean = lib.removePrefix "#" hex;
    # Extract RGB components
    r = builtins.substring 0 2 clean;
    g = builtins.substring 2 2 clean;
    b = builtins.substring 4 2 clean;
  in "0x${r},0x${g},0x${b}";

in ''
  # Vogix16 theme for ripgrep
  # Minimalist design: monochromatic structure, semantic highlights

  # Structure elements - monochromatic (no semantic meaning)
  # Path: file names and paths shown in output
  --colors=path:fg:${hexToRgb colors.foreground-text}

  # Line numbers: structural information
  --colors=line:fg:${hexToRgb colors.foreground-comment}
  --colors=line:style:bold

  # Column numbers: structural information
  --colors=column:fg:${hexToRgb colors.foreground-comment}

  # Semantic elements - functional colors (information user needs)
  # Match: the actual search match - PRIMARY semantic element
  # User NEEDS to see what matched their search query
  --colors=match:fg:${hexToRgb colors.active}
  --colors=match:style:bold

  # Highlight: context matches or secondary highlights
  # Used for additional context around matches
  --colors=highlight:fg:${hexToRgb colors.highlight}
''
