#!/bin/sh
# install.sh - Terminal Enhancements Installer
# https://github.com/hodorogandrei/terminal-enhancements
#
# POSIX-compliant installer for modern terminal tools:
# starship, fzf, zoxide, eza, bat, fd, ripgrep
#
# Usage:
#   Direct:      ./install.sh
#   curl-to-bash: curl -fsSL https://raw.githubusercontent.com/hodorogandrei/terminal-enhancements/main/install.sh | bash

set -e

VERSION="1.0.0"
REPO_URL="https://github.com/hodorogandrei/terminal-enhancements.git"

# ══════════════════════════════════════════════════════════════════════════════
# DETERMINE SCRIPT LOCATION
# ══════════════════════════════════════════════════════════════════════════════

# Handle both direct execution and curl-to-bash scenarios
determine_script_dir() {
    # Method 1: Check if we're in a directory with lib/detect.sh
    if [ -f "./lib/detect.sh" ]; then
        SCRIPT_DIR="$(pwd)"
        return 0
    fi

    # Method 2: Use $0 to find script location (works for direct execution)
    if [ -n "$0" ] && [ "$0" != "sh" ] && [ "$0" != "bash" ] && [ "$0" != "-bash" ]; then
        _dir="$(dirname "$0")"
        if [ -f "${_dir}/lib/detect.sh" ]; then
            SCRIPT_DIR="$(cd "$_dir" && pwd)"
            return 0
        fi
    fi

    # Method 3: Running via curl-to-bash - download to temp directory
    SCRIPT_DIR=$(mktemp -d)
    TEMP_INSTALL=1

    echo "Downloading terminal-enhancements to temporary directory..."

    if command -v git >/dev/null 2>&1; then
        if git clone --depth 1 "$REPO_URL" "$SCRIPT_DIR" 2>/dev/null; then
            return 0
        fi
    fi

    # Git failed or not available
    echo "Error: Failed to download terminal-enhancements." >&2
    echo "Please clone manually:" >&2
    echo "  git clone $REPO_URL" >&2
    echo "  cd terminal-enhancements" >&2
    echo "  ./install.sh" >&2
    rm -rf "$SCRIPT_DIR"
    exit 2
}

# Determine SCRIPT_DIR
determine_script_dir

# ══════════════════════════════════════════════════════════════════════════════
# LOAD LIBRARIES
# ══════════════════════════════════════════════════════════════════════════════

# Verify libraries exist
for lib in detect.sh prompts.sh packages.sh config.sh; do
    if [ ! -f "$SCRIPT_DIR/lib/$lib" ]; then
        echo "Error: Missing required library: $SCRIPT_DIR/lib/$lib" >&2
        exit 1
    fi
done

# Source libraries in dependency order
# shellcheck disable=SC1091
. "$SCRIPT_DIR/lib/detect.sh"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/lib/prompts.sh"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/lib/packages.sh"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/lib/config.sh"

# Override SCRIPT_DIR in config.sh (it may have been set differently)
SCRIPT_DIR="$SCRIPT_DIR"

# ══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

# Display available tools with descriptions and install status
display_tools() {
    _tools="$1"

    printf '\n%s%sAvailable tools:%s\n\n' "${BOLD}" "${CYAN}" "${RESET}"

    for _tool in $_tools; do
        _desc=$(get_tool_description "$_tool")
        if is_installed "$_tool"; then
            printf '  %s[installed]%s %-10s - %s\n' "${GREEN}" "${RESET}" "$_tool" "$_desc"
        else
            printf '  %s[        ]%s %-10s - %s\n' "${YELLOW}" "${RESET}" "$_tool" "$_desc"
        fi
    done

    printf '\n'
}

