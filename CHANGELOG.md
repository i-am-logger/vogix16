# Changelog

All notable changes to Vogix16 will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub Actions CI/CD workflows
- Comprehensive CONTRIBUTING.md with development guidelines
- Automated release process with release-please

### Changed
- Updated all documentation to reflect actual Nix-based architecture
- Corrected README examples to show proper home-manager integration
- Binary name consistently referred to as `vogix` throughout docs

### Removed
- Obsolete ARCHITECTURE-REDESIGN.md documentation

## [0.5.0] - 2024-XX-XX

### Added
- Renamed binary from `vogix16` to `vogix` for consistency
- Auto-toggle `switch` command (no arguments needed)
- Per-app theme and variant override support
- Comprehensive theme library with 19 themes
- Console (TTY) theme support with setvtrgb integration

### Changed
- Refactored architecture: Nix generates all theme configs at build time
- CLI now only manages symlinks, not config generation
- Improved symlink architecture for instant theme switching
- Enhanced state persistence

## [0.4.0] - 2024-XX-XX

### Added
- Comprehensive automated testing suite (16 test scenarios)
- VM-based integration testing
- Theme validation at build time
- Semantic color API for application modules

### Changed
- Improved error handling across all components
- Enhanced reload mechanisms with multiple methods
- Better symlink management

## [0.3.0] - 2024-XX-XX

### Added
- Auto-discovery of themes from `themes/` directory
- Auto-discovery of application generators
- Systemd service for runtime directory setup
- Support for per-app configuration overrides

### Changed
- Migrated from runtime template processing to build-time generation
- Simplified CLI to focus on symlink management

## [0.2.0] - 2024-XX-XX

### Added
- Multiple application reload methods (touch, signal, command)
- Shell completions for all major shells
- State persistence for current theme/variant

### Changed
- Improved NixOS integration
- Enhanced home-manager module

## [0.1.0] - 2024-XX-XX

### Added
- Initial release
- Vogix16 design system with 16-color palette
- Basic theme switching functionality
- Dark and light variant support
- NixOS and home-manager integration
- Example themes (aikido, forest, matrix)
- CLI tool for runtime theme management
- Application reload mechanism
- Documentation for design system, architecture, and usage

[Unreleased]: https://github.com/i-am-logger/vogix16/compare/v0.5.0...HEAD
[0.5.0]: https://github.com/i-am-logger/vogix16/releases/tag/v0.5.0
[0.4.0]: https://github.com/i-am-logger/vogix16/releases/tag/v0.4.0
[0.3.0]: https://github.com/i-am-logger/vogix16/releases/tag/v0.3.0
[0.2.0]: https://github.com/i-am-logger/vogix16/releases/tag/v0.2.0
[0.1.0]: https://github.com/i-am-logger/vogix16/releases/tag/v0.1.0
