{ config, pkgs, ... }:

{
  home.username = "vogix";
  home.homeDirectory = "/home/vogix";
  home.stateVersion = "24.11";

  # Enable vogix16
  programs.vogix16 = {
    enable = true;
    defaultTheme = "aikido";
    defaultVariant = "dark";
    # Apps are auto-detected from enabled programs (alacritty, btop, bash, console)
    # You can disable individual apps with: alacritty.enable = false; etc.
    enableDaemon = false; # Disabled for tests - daemon requires home-manager/.config watch path

    # Themes are auto-discovered from ../../themes directory
    # No need to list them manually!
  };

  # Configure alacritty for testing
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding.x = 10;
        padding.y = 10;
      };
      font = {
        size = 12;
      };
      env = {
        TERM = "alacritty"; # Ensure true color support
      };
    };
  };

  # Configure btop for testing
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "vogix"; # Use vogix theme (managed by vogix16)
      theme_background = false;
      update_ms = 100; # Refresh every 100ms for dynamic demo display
    };
  };

  # Enable git for convenience
  programs.git = {
    enable = true;
    settings = {
      user.name = "Vogix Test";
      user.email = "test@vogix.local";
    };
  };

  # Enable bash (vogix module will auto-configure shell colors)
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      v = "vogix";
      reload-colors = "source ~/.config/shell-colors/colors.sh && source ~/.config/ls-colors/dircolors && echo 'Colors reloaded!'";
      colors = "echo -e '\\033[0;30m Black \\033[0;31m Red \\033[0;32m Green \\033[0;33m Yellow \\033[0;34m Blue \\033[0;35m Magenta \\033[0;36m Cyan \\033[0;37m White \\033[0m' && echo -e '\\033[1;30m Bright Black \\033[1;31m Bright Red \\033[1;32m Bright Green \\033[1;33m Bright Yellow \\033[1;34m Bright Blue \\033[1;35m Bright Magenta \\033[1;36m Bright Cyan \\033[1;37m Bright White \\033[0m'";
      shutdown = "sudo systemctl poweroff";
    };
    sessionVariables = {
      COLORTERM = "truecolor"; # Enable true color support
    };
    initExtra = ''
      # Show welcome message with theme info
      echo ""
      echo "=== Vogix16 Test VM ==="
      echo "Current theme: $(vogix status | grep 'Current theme:' | cut -d: -f2)"
      echo ""
      echo "Available commands:"
      echo "  vogix list       - List all themes"
      echo "  vogix theme X    - Switch to theme X"
      echo "  vogix switch     - Toggle between dark/light"
      echo "  vogix-demo       - Run demo (for OBS recording)"
      echo "  reload-colors      - Reload shell colors after theme change"
      echo "  colors             - Show ANSI color palette"
      echo "  ls --color         - Test directory colors"
      echo "  shutdown           - Power off VM"
      echo ""
      echo "NOTE: After changing theme/variant, run 'reload-colors' or start new shell (exec bash)"
      echo ""
    '';
  };

  # Install fastfetch for color testing
  home.packages = with pkgs; [
    fastfetch
  ];
}
