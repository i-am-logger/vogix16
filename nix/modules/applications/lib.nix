{ lib }:

# Shared utility functions for Vogix16 application modules
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

  # Convert hex color to decimal RGB components
  # Input: "#RRGGBB"
  # Output: { r = 255; g = 87; b = 51; }
  #
  # Example:
  #   hexToRgbDecimal "#FF5733" => { r = 255; g = 87; b = 51; }
  hexToRgbDecimal = hex:
    let
      clean = lib.removePrefix "#" hex;
      hexToDecimal = hexStr:
        let
          hexDigits = {
            "0" = 0;
            "1" = 1;
            "2" = 2;
            "3" = 3;
            "4" = 4;
            "5" = 5;
            "6" = 6;
            "7" = 7;
            "8" = 8;
            "9" = 9;
            "A" = 10;
            "B" = 11;
            "C" = 12;
            "D" = 13;
            "E" = 14;
            "F" = 15;
            "a" = 10;
            "b" = 11;
            "c" = 12;
            "d" = 13;
            "e" = 14;
            "f" = 15;
          };
          upper = builtins.substring 0 1 hexStr;
          lower = builtins.substring 1 1 hexStr;
        in
        (hexDigits.${upper} * 16) + hexDigits.${lower};
      r = hexToDecimal (builtins.substring 0 2 clean);
      g = hexToDecimal (builtins.substring 2 2 clean);
      b = hexToDecimal (builtins.substring 4 2 clean);
    in
    {
      inherit r g b;
    };
}