# Cleanup function for temp directory
cleanup() {
    if [ "${TEMP_INSTALL:-0}" = "1" ] && [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR" ]; then
        rm -rf "$SCRIPT_DIR"
    fi
}

# Set trap for cleanup on exit
trap cleanup EXIT

# ══════════════════════════════════════════════════════════════════════════════
# MAIN INSTALLATION
# ══════════════════════════════════════════════════════════════════════════════

main() {
    # Get list of all tools
    TOOLS="$(get_all_tools)"

    # Print header
    printf '\n'
    printf '%s%s Terminal Enhancements Installer v%s %s\n' "${BOLD}" "${CYAN}" "$VERSION" "${RESET}"
    printf '%s════════════════════════════════════════════════════%s\n' "${CYAN}" "${RESET}"

    # Detect environment
    os=$(detect_os)
    distro=$(detect_distro)
    pm=$(detect_package_manager)
    shells=$(detect_shells)
    distro_name=$(get_distro_name)

    printf '\n%sSystem detected:%s\n' "${BOLD}" "${RESET}"
    printf '  OS:              %s%s%s\n' "${GREEN}" "$distro_name" "${RESET}"
    printf '  Package Manager: %s%s%s\n' "${GREEN}" "$pm" "${RESET}"
    printf '  Shells:          %s%s%s\n' "${GREEN}" "$shells" "${RESET}"

    # Check for supported package manager
    if [ "$pm" = "unknown" ]; then
        print_error "No supported package manager found."
        print_info "Supported: apt, dnf, yum, pacman, brew"
        exit 2
    fi

    # Display available tools with status
    display_tools "$TOOLS"

    # Prompt user to select tools
    printf '%sSelect tools to install:%s\n' "${BOLD}" "${RESET}"
    printf '(Press Enter to install all, or type selections like "y y n y n y y")\n\n'

    for _tool in $TOOLS; do
        if is_installed "$_tool"; then
            printf '  %s[y]%s %s %s(installed)%s\n' "${GREEN}" "${RESET}" "$_tool" "${GREEN}" "${RESET}"
        else
            printf '  %s[y]%s %s\n' "${BLUE}" "${RESET}" "$_tool"
        fi
    done

    printf '\n%s>%s ' "${CYAN}" "${RESET}"

    # Read selection
    if [ -t 0 ]; then
        # Interactive - read from terminal
        read -r selection </dev/tty 2>/dev/null || read -r selection
    else
        # Non-interactive (piped) - use default (all)
        selection=""
        printf '(non-interactive mode, installing all)\n'
    fi

    # Parse selection
    if [ -z "$selection" ]; then
        # Accept all tools
        selected="$TOOLS"
    else
        # Parse user's y/n selections
        selected=""
        _index=1

        # shellcheck disable=SC2086
        set -- $selection

        for _tool in $TOOLS; do
            eval "_answer=\${$_index:-y}"

            case "$_answer" in
                [Yy]|[Yy][Ee][Ss])
                    if [ -z "$selected" ]; then
                        selected="$_tool"
                    else
                        selected="$selected $_tool"
                    fi
                    ;;
            esac

            _index=$((_index + 1))
        done
    fi

    # Check if anything selected
    if [ -z "$selected" ]; then
        print_warning "No tools selected. Exiting."
        exit 0
    fi

    # Install tools
    printf '\n%s%sInstalling selected tools...%s\n\n' "${BOLD}" "${CYAN}" "${RESET}"

    # Pre-acquire sudo credentials so the password prompt is not swallowed
    # by output redirection during individual tool installs
    if [ "$(id -u)" -ne 0 ]; then
        _needs_sudo=0
        for _tool in $selected; do
            if ! is_installed "$_tool"; then
                _needs_sudo=1
                break
            fi
        done
        if [ "$_needs_sudo" = "1" ]; then
            print_info "Sudo access is needed to install packages."
            if ! sudo -v 2>/dev/null; then
                print_error "Failed to obtain sudo credentials. Cannot install packages."
                exit 1
            fi
            # Wait for any active apt locks before starting installs
            if command -v fuser >/dev/null 2>&1; then
                if sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
                   sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; then
                    print_info "Waiting for other package managers to finish..."
                    while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
                          sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
                        sleep 2
                    done
                fi
            fi
        fi
    fi

    failed=""
    succeeded=""

    for _tool in $selected; do
        printf '  Installing %s%-10s%s... ' "${BOLD}" "$_tool" "${RESET}"

        if is_installed "$_tool"; then
            printf '%s(already installed)%s\n' "${GREEN}" "${RESET}"
            if [ -z "$succeeded" ]; then
                succeeded="$_tool"
            else
                succeeded="$succeeded $_tool"
            fi
        elif install_tool "$_tool" >/dev/null 2>&1; then
            print_success "done"
            if [ -z "$succeeded" ]; then
                succeeded="$_tool"
            else
                succeeded="$succeeded $_tool"
            fi
        else
            print_error "failed"
            if [ -z "$failed" ]; then
                failed="$_tool"
            else
                failed="$failed $_tool"
            fi
        fi
    done

    # Configure shells
    printf '\n%s%sConfigure shell integrations:%s\n\n' "${BOLD}" "${CYAN}" "${RESET}"

    if [ "$shells" = "unknown" ]; then
        print_warning "No supported shells detected."
        print_info "Manually add configurations to your shell's rc file."
    else
        for _shell in $shells; do
            printf '  Configuring %s%s%s...\n' "${BOLD}" "$_shell" "${RESET}"
            install_shell_config "$_shell"
        done
    fi

    # Show summary
    printf '\n%s════════════════════════════════════════════════════%s\n' "${CYAN}" "${RESET}"

    if [ -n "$failed" ]; then
        printf '\n'
        print_warning "Some tools failed to install: $failed"
        print_info "Try installing them manually or check system requirements."
        printf '\n'
    fi

    if [ -n "$succeeded" ]; then
        print_success "Installation complete!"
        printf '\n'
        print_info "Installed tools: $succeeded"
        printf '\n'
    fi

    # Show restart instructions
    printf '%s%sTo activate enhancements, restart your shell or run:%s\n\n' "${BOLD}" "${CYAN}" "${RESET}"

    for _shell in $shells; do
        case "$_shell" in
            bash)
                printf '  %ssource ~/.bashrc%s\n' "${GREEN}" "${RESET}"
                ;;
            zsh)
                printf '  %ssource ~/.zshrc%s\n' "${GREEN}" "${RESET}"
                ;;
            fish)
                printf '  %ssource ~/.config/fish/config.fish%s\n' "${GREEN}" "${RESET}"
                ;;
        esac
    done

    printf '\n'

    # Show quick reference
    printf '%s%sQuick reference:%s\n' "${BOLD}" "${CYAN}" "${RESET}"
    printf '  %sCtrl+R%s  - Fuzzy history search (fzf)\n' "${YELLOW}" "${RESET}"
    printf '  %sCtrl+T%s  - Fuzzy file finder (fzf)\n' "${YELLOW}" "${RESET}"
    printf '  %sz <dir>%s - Smart cd (zoxide)\n' "${YELLOW}" "${RESET}"
    printf '  %sll%s      - Detailed ls with icons (eza)\n' "${YELLOW}" "${RESET}"
    printf '  %slt%s      - Tree view (eza)\n' "${YELLOW}" "${RESET}"
    printf '\n'

    # Return appropriate exit code
    if [ -n "$failed" ]; then
        exit 1
    fi

    exit 0
}

# Run main function
main "$@"
