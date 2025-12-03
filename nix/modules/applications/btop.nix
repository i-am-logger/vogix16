{ lib }:

# Helper function to generate btop theme from semantic colors
# Returns btop theme file content
colors: ''
  # Vogix16 theme for btop
  # Main interface - monochromatic base
  theme[main_bg]="${colors.background}"
  theme[main_fg]="${colors.foreground-text}"
  theme[title]="${colors.foreground-heading}"
  theme[hi_fg]="${colors.foreground-bright}"
  theme[selected_bg]="${colors.background-selection}"
  theme[selected_fg]="${colors.active}"
  theme[inactive_fg]="${colors.foreground-comment}"
  theme[proc_misc]="${colors.foreground-text}"

  # Box borders - all same color, no semantic meaning
  theme[cpu_box]="${colors.foreground-border}"
  theme[mem_box]="${colors.foreground-border}"
  theme[net_box]="${colors.foreground-border}"
  theme[proc_box]="${colors.foreground-border}"
  theme[div_line]="${colors.foreground-border}"

  # Graphs - monochromatic base
  theme[graph_text]="${colors.foreground-text}"
  theme[meter_bg]="${colors.background-surface}"

  # All gradients: semantic progression (low → warning → danger)
  # These indicate resource utilization levels - user needs to know

  # Temperature: low → moderate → high
  theme[temp_start]="${colors.foreground-comment}"
  theme[temp_mid]="${colors.warning}"
  theme[temp_end]="${colors.danger}"

  # CPU usage: low → moderate → high
  theme[cpu_start]="${colors.foreground-comment}"
  theme[cpu_mid]="${colors.warning}"
  theme[cpu_end]="${colors.danger}"

  # Memory: used - low → moderate → high
  theme[used_start]="${colors.foreground-comment}"
  theme[used_mid]="${colors.warning}"
  theme[used_end]="${colors.danger}"

  # Memory: available - low → moderate → high (low available = bad, high available = good)
  theme[available_start]="${colors.danger}"
  theme[available_mid]="${colors.warning}"
  theme[available_end]="${colors.foreground-comment}"

  # Memory: free - low → moderate → high (low free = bad, high free = good)
  theme[free_start]="${colors.danger}"
  theme[free_mid]="${colors.warning}"
  theme[free_end]="${colors.foreground-comment}"

  # Memory: cached - low → moderate → high
  theme[cached_start]="${colors.foreground-comment}"
  theme[cached_mid]="${colors.warning}"
  theme[cached_end]="${colors.danger}"

  # Network: download - low → moderate → high
  theme[download_start]="${colors.foreground-comment}"
  theme[download_mid]="${colors.warning}"
  theme[download_end]="${colors.danger}"

  # Network: upload - low → moderate → high
  theme[upload_start]="${colors.foreground-comment}"
  theme[upload_mid]="${colors.warning}"
  theme[upload_end]="${colors.danger}"

  # Process usage: low → moderate → high
  theme[process_start]="${colors.foreground-comment}"
  theme[process_mid]="${colors.warning}"
  theme[process_end]="${colors.danger}"
''
