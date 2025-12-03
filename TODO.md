# Vogix16 App-Support Implementation Tracker

## Vogix16 Design Guidelines

### Core Principles
**"Functional colors for minimalist minds"**

- Colors used intentionally for functional value only
- Interface surfaces use monochromatic scales
- True distinct colors reserved for functional elements
- Dark and light variants maintain semantic consistency

### Color Usage Framework

#### Monochromatic Base (base00-base07) - UI Structure
- **base00** (`background`): Main background
- **base01** (`background-surface`): Alternative surfaces, panels
- **base02** (`background-selection`): Selection background, hover states
- **base03** (`foreground-comment`): Comments, disabled content, subtle text
- **base04** (`foreground-border`): Borders, dividers, structural elements
- **base05** (`foreground-text`): Main text, primary content
- **base06** (`foreground-heading`): Headings, emphasized content
- **base07** (`foreground-bright`): High contrast elements

#### Functional Colors (base08-base0F) - Semantic Meaning ONLY
- **base08** (`danger`): Errors, destructive actions, critical alerts, deletions
- **base09** (`warning`): Warnings, high resource usage, caution indicators
- **base0A** (`notice`): Notices, modifications, pending states, numbers
- **base0B** (`success`): Success states, additions, positive indicators, running status
- **base0C** (`active`): Current selection, active element, focused content, playing state
- **base0D** (`link`): Links, clickable elements, informational content, functions
- **base0E** (`highlight`): Focus indicators, highlighted content, tags, important items
- **base0F** (`special`): Special states, system messages, tertiary elements

### Decision Framework

**Ask: "Does this color convey information the user needs to know?"**

**YES - Use Functional Colors:**
- Error states, warnings, success confirmations
- Resource utilization levels (CPU at 90% vs 10%)
- Temperature/status gradients (cool → warm → hot)
- Active/selected/focused items
- Added/removed/modified content (git diffs, file changes)
- Important notifications or alerts

**NO - Use Monochromatic Base:**
- UI borders, dividers, structural elements
- File type differentiation (unless indicating errors)
- Syntax highlighting for aesthetics
- Category labels without status meaning
- Navigation elements
- Decorative accents

### Implementation Checklist Per App

**Git Workflow: Each app gets its own branch, commit, and PR**

1. [ ] Create branch: `git checkout -b feat/app-<app-name>`
2. [ ] Clone repo to `~/Code/github/tmp/<app-name>` (if not exists)
3. [ ] Research source code for latest theming configuration options
4. [ ] Identify semantic vs. decorative color usage
5. [ ] Design theme following Vogix16 principles
6. [ ] Create `nix/modules/applications/<app>.nix`
7. [ ] Add home-manager integration (if needed)
8. [ ] Test configuration
9. [ ] Commit with message: `feat(app): add <app-name> theme support`
10. [ ] Push branch: `git push -u origin feat/app-<app-name>`
11. [ ] Create PR with description of theme design decisions
12. [ ] Mark complete in TODO.md

---

## TIER 1: Essential CLI/TUI Tools (Most Popular)

### btop - System Monitor (#52)
- [ ] Clone repo & research
- [ ] Design theme (semantic: CPU/memory/temp gradients; mono: borders)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGHEST - System monitor with resource utilization (semantic colors required)

### ripgrep - Grep Alternative (#35)
- [ ] Clone repo & research
- [ ] Design theme (semantic: match highlights; mono: structure)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGHEST - Essential search tool

### bat - Cat with Syntax Highlighting (#65)
- [ ] Clone repo & research
- [ ] Design theme (.tmTheme format; minimize syntax colors, semantic for diffs)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGHEST - Commonly used file viewer

### eza - Modern ls Replacement (#56)
- [ ] Clone repo & research
- [ ] Design theme (mono: file types; semantic: permissions/errors only)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGHEST - Essential file listing tool

### fd - Find Alternative (#36)
- [ ] Clone repo & research
- [ ] Design theme (minimal colors needed)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGH - Essential search tool

