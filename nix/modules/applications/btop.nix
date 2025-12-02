{ lib }:

# Helper function to generate btop theme from semantic colors
# Returns btop theme file content
colors: ''
  # Vogix16 theme for btop
  theme[main_bg]="${colors.background}"
  theme[main_fg]="${colors.foreground-text}"
  theme[title]="${colors.foreground-heading}"
  theme[hi_fg]="${colors.foreground-bright}"
  theme[selected_bg]="${colors.background-selection}"
  theme[selected_fg]="${colors.active}"
  theme[inactive_fg]="${colors.foreground-comment}"
  theme[proc_misc]="${colors.foreground-text}"

  theme[cpu_box]="${colors.link}"
  theme[mem_box]="${colors.success}"
  theme[net_box]="${colors.notice}"
  theme[proc_box]="${colors.highlight}"
  theme[div_line]="${colors.foreground-border}"

  theme[graph_text]="${colors.foreground-text}"
  theme[meter_bg]="${colors.background-surface}"

  # Used resources: low (comment/subtle) → moderate (warning) → high (danger)
  theme[used_start]="${colors.foreground-comment}"
  theme[used_mid]="${colors.warning}"
  theme[used_end]="${colors.danger}"

  # Available resources: high (comment/subtle) → moderate (warning) → low (danger)
  theme[available_start]="${colors.foreground-comment}"
  theme[available_mid]="${colors.warning}"
  theme[available_end]="${colors.danger}"
''
