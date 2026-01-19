{ pkgs, ... }:

{
  home.username = "vogix";
  home.homeDirectory = "/home/vogix";
  home.stateVersion = "24.11";

  # Enable vogix
  programs.vogix = {
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
      color_theme = "vogix"; # Use vogix theme (managed by vogix)
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
      echo "=== Vogix Test VM ==="
      vogix status
      echo ""
      echo "Available commands:"
      echo "  vogix status          - Show current theme/variant/scheme"
      echo "  vogix list            - List all themes"
      echo "  vogix list -s base16  - List base16 themes"
      echo "  vogix list -s base24  - List base24 themes"
      echo "  vogix list -s ansi16  - List ansi16 themes"
      echo "  vogix -t <theme>      - Switch theme"
      echo "  vogix -v dark|light   - Switch variant"
      echo "  vogix -v darker       - Navigate to darker variant"
      echo "  vogix -v lighter      - Navigate to lighter variant"
      echo "  vogix -s <scheme>     - Switch scheme (vogix16/base16/base24/ansi16)"
      echo "  vogix -s base16 -t dracula -v dark  - Combined flags"
      echo ""
      echo "Shell commands:"
      echo "  reload-colors    - Reload shell colors after theme change"
      echo "  colors           - Show ANSI color palette"
      echo "  ls --color       - Test directory colors"
      echo "  shutdown         - Power off VM"
      echo ""
    '';
  };

  # Install fastfetch for color testing
  home.packages = with pkgs; [
    fastfetch
  ];
}