### fzf - Fuzzy Finder (#38)
- [ ] Clone repo & research
- [ ] Design theme (semantic: selection/match; mono: structure)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGHEST - Critical workflow tool

### gitui - Git TUI (#68)
- [ ] Clone repo & research
- [ ] Design theme (semantic: add/remove/modify; mono: structure)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGHEST - Git interface with semantic diffs

### delta - Git Diff Viewer (#45)
- [ ] Clone repo & research
- [ ] Design theme (semantic: add/remove/modify; mono: line numbers)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGHEST - Essential git tool

### lazygit - Git TUI (#46)
- [ ] Clone repo & research
- [ ] Design theme (semantic: git status; mono: structure)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGHEST - Popular git interface

### tmux - Terminal Multiplexer (#40)
- [ ] Clone repo & research
- [ ] Design theme (mono: status bar; semantic: activity/alerts only)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGHEST - Core terminal tool

### starship - Shell Prompt (#39)
- [ ] Clone repo & research
- [ ] Design theme (TOML; semantic: git status/errors; mono: structure)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGHEST - Universal shell prompt

---

## TIER 2: Development Tools

### VSCode/VSCodium - Code Editor (#29)
- [ ] Clone repo & research
- [ ] Design theme (JSON; minimize syntax colors, semantic for errors/warnings)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGH - Popular code editor

### OpenCode - VSCodium Alternative (#93)
- [ ] Clone repo & research
- [ ] Design theme (likely uses VSCode theme format)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - Alternative to VSCode

### htop - Process Viewer (#53)
- [ ] Clone repo & research
- [ ] Design theme (semantic: resource usage; mono: structure)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGH - Process monitoring

### k9s - Kubernetes TUI (#63)
- [ ] Clone repo & research
- [ ] Design theme (YAML skin; semantic: pod status; mono: structure)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - DevOps tool

### kubecolor - Kubectl Colorizer (#64)
- [ ] Clone repo & research
- [ ] Design theme (YAML/ENV; semantic: resource status)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - DevOps tool

---

## TIER 3: Terminal File Managers

### yazi - Terminal File Manager (#51)
- [ ] Clone repo & research
- [ ] Design theme (mono: file types; semantic: selection/errors)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGH - Modern file manager

### ranger - Terminal File Manager (#50)
- [ ] Clone repo & research
- [ ] Design theme (mono: file types; semantic: selection)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - Popular file manager

### lf - Terminal File Manager (#47)
- [ ] Clone repo & research
- [ ] Design theme (mono: structure; semantic: selection)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - Lightweight file manager

### nnn - Terminal File Manager (#49)
- [ ] Clone repo & research
- [ ] Design theme (minimal colors)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - Minimal file manager

---

## TIER 4: Browsers & Communications

### Firefox - Web Browser (#54)
- [ ] Clone repo & research
- [ ] Design theme (userChrome.css; UI chrome only)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGH - Popular browser

### qutebrowser - Keyboard Browser (#55)
- [ ] Clone repo & research
- [ ] Design theme (Python config; minimal UI colors)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - Power user browser

### Discord/Vesktop - Chat Application (#43)
- [ ] Clone repo & research
- [ ] Design theme (CSS; semantic for status; mono for UI)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - Popular chat app

### Thunderbird - Email Client (#44)
- [ ] Clone repo & research
- [ ] Design theme (userChrome.css/config)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - Email client

---

## TIER 5: Music Players

### ncspot - Terminal Spotify (#59)
- [ ] Clone repo & research
- [ ] Design theme (TOML; semantic: playing/selection; mono: structure)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - Terminal music player

### spotify-player - Terminal Spotify (#61)
- [ ] Clone repo & research
- [ ] Design theme (TOML; semantic: status; mono: structure)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - Spotify client

### Spicetify - Spotify Desktop (#60)
- [ ] Clone repo & research
- [ ] Design theme (CSS/INI; semantic for controls)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - Spotify customization

