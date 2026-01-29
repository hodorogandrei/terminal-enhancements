#!/bin/sh
# lib/detect.sh - OS, distro, and shell detection
# POSIX-compliant for maximum compatibility

# detect_os() - Returns "linux", "macos", or "unknown"
# Uses uname -s to detect the operating system
detect_os() {
    case "$(uname -s)" in
        Linux*)  echo "linux" ;;
        Darwin*) echo "macos" ;;
        *)       echo "unknown" ;;
    esac
}

# detect_distro() - Returns "debian", "fedora", "rhel", "arch", or "unknown"
# Reads /etc/os-release, checks $ID and $ID_LIKE for derivatives
detect_distro() {
    # Only relevant for Linux
    if [ "$(detect_os)" != "linux" ]; then
        echo "unknown"
        return
    fi

    # Check /etc/os-release
    if [ -f /etc/os-release ]; then
        # Source the file to get ID and ID_LIKE variables
        # shellcheck disable=SC1091
        . /etc/os-release

        # Check ID first for exact match
        case "$ID" in
            debian|ubuntu|linuxmint|pop|elementary|zorin|kali)
                echo "debian"
                return
                ;;
            fedora)
                echo "fedora"
                return
                ;;
            rhel|centos|rocky|alma|oracle|scientific)
                echo "rhel"
                return
                ;;
            arch|manjaro|endeavouros|garuda|artix)
                echo "arch"
                return
                ;;
        esac

        # Check ID_LIKE for derivatives
        case "$ID_LIKE" in
            *debian*|*ubuntu*)
                echo "debian"
                return
                ;;
            *fedora*)
                echo "fedora"
                return
                ;;
            *rhel*|*centos*)
                echo "rhel"
                return
                ;;
            *arch*)
                echo "arch"
                return
                ;;
        esac
    fi

    # Fallback detection using release files
    if [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/fedora-release ]; then
        echo "fedora"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif [ -f /etc/arch-release ]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

# detect_package_manager() - Returns "brew", "apt", "dnf", "yum", "pacman", or "unknown"
# Checks which package manager commands exist
detect_package_manager() {
    # Check for Homebrew first (works on both macOS and Linux)
    if command -v brew >/dev/null 2>&1; then
        echo "brew"
    elif command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

# detect_shells() - Returns space-separated list like "bash zsh fish"
# Checks for ~/.bashrc, ~/.zshrc, ~/.config/fish, and shell commands
detect_shells() {
    shells=""

    # Check for bash
    if [ -f "$HOME/.bashrc" ] || [ -f "$HOME/.bash_profile" ] || command -v bash >/dev/null 2>&1; then
        shells="bash"
    fi

    # Check for zsh
    if [ -f "$HOME/.zshrc" ] || command -v zsh >/dev/null 2>&1; then
        if [ -n "$shells" ]; then
            shells="$shells zsh"
        else
            shells="zsh"
        fi
    fi

    # Check for fish
    if [ -d "$HOME/.config/fish" ] || command -v fish >/dev/null 2>&1; then
        if [ -n "$shells" ]; then
            shells="$shells fish"
        else
            shells="fish"
        fi
    fi

    # Return detected shells or "unknown" if none found
    if [ -n "$shells" ]; then
        echo "$shells"
    else
        echo "unknown"
    fi
}

# get_distro_name() - Returns human-readable name like "Ubuntu 24.04" or "macOS 14.0"
# Uses /etc/os-release PRETTY_NAME or sw_vers on macOS
get_distro_name() {
    os="$(detect_os)"

    case "$os" in
        macos)
            # Use sw_vers on macOS
            if command -v sw_vers >/dev/null 2>&1; then
                product_name="$(sw_vers -productName 2>/dev/null)"
                product_version="$(sw_vers -productVersion 2>/dev/null)"
                if [ -n "$product_name" ] && [ -n "$product_version" ]; then
                    echo "$product_name $product_version"
                else
                    echo "macOS"
                fi
            else
                echo "macOS"
            fi
            ;;
        linux)
            # Use PRETTY_NAME from /etc/os-release
            if [ -f /etc/os-release ]; then
                # shellcheck disable=SC1091
                . /etc/os-release
                if [ -n "$PRETTY_NAME" ]; then
                    echo "$PRETTY_NAME"
                elif [ -n "$NAME" ] && [ -n "$VERSION" ]; then
                    echo "$NAME $VERSION"
                elif [ -n "$NAME" ]; then
                    echo "$NAME"
                else
                    echo "Linux"
                fi
            else
                echo "Linux"
            fi
            ;;
        *)
            echo "Unknown OS"
            ;;
    esac
}
