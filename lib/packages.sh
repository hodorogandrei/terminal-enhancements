#!/bin/sh
# lib/packages.sh - Package installation per distro
# POSIX-compliant for maximum compatibility

# Source detect.sh for package manager detection
# Get the directory of this script
_LIB_DIR="${0%/*}"
if [ "$_LIB_DIR" = "$0" ]; then
    _LIB_DIR="."
fi

# Try to source detect.sh from various locations
if [ -f "${_LIB_DIR}/detect.sh" ]; then
    # shellcheck disable=SC1091
    . "${_LIB_DIR}/detect.sh"
elif [ -f "$(dirname "$0")/lib/detect.sh" ]; then
    # shellcheck disable=SC1091
    . "$(dirname "$0")/lib/detect.sh"
elif [ -f "./lib/detect.sh" ]; then
    # shellcheck disable=SC1091
    . "./lib/detect.sh"
fi

# get_package_name(tool, pm) - Returns distro-specific package name
# Args: $1 = tool name, $2 = package manager
# bat -> "bat" (brew/pacman) or "bat" (apt, binary is batcat)
# fd -> "fd" (brew/pacman) or "fd-find" (apt)
# Others return as-is
get_package_name() {
    _tool="$1"
    _pm="$2"

    case "$_tool" in
        bat)
            # apt uses "bat" package but binary is "batcat"
            echo "bat"
            ;;
        fd)
            case "$_pm" in
                apt)
                    echo "fd-find"
                    ;;
                *)
                    echo "fd"
                    ;;
            esac
            ;;
        ripgrep)
            echo "ripgrep"
            ;;
        fzf)
            echo "fzf"
            ;;
        eza)
            echo "eza"
            ;;
        zoxide)
            echo "zoxide"
            ;;
        starship)
            echo "starship"
            ;;
        *)
            echo "$_tool"
            ;;
    esac
}

# is_installed(tool) - Returns 0 if installed, 1 if not
# Handles special cases: bat/batcat, fd/fdfind, ripgrep/rg
is_installed() {
    _tool="$1"

    case "$_tool" in
        bat)
            # Check both bat and batcat (Debian/Ubuntu uses batcat)
            command -v bat >/dev/null 2>&1 || command -v batcat >/dev/null 2>&1
            return $?
            ;;
        fd)
            # Check both fd and fdfind (Debian/Ubuntu uses fdfind)
            command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1
            return $?
            ;;
        ripgrep)
            # Binary is "rg"
            command -v rg >/dev/null 2>&1
            return $?
            ;;
        starship)
            command -v starship >/dev/null 2>&1
            return $?
            ;;
        fzf)
            command -v fzf >/dev/null 2>&1
            return $?
            ;;
        zoxide)
            command -v zoxide >/dev/null 2>&1
            return $?
            ;;
        eza)
            command -v eza >/dev/null 2>&1
            return $?
            ;;
        *)
            command -v "$_tool" >/dev/null 2>&1
            return $?
            ;;
    esac
}

# install_package(tool) - Install via package manager
# Detects pm, gets correct package name, runs install command
# Returns: 0 on success, 1 on failure
install_package() {
    _tool="$1"
    _pm="$(detect_package_manager)"
    _pkg="$(get_package_name "$_tool" "$_pm")"

    case "$_pm" in
        brew)
            brew install "$_pkg"
            return $?
            ;;
        apt)
            sudo apt-get update -qq && sudo apt-get install -y "$_pkg"
            return $?
            ;;
        dnf)
            sudo dnf install -y "$_pkg"
            return $?
            ;;
        yum)
            sudo yum install -y "$_pkg"
            return $?
            ;;
        pacman)
            sudo pacman -S --noconfirm "$_pkg"
            return $?
            ;;
        *)
            return 1
            ;;
    esac
}

# install_starship() - Special installer (uses starship.rs script or brew)
# Returns: 0 on success, 1 on failure
install_starship() {
    _pm="$(detect_package_manager)"

    case "$_pm" in
        brew)
            brew install starship
            return $?
            ;;
        pacman)
            sudo pacman -S --noconfirm starship
            return $?
            ;;
        *)
            # Use official starship installer script
            if command -v curl >/dev/null 2>&1; then
                curl -sS https://starship.rs/install.sh | sh -s -- -y
                return $?
            elif command -v wget >/dev/null 2>&1; then
                wget -qO- https://starship.rs/install.sh | sh -s -- -y
                return $?
            else
                return 1
            fi
            ;;
    esac
}

