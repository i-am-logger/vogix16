{ lib }:

{
  # fzf doesn't use a traditional config file - colors are set via FZF_DEFAULT_OPTS
  # We'll generate a shell script that exports the variable
  configFile = "fzf-colors.sh";

  # Generator function to create fzf color configuration from semantic colors
  # Returns shell script that exports FZF_DEFAULT_OPTS with color settings
  #
  # fzf color format: --color=NAME:VALUE
  # VALUE can be: hex colors (#RRGGBB), ANSI colors (0-255), or color names
  #
  # Vogix16 Philosophy for fzf:
  # - Monochromatic for UI structure (backgrounds, borders, normal text)
  # - Semantic colors ONLY for:
  #   - Matched text highlights (what user searched for)
  #   - Current selection pointer (where user is)
  #   - Status indicators that convey information
  generate = colors: ''
    # Vogix16 theme for fzf
    # Source this file in your shell rc to apply colors
    # For bash/zsh: source ~/.config/fzf/fzf-colors.sh
    # For fish: source ~/.config/fzf/fzf-colors.sh

    export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS"\
    " --color=fg:${colors.foreground-text}"\
    " --color=fg+:${colors.foreground-bright}"\
    " --color=bg:${colors.background}"\
    " --color=bg+:${colors.background-selection}"\
    " --color=hl:${colors.active}"\
    " --color=hl+:${colors.active}"\
    " --color=info:${colors.foreground-comment}"\
    " --color=prompt:${colors.foreground-text}"\
    " --color=pointer:${colors.active}"\
    " --color=marker:${colors.active}"\
    " --color=spinner:${colors.foreground-comment}"\
    " --color=header:${colors.foreground-heading}"\
    " --color=border:${colors.foreground-border}"\
    " --color=label:${colors.foreground-heading}"\
    " --color=query:${colors.foreground-bright}"\
    " --color=gutter:${colors.background}"
  '';

  # No reload method - shell needs to be reloaded for env var changes
  # Users can source the file or restart their shell
}
