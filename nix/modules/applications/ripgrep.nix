{ appLib, ... }:

{
  # Config file path relative to ~/.config/ripgrep/
  configFile = "ripgreprc";

  # Generators for each color scheme
  # Ripgrep color format: --colors='type:attribute:value'
  # - type: path, line, column, match, highlight
  # - attribute: fg, bg, style
  # - value: RGB hex (0xRR,0xGG,0xBB) or color name
  schemes = {
    # Vogix16: semantic color names
    vogix16 = colors: ''
      # Vogix16 theme for ripgrep
      --colors=path:fg:${appLib.hexToRgb colors.foreground-text}
      --colors=line:fg:${appLib.hexToRgb colors.foreground-comment}
      --colors=line:style:bold
      --colors=column:fg:${appLib.hexToRgb colors.foreground-comment}
      --colors=match:fg:${appLib.hexToRgb colors.active}
      --colors=match:style:bold
      --colors=highlight:fg:${appLib.hexToRgb colors.highlight}
    '';

    # Base16: raw base00-base0F colors
    base16 = colors: ''
      # Base16 theme for ripgrep
      --colors=path:fg:${appLib.hexToRgb colors.base05}
      --colors=line:fg:${appLib.hexToRgb colors.base03}
      --colors=line:style:bold
      --colors=column:fg:${appLib.hexToRgb colors.base03}
      --colors=match:fg:${appLib.hexToRgb colors.base0D}
      --colors=match:style:bold
      --colors=highlight:fg:${appLib.hexToRgb colors.base0E}
    '';

    # Base24: base00-base17 with true bright colors
    base24 = colors: ''
      # Base24 theme for ripgrep
      --colors=path:fg:${appLib.hexToRgb colors.base05}
      --colors=line:fg:${appLib.hexToRgb colors.base03}
      --colors=line:style:bold
      --colors=column:fg:${appLib.hexToRgb colors.base03}
      --colors=match:fg:${appLib.hexToRgb colors.base16}
      --colors=match:style:bold
      --colors=highlight:fg:${appLib.hexToRgb colors.base17}
    '';

    # ANSI16: direct terminal colors
    ansi16 = colors: ''
      # ANSI16 theme for ripgrep
      --colors=path:fg:${appLib.hexToRgb colors.foreground}
      --colors=line:fg:${appLib.hexToRgb colors.color08}
      --colors=line:style:bold
      --colors=column:fg:${appLib.hexToRgb colors.color08}
      --colors=match:fg:${appLib.hexToRgb colors.color12}
      --colors=match:style:bold
      --colors=highlight:fg:${appLib.hexToRgb colors.color13}
    '';
  };
}
