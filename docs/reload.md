# Reload Mechanism

When a theme or variant is switched, applications need to be notified to reload their configurations. The Vogix16 system uses a flexible, configuration-driven approach to handle this.

## Configuration-Based Reload

Instead of hardcoding application reload methods, each application defines its reload method in its theme configuration:

```nix
# Example reload configurations
{
  name = "alacritty";
  reload = {
    type = "dbus";
    interface = "org.alacritty.Window";
    method = "Reload";
  };
}

{
  name = "waybar";
  reload = {
    type = "signal";
    signal = "SIGUSR1";
  };
}

{
  name = "sway";
  reload = {
    type = "ipc";
    command = "reload";
  };
}
```

## Supported Reload Methods

The system supports multiple reload mechanisms:

1. **DBus Methods**: For applications with DBus interfaces
2. **Unix Signals**: For applications that reload on signals like SIGUSR1
3. **IPC Commands**: For applications with custom IPC protocols
4. **Socket Commands**: For applications that accept commands via sockets
5. **Custom Shell Commands**: For applications requiring custom reload commands
6. **Filesystem Watches**: For applications that automatically detect changes

## Implementation

The reload system:

1. Reads the reload configuration for each themed application
2. Checks if the application is running
3. Executes the appropriate reload method
4. Handles failures gracefully with fallbacks and error reporting

Adding support for a new application only requires adding its reload configuration, not modifying the code.

## Fallback Mechanisms

If an application doesn't support runtime reload:

1. The system will note that the configuration has changed
2. The application will use the new theme on next launch
3. Optionally, the user can be notified that manual restart is required