### cmus - Terminal Music Player (#58)
- [ ] Clone repo & research
- [ ] Design theme (theme files; semantic: playing/status)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - Classic music player

---

## TIER 6: Productivity

### Obsidian - Note-taking (#76)
- [ ] Clone repo & research
- [ ] Design theme (CSS; minimal syntax colors, semantic for UI)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - Popular note-taking app

### Anki - Flashcards (#66)
- [ ] Clone repo & research
- [ ] Design theme (Qt + CSS; semantic: answer feedback)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Learning tool

### Notion - Productivity (#41)
- [ ] Clone repo & research (may be proprietary/limited)
- [ ] Design theme (if possible)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Proprietary app

---

## TIER 7: System UI Components

### swaylock - Screen Locker (#67)
- [ ] Clone repo & research
- [ ] Design theme (minimal; semantic for status indicators)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGH - Security component

### i3status-rust - Status Bar (#83)
- [ ] Clone repo & research
- [ ] Design theme (TOML; semantic: system status; mono: structure)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGH - Status bar component

### hyprpanel - Status Panel (#84)
- [ ] Clone repo & research
- [ ] Design theme (CSS/JSON; semantic: status; mono: structure)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - Hyprland component

### wob - Overlay Bar (#81)
- [ ] Clone repo & research
- [ ] Design theme (minimal INI; semantic: levels)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - Volume/brightness OSD

### avizo - OSD (#82)
- [ ] Clone repo & research
- [ ] Design theme (INI; semantic: volume/brightness levels)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - OSD component

### MangoHud - Gaming Overlay (#80)
- [ ] Clone repo & research
- [ ] Design theme (INI; semantic: FPS/resource usage; mono: structure)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Gaming tool

---

## TIER 8: Display Managers

### LightDM - Display Manager (#72)
- [ ] Clone repo & research
- [ ] Design theme (greeter-specific; mono UI)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - Login screen

### regreet - GTK Greeter (#87)
- [ ] Clone repo & research
- [ ] Design theme (GTK-based; mono UI)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - Greetd greeter

---

## TIER 9: Wallpaper Daemons

### hyprpaper - Wallpaper Daemon (#85)
- [ ] Clone repo & research
- [ ] Design theme (config-based; minimal theming needed)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Wallpaper management

### wpaperd - Wallpaper Daemon (#86)
- [ ] Clone repo & research
- [ ] Design theme (TOML; minimal theming needed)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Wallpaper management

---

## TIER 10: Image Viewers

### feh - X11 Image Viewer (#73)
- [ ] Clone repo & research
- [ ] Design theme (Xresources; minimal UI colors)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Image viewer

### sxiv - Simple Image Viewer (#74)
- [ ] Clone repo & research
- [ ] Design theme (Xresources; minimal UI)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Image viewer

### Eye of GNOME (eog) - Image Viewer (#75)
- [ ] Clone repo & research
- [ ] Design theme (GTK theme-based)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - GNOME image viewer

---

## TIER 11: System-Wide Theming

### GTK - GTK Applications (#19)
- [ ] Research GTK3/GTK4 theming
- [ ] Design theme (CSS; comprehensive GTK widget theming)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGH - System-wide theme

### Qt - Qt Applications (#69)
- [ ] Research Qt5/Qt6 theming (qt5ct/qt6ct/Kvantum)
- [ ] Design theme (comprehensive Qt widget theming)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: HIGH - System-wide theme

### Xresources - X11 Configuration (#99)
- [ ] Research Xresources format
- [ ] Design theme (base colors, terminal colors, fonts)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - X11 apps

---

## TIER 12: Boot/System Components

### Plymouth - Boot Splash (#71)
- [ ] Clone repo & research
- [ ] Design theme (boot splash; minimal colors)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Boot screen

### GRUB - Bootloader (#70)
- [ ] Research GRUB theming
- [ ] Design theme (text colors, menu styling)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Bootloader

