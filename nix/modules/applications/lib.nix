{ lib }:

# Shared utility functions for Vogix application modules
# These functions help with common color format conversions
#
# Note: All colors from themes should come with # prefix already.
# These functions handle removal of # when needed for specific formats.

{
  # Convert hex color to RGB format used by ripgrep and other tools
  # Input: "#RRGGBB"
  # Output: "0xRR,0xGG,0xBB"
  #
  # Example:
  #   hexToRgb "#FF5733" => "0xFF,0x57,0x33"
  hexToRgb = hex:
    let
      # Remove # prefix
      clean = lib.removePrefix "#" hex;
      # Extract RGB components
      r = builtins.substring 0 2 clean;
      g = builtins.substring 2 2 clean;
      b = builtins.substring 4 2 clean;
    in
    "0x${r},0x${g},0x${b}";

  # Remove # prefix from hex color (for formats that don't use it)
  # Input: "#RRGGBB"
  # Output: "RRGGBB"
  #
  # Example:
  #   stripHash "#FF5733" => "FF5733"
  stripHash = color: lib.removePrefix "#" color;
}
