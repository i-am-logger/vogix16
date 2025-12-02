{ config, pkgs, lib, ... }:

{
  # VM configuration for testing vogix16
  imports = [ ];

  # Basic VM settings
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Minimal system configuration
  fileSystems."/" = {
    device = "/dev/vda";
    fsType = "ext4";
  };

  # Networking
  networking.hostName = "vogix16-test";
  networking.useDHCP = true;

  # Enable vogix16 NixOS module for console.colors integration
  # This will auto-detect theme settings from home-manager
  vogix16.enable = true;

  # Demo script as a package
  # Updated: 2025-12-01 - Added asciinema-agg for GIF conversion
  environment.systemPackages = with pkgs; [
    vim
    git
    alacritty
    btop
    tmux
    tree  # For showing directory structure in demo
    asciinema
    asciinema-agg  # For converting .cast to GIF

    # Demo script in PATH
    (pkgs.writeScriptBin "vogix-demo" (builtins.readFile ../../scripts/demo.sh))
  ];

  # Install fonts for agg
  fonts.packages = with pkgs; [
    dejavu_fonts
    liberation_ttf
    noto-fonts
    noto-fonts-color-emoji
  ];

  # Create test user
  users.users.vogix = {
    isNormalUser = true;
    home = "/home/vogix";
    description = "Vogix Test User";
    extraGroups = [ "wheel" ];
    password = "vogix"; # Simple password for testing
  };

  # Enable sudo without password for testing
  security.sudo.wheelNeedsPassword = false;

  # Auto-login for easier testing (only once)
  services.getty.autologinUser = "vogix";

  # Enable serial console getty (override test instrumentation)
  systemd.services."serial-getty@ttyS0".enable = lib.mkForce true;

  # Disable auto-restart of getty so exit will actually close the terminal
  systemd.services."getty@tty1" = {
    serviceConfig.Restart = lib.mkForce "no";
    serviceConfig.TTYVHangup = lib.mkForce "yes";
    serviceConfig.TTYReset = lib.mkForce "yes";
  };
  systemd.services."serial-getty@ttyS0" = {
    serviceConfig.Restart = lib.mkForce "no";
    serviceConfig.TTYVHangup = lib.mkForce "yes";
    serviceConfig.TTYReset = lib.mkForce "yes";
  };

  # System state version
  system.stateVersion = "24.11";

  # Enable serial console for terminal mode
  boot.kernelParams = [ "console=tty1" "console=ttyS0" ];

  # VM-specific settings
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 2048;
      cores = 2;
      graphics = true;
      resolution = { x = 1920; y = 1080; };  # HD resolution

      # Use default shared directory (usually $TMPDIR/xchg on host -> /tmp/shared in VM)

      qemu.options = [
        "-vga virtio"  # Better graphics with virtio
        "-display gtk,zoom-to-fit=on"  # GTK display with auto-zoom
      ];
    };
  };
}