### Limine - Bootloader (#91)
- [ ] Clone repo & research
- [ ] Design theme (config file colors)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Bootloader

### kmscon - Userspace Console (#92)
- [ ] Clone repo & research
- [ ] Design theme (color palette config)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Console emulator

---

## TIER 13: Remaining GUI & Specialized Apps

### Blender - 3D Software (#90)
- [ ] Clone repo & research
- [ ] Design theme (XML theme format; minimal UI colors)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - 3D application

### Foliate - Ebook Reader (#77)
- [ ] Clone repo & research
- [ ] Design theme (GTK-based)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Reading app

### GNOME Text Editor (#89)
- [ ] Clone repo & research
- [ ] Design theme (GtkSourceView; minimal syntax colors)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Text editor

### Sublime Text - Text Editor (#48)
- [ ] Clone repo & research (proprietary)
- [ ] Design theme (JSON; minimal syntax colors)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Proprietary editor

### Halloy - IRC Client (#78)
- [ ] Clone repo & research
- [ ] Design theme (TOML; semantic: messages; mono: structure)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - IRC client

### Glance - Dashboard (#79)
- [ ] Clone repo & research
- [ ] Design theme (YAML; semantic for status)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Dashboard tool

### fcitx5 - Input Method (#88)
- [ ] Clone repo & research
- [ ] Design theme (candidate window colors)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Input method

### Cavalier - Audio Visualizer (#96)
- [ ] Clone repo & research
- [ ] Design theme (GTK-based)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Visualizer

### JankyBorders - Window Borders (#95)
- [ ] Clone repo & research
- [ ] Design theme (border colors; semantic for focus)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Window decoration

### i3bar-river - Status Bar (#94)
- [ ] Clone repo & research
- [ ] Design theme (config-based; semantic: status)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - River WM component

### nixos-icons - Icon Theme (#100)
- [ ] Research icon theming
- [ ] Design theme (color mappings for icons)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Icon theme

### ashell - Android Shell (#97)
- [ ] Clone repo & research
- [ ] Design theme (if applicable)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Android tool

### vicinae - Unknown App (#98)
- [ ] Research what vicinae is
- [ ] Clone repo & research
- [ ] Design theme (once app understood)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Unknown app

### gdu - Disk Usage Analyzer (#62)
- [ ] Clone repo & research
- [ ] Design theme (TUI; semantic: disk usage levels; mono: structure)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: MEDIUM - Disk analysis tool

### zoxide - cd Replacement (#37)
- [ ] Clone repo & research
- [ ] Design theme (minimal theming needed)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Navigation tool

### Slack - Team Communication (#42)
- [ ] Research Slack theming (sidebar colors)
- [ ] Design theme (proprietary; limited customization)
- [ ] Implement module
- [ ] Test & verify
- **Priority**: LOW - Proprietary app

---

## Progress Summary

**Total Issues**: 101
**Completed**: 0
**In Progress**: 0
**Remaining**: 101

### By Tier
- Tier 1 (Essential CLI/TUI): 0/11 complete
- Tier 2 (Development): 0/5 complete
- Tier 3 (File Managers): 0/4 complete
- Tier 4 (Browsers/Comms): 0/4 complete
- Tier 5 (Music): 0/4 complete
- Tier 6 (Productivity): 0/3 complete
- Tier 7 (System UI): 0/6 complete
- Tier 8 (Display Managers): 0/2 complete
- Tier 9 (Wallpaper): 0/2 complete
- Tier 10 (Image Viewers): 0/3 complete
- Tier 11 (System Theming): 0/3 complete
- Tier 12 (Boot/System): 0/4 complete
- Tier 13 (Remaining): 0/50 complete

---

## Notes

- **Ignore color values in issues**: Research actual configuration from source code
- **Follow Vogix16 principles**: Monochromatic for structure, functional for semantics
- **Test each implementation**: Verify theme applies correctly
- **Document decisions**: Add comments explaining color choices
- **Update this file**: Mark items complete as you finish them

