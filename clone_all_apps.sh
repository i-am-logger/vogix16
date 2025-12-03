#!/usr/bin/env bash
# Clone all app repositories for Vogix16 theming research
# Usage: ./clone_all_apps.sh

set -e

# Disable git config to avoid SSH key prompts (yubikey)
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_SYSTEM=/dev/null

CLONE_DIR=~/Code/github/tmp
mkdir -p "$CLONE_DIR"
cd "$CLONE_DIR"

echo "Cloning all app repositories to $CLONE_DIR..."
echo "This may take a while..."

# Function to clone or update a repo
clone_or_update() {
    local name=$1
    local url=$2

    if [ -d "$name" ]; then
        echo "✓ $name already exists, skipping..."
    else
        echo "→ Cloning $name..."
        # Use HTTPS and prevent URL rewriting to SSH
        git clone --quiet "$url" "$name" 2>&1 || true
    fi
}

# TIER 1: Essential CLI/TUI Tools
clone_or_update "ripgrep" "https://github.com/BurntSushi/ripgrep.git"
clone_or_update "bat" "https://github.com/sharkdp/bat.git"
clone_or_update "eza" "https://github.com/eza-community/eza.git"
clone_or_update "fd" "https://github.com/sharkdp/fd.git"
clone_or_update "fzf" "https://github.com/junegunn/fzf.git"
clone_or_update "gitui" "https://github.com/extrawurst/gitui.git"
clone_or_update "delta" "https://github.com/dandavison/delta.git"
clone_or_update "lazygit" "https://github.com/jesseduffield/lazygit.git"
clone_or_update "tmux" "https://github.com/tmux/tmux.git"
clone_or_update "starship" "https://github.com/starship/starship.git"
clone_or_update "btop" "https://github.com/aristocratos/btop.git"

# TIER 2: Development Tools
clone_or_update "vscode" "https://github.com/microsoft/vscode.git"
clone_or_update "htop" "https://github.com/htop-dev/htop.git"
clone_or_update "k9s" "https://github.com/derailed/k9s.git"
clone_or_update "kubecolor" "https://github.com/kubecolor/kubecolor.git"

# TIER 3: Terminal File Managers
clone_or_update "yazi" "https://github.com/sxyazi/yazi.git"
clone_or_update "ranger" "https://github.com/ranger/ranger.git"
clone_or_update "lf" "https://github.com/gokcehan/lf.git"
clone_or_update "nnn" "https://github.com/jarun/nnn.git"

# TIER 4: Browsers & Communications
clone_or_update "firefox" "https://github.com/mozilla/gecko-dev.git"
clone_or_update "qutebrowser" "https://github.com/qutebrowser/qutebrowser.git"
clone_or_update "vesktop" "https://github.com/Vencord/Vesktop.git"
clone_or_update "thunderbird-android" "https://github.com/thunderbird/thunderbird-android.git"

# TIER 5: Music Players
clone_or_update "ncspot" "https://github.com/hrkfdn/ncspot.git"
clone_or_update "spotify-player" "https://github.com/aome510/spotify-player.git"
clone_or_update "spicetify-cli" "https://github.com/spicetify/cli.git"
clone_or_update "cmus" "https://github.com/cmus/cmus.git"

# TIER 6: Productivity
clone_or_update "obsidian-sample-plugin" "https://github.com/obsidianmd/obsidian-sample-plugin.git"
clone_or_update "anki" "https://github.com/ankitects/anki.git"

# TIER 7: System UI Components
clone_or_update "swaylock" "https://github.com/swaywm/swaylock.git"
clone_or_update "i3status-rust" "https://github.com/greshake/i3status-rust.git"
clone_or_update "hyprpanel" "https://github.com/Jas-SinghFSU/HyprPanel.git"
clone_or_update "wob" "https://github.com/francma/wob.git"
clone_or_update "avizo" "https://github.com/misterdanb/avizo.git"
clone_or_update "mangohud" "https://github.com/flightlessmango/MangoHud.git"

# TIER 8: Display Managers
clone_or_update "lightdm" "https://github.com/canonical/lightdm.git"
clone_or_update "regreet" "https://github.com/rharish101/ReGreet.git"

# TIER 9: Wallpaper Daemons
clone_or_update "hyprpaper" "https://github.com/hyprwm/hyprpaper.git"
clone_or_update "wpaperd" "https://github.com/danyspin97/wpaperd.git"

# TIER 10: Image Viewers
clone_or_update "feh" "https://github.com/derf/feh.git"
clone_or_update "sxiv" "https://github.com/xyb3rt/sxiv.git"
clone_or_update "eog" "https://gitlab.gnome.org/GNOME/eog.git"

# TIER 11: System-Wide Theming
clone_or_update "gtk" "https://gitlab.gnome.org/GNOME/gtk.git"
clone_or_update "qtbase" "https://github.com/qt/qtbase.git"

# TIER 12: Boot/System Components
clone_or_update "plymouth" "https://gitlab.freedesktop.org/plymouth/plymouth.git"
clone_or_update "grub" "https://git.savannah.gnu.org/git/grub.git"
clone_or_update "limine" "https://github.com/limine-bootloader/limine.git"
clone_or_update "kmscon" "https://github.com/Aetf/kmscon.git"

# TIER 13: Remaining GUI & Specialized Apps
clone_or_update "blender" "https://github.com/blender/blender.git"
clone_or_update "foliate" "https://github.com/johnfactotum/foliate.git"
clone_or_update "gnome-text-editor" "https://gitlab.gnome.org/GNOME/gnome-text-editor.git"
clone_or_update "sublime-text" "https://github.com/sublimehq/sublime_text.git"
clone_or_update "halloy" "https://github.com/squidowl/halloy.git"
clone_or_update "glance" "https://github.com/glanceapp/glance.git"
clone_or_update "fcitx5" "https://github.com/fcitx/fcitx5.git"
clone_or_update "cavalier" "https://github.com/fsobolev/cavalier.git"
clone_or_update "jankyborders" "https://github.com/FelixKratz/JankyBorders.git"
clone_or_update "i3bar-river" "https://github.com/MaxVerevkin/i3bar-river.git"
clone_or_update "gdu" "https://github.com/dundee/gdu.git"
clone_or_update "zoxide" "https://github.com/ajeetdsouza/zoxide.git"
clone_or_update "neovim" "https://github.com/neovim/neovim.git"
clone_or_update "vim" "https://github.com/vim/vim.git"

echo ""
echo "✅ All repositories cloned/updated successfully!"
echo "Location: $CLONE_DIR"
