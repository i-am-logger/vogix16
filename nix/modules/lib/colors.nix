# Color utilities
#
# Shared color manipulation functions
{ lib }:

{
  # Calculate luminance from hex color (sRGB to linear, then ITU-R BT.709)
  # Used for sorting variants by brightness
  hexToLuminance =
    hex:
    let
      h = lib.removePrefix "#" hex;
      r = (lib.trivial.fromHexString (builtins.substring 0 2 h)) / 255.0;
      g = (lib.trivial.fromHexString (builtins.substring 2 2 h)) / 255.0;
      b = (lib.trivial.fromHexString (builtins.substring 4 2 h)) / 255.0;
    in
    0.2126 * r + 0.7152 * g + 0.0722 * b;
}