# install_zoxide() - Uses apt/brew/pacman or falls back to cargo
# Returns: 0 on success, 1 on failure
install_zoxide() {
    _pm="$(detect_package_manager)"

    case "$_pm" in
        brew)
            brew install zoxide
            return $?
            ;;
        pacman)
            sudo pacman -S --noconfirm zoxide
            return $?
            ;;
        apt)
            # zoxide is available in newer Ubuntu/Debian
            # Try apt first, fall back to cargo if not available
            if apt-cache show zoxide >/dev/null 2>&1; then
                sudo apt-get update -qq && sudo apt-get install -y zoxide
                return $?
            else
                install_via_cargo zoxide
                return $?
            fi
            ;;
        dnf)
            # zoxide may be available in Fedora repos
            if dnf info zoxide >/dev/null 2>&1; then
                sudo dnf install -y zoxide
                return $?
            else
                install_via_cargo zoxide
                return $?
            fi
            ;;
        yum)
            # Usually not in yum repos, use cargo
            install_via_cargo zoxide
            return $?
            ;;
        *)
            install_via_cargo zoxide
            return $?
            ;;
    esac
}

# install_eza() - Uses apt repo, brew/pacman, or cargo fallback
# Returns: 0 on success, 1 on failure
install_eza() {
    _pm="$(detect_package_manager)"

    case "$_pm" in
        brew)
            brew install eza
            return $?
            ;;
        pacman)
            sudo pacman -S --noconfirm eza
            return $?
            ;;
        apt)
            # eza is available in newer Ubuntu (24.04+) and Debian
            # Try apt first, fall back to cargo if not available
            if apt-cache show eza >/dev/null 2>&1; then
                sudo apt-get update -qq && sudo apt-get install -y eza
                return $?
            else
                install_via_cargo eza
                return $?
            fi
            ;;
        dnf)
            # eza may be available in Fedora repos
            if dnf info eza >/dev/null 2>&1; then
                sudo dnf install -y eza
                return $?
            else
                install_via_cargo eza
                return $?
            fi
            ;;
        yum)
            # Usually not in yum repos, use cargo
            install_via_cargo eza
            return $?
            ;;
        *)
            install_via_cargo eza
            return $?
            ;;
    esac
}

# install_via_cargo(tool) - Fallback installer using cargo
# Installs rustup if needed, then cargo install
# Returns: 0 on success, 1 on failure
install_via_cargo() {
    _tool="$1"

    # Check if cargo is installed
    if ! command -v cargo >/dev/null 2>&1; then
        # Try to install rustup
        if command -v curl >/dev/null 2>&1; then
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            # Source cargo env for current session
            if [ -f "$HOME/.cargo/env" ]; then
                # shellcheck disable=SC1091
                . "$HOME/.cargo/env"
            fi
        elif command -v wget >/dev/null 2>&1; then
            wget -qO- https://sh.rustup.rs | sh -s -- -y
            if [ -f "$HOME/.cargo/env" ]; then
                # shellcheck disable=SC1091
                . "$HOME/.cargo/env"
            fi
        else
            return 1
        fi
    fi

    # Verify cargo is now available
    if ! command -v cargo >/dev/null 2>&1; then
        return 1
    fi

    # Install the tool via cargo
    cargo install "$_tool"
    return $?
}

# install_tool(tool) - Router that calls the right installer
# Returns: 0 on success, 1 on failure
install_tool() {
    _tool="$1"

    # Check if already installed
    if is_installed "$_tool"; then
        return 0
    fi

    case "$_tool" in
        starship)
            install_starship
            return $?
            ;;
        zoxide)
            install_zoxide
            return $?
            ;;
        eza)
            install_eza
            return $?
            ;;
        bat|fd|ripgrep|fzf)
            install_package "$_tool"
            return $?
            ;;
        *)
            # Try generic package installation
            install_package "$_tool"
            return $?
            ;;
    esac
}

# get_tool_description(tool) - Returns human-readable description
get_tool_description() {
    _tool="$1"

    case "$_tool" in
        starship)
            echo "Cross-shell prompt with git info"
            ;;
        fzf)
            echo "Fuzzy finder (Ctrl+R history search)"
            ;;
        zoxide)
            echo "Smart cd that learns your habits"
            ;;
        eza)
            echo "Modern ls with icons and git status"
            ;;
        bat)
            echo "Cat with syntax highlighting"
            ;;
        fd)
            echo "Fast, user-friendly find"
            ;;
        ripgrep)
            echo "Fast grep replacement"
            ;;
        *)
            echo "Command-line tool"
            ;;
    esac
}

# get_all_tools() - Returns space-separated list of all tools
get_all_tools() {
    echo "starship fzf zoxide eza bat fd ripgrep"
}
