#!/bin/sh
# uninstall.sh - Terminal Enhancements Uninstaller
# https://github.com/USER/terminal-enhancements
#
# POSIX-compliant uninstaller for terminal enhancements
# Removes shell configurations and optionally uninstalls packages
#
# Usage:
#   ./uninstall.sh

set -e

VERSION="1.0.0"

# ══════════════════════════════════════════════════════════════════════════════
# DETERMINE SCRIPT LOCATION
# ══════════════════════════════════════════════════════════════════════════════

# Find script directory
determine_script_dir() {
    # Method 1: Check if we're in a directory with lib/detect.sh
    if [ -f "./lib/detect.sh" ]; then
        SCRIPT_DIR="$(pwd)"
        return 0
    fi

    # Method 2: Use $0 to find script location
    if [ -n "$0" ] && [ "$0" != "sh" ] && [ "$0" != "bash" ] && [ "$0" != "-bash" ]; then
        _dir="$(dirname "$0")"
        if [ -f "${_dir}/lib/detect.sh" ]; then
            SCRIPT_DIR="$(cd "$_dir" && pwd)"
            return 0
        fi
    fi

    # Cannot find library directory
    echo "Error: Cannot find lib/detect.sh" >&2
    echo "Please run from the terminal-enhancements directory." >&2
    exit 1
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
# UNINSTALL FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

# uninstall_package(tool) - Uninstall via package manager
# Detects pm, gets correct package name, runs uninstall command
# Returns: 0 on success, 1 on failure
uninstall_package() {
    _tool="$1"
    _pm="$(detect_package_manager)"
    _pkg="$(get_package_name "$_tool" "$_pm")"

    case "$_pm" in
        brew)
            brew uninstall "$_pkg" 2>/dev/null || brew remove "$_pkg" 2>/dev/null
            return $?
            ;;
        apt)
            sudo apt-get remove -y "$_pkg"
            return $?
            ;;
        dnf)
            sudo dnf remove -y "$_pkg"
            return $?
            ;;
        yum)
            sudo yum remove -y "$_pkg"
            return $?
            ;;
        pacman)
            sudo pacman -R --noconfirm "$_pkg"
            return $?
            ;;
        *)
            return 1
            ;;
    esac
}

# uninstall_cargo_package(tool) - Uninstall cargo-installed package
# Returns: 0 on success, 1 on failure
uninstall_cargo_package() {
    _tool="$1"

    if command -v cargo >/dev/null 2>&1; then
        cargo uninstall "$_tool" 2>/dev/null
        return $?
    fi

    return 1
}

# uninstall_tool(tool) - Router that tries appropriate uninstall method
# Returns: 0 on success, 1 on failure
uninstall_tool() {
    _tool="$1"

    # Check if installed first
    if ! is_installed "$_tool"; then
        return 0
    fi

    # Try package manager first
    if uninstall_package "$_tool" 2>/dev/null; then
        return 0
    fi

    # Fallback: try cargo uninstall
    if uninstall_cargo_package "$_tool" 2>/dev/null; then
        return 0
    fi

    # Starship special case: may have been installed via install script
    if [ "$_tool" = "starship" ]; then
        # Try to remove from common locations
        if [ -f "/usr/local/bin/starship" ]; then
            sudo rm -f "/usr/local/bin/starship" 2>/dev/null && return 0
        fi
        if [ -f "$HOME/.cargo/bin/starship" ]; then
            rm -f "$HOME/.cargo/bin/starship" 2>/dev/null && return 0
        fi
        if [ -f "$HOME/.local/bin/starship" ]; then
            rm -f "$HOME/.local/bin/starship" 2>/dev/null && return 0
        fi
    fi

    return 1
}

# count_items(space_separated_list) - Count items in a space-separated list
count_items() {
    _list="$1"
    _count=0

    for _item in $_list; do
        _count=$((_count + 1))
    done

    echo "$_count"
}

# ══════════════════════════════════════════════════════════════════════════════
# MAIN UNINSTALLATION
# ══════════════════════════════════════════════════════════════════════════════

main() {
    # Get list of all tools
    TOOLS="$(get_all_tools)"

    # Print header
    printf '\n'
    printf '%s%s Terminal Enhancements Uninstaller v%s %s\n' "${BOLD}" "${CYAN}" "$VERSION" "${RESET}"
    printf '%s════════════════════════════════════════════════════%s\n' "${CYAN}" "${RESET}"

    # Detect environment
    shells=$(detect_shells)
    pm=$(detect_package_manager)
    distro_name=$(get_distro_name)

    printf '\n%sSystem detected:%s\n' "${BOLD}" "${RESET}"
    printf '  OS:              %s%s%s\n' "${GREEN}" "$distro_name" "${RESET}"
    printf '  Package Manager: %s%s%s\n' "${GREEN}" "$pm" "${RESET}"
    printf '  Shells:          %s%s%s\n' "${GREEN}" "$shells" "${RESET}"

    # ────────────────────────────────────────────────────────────────────────────
    # PHASE 1: Remove shell configurations
    # ────────────────────────────────────────────────────────────────────────────

    printf '\n%s%sPhase 1: Remove Shell Configurations%s\n\n' "${BOLD}" "${CYAN}" "${RESET}"

    if [ "$shells" = "unknown" ]; then
        print_warning "No supported shells detected."
    else
        for _shell in $shells; do
            if ask_yes "Remove $_shell enhancements?"; then
                printf '  Removing %s%s%s configuration...\n' "${BOLD}" "$_shell" "${RESET}"
                if remove_shell_config "$_shell"; then
                    print_success "Removed $_shell configuration"
                else
                    print_warning "Failed to fully remove $_shell configuration"
                fi
            else
                print_info "Skipping $_shell configuration"
            fi
        done
    fi

    # ────────────────────────────────────────────────────────────────────────────
    # PHASE 2: Optionally remove installed packages
    # ────────────────────────────────────────────────────────────────────────────

    printf '\n%s%sPhase 2: Remove Installed Packages%s\n\n' "${BOLD}" "${CYAN}" "${RESET}"

    # Check which tools are installed
    installed_tools=""
    for _tool in $TOOLS; do
        if is_installed "$_tool"; then
            if [ -z "$installed_tools" ]; then
                installed_tools="$_tool"
            else
                installed_tools="$installed_tools $_tool"
            fi
        fi
    done

    if [ -z "$installed_tools" ]; then
        print_info "No terminal enhancement tools are currently installed."
    else
        _tool_count=$(count_items "$installed_tools")
        printf 'Found %s%d%s installed tool(s): %s%s%s\n\n' "${BOLD}" "$_tool_count" "${RESET}" "${GREEN}" "$installed_tools" "${RESET}"

        if ask_no "Do you want to uninstall these packages?"; then
            printf '\n'

            failed=""
            succeeded=""

            for _tool in $installed_tools; do
                if ask_yes "  Uninstall $_tool?"; then
                    printf '    Uninstalling %s%-10s%s... ' "${BOLD}" "$_tool" "${RESET}"

                    if uninstall_tool "$_tool"; then
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
                else
                    print_info "    Keeping $_tool"
                fi
            done

            # Show package removal summary
            if [ -n "$failed" ]; then
                printf '\n'
                print_warning "Some tools failed to uninstall: $failed"
                print_info "You may need to remove them manually."
            fi

            if [ -n "$succeeded" ]; then
                printf '\n'
                print_success "Uninstalled: $succeeded"
            fi
        else
            print_info "Keeping installed packages."
        fi
    fi

    # ────────────────────────────────────────────────────────────────────────────
    # PHASE 3: Backup cleanup
    # ────────────────────────────────────────────────────────────────────────────

    printf '\n%s%sPhase 3: Backup Cleanup%s\n\n' "${BOLD}" "${CYAN}" "${RESET}"

    if [ -d "$BACKUP_DIR" ]; then
        # Count backup files
        _backup_count=0
        if [ -d "$BACKUP_DIR" ]; then
            for _file in "$BACKUP_DIR"/*; do
                if [ -f "$_file" ]; then
                    _backup_count=$((_backup_count + 1))
                fi
            done
        fi

        if [ "$_backup_count" -gt 0 ]; then
            printf 'Found %s%d%s backup file(s) in %s%s%s\n\n' "${BOLD}" "$_backup_count" "${RESET}" "${CYAN}" "$BACKUP_DIR" "${RESET}"

            # List backup files
            for _file in "$BACKUP_DIR"/*; do
                if [ -f "$_file" ]; then
                    printf '  %s\n' "${_file##*/}"
                fi
            done
            printf '\n'

            if ask_no "Remove backup directory and all backups?"; then
                rm -rf "$BACKUP_DIR"
                print_success "Removed backup directory: $BACKUP_DIR"
            else
                print_info "Keeping backups in: $BACKUP_DIR"
            fi
        else
            print_info "Backup directory is empty."
            if ask_yes "Remove empty backup directory?"; then
                rmdir "$BACKUP_DIR" 2>/dev/null && print_success "Removed empty backup directory" || print_info "Directory not empty or already removed"
            fi
        fi
    else
        print_info "No backup directory found."
    fi

    # ────────────────────────────────────────────────────────────────────────────
    # SUMMARY
    # ────────────────────────────────────────────────────────────────────────────

    printf '\n%s════════════════════════════════════════════════════%s\n' "${CYAN}" "${RESET}"
    printf '\n'
    print_success "Uninstallation complete!"
    printf '\n'

    # Show restart instructions
    printf '%s%sTo complete the uninstallation, restart your shell or run:%s\n\n' "${BOLD}" "${CYAN}" "${RESET}"

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
    print_info "Thank you for trying Terminal Enhancements!"
    printf '\n'

    exit 0
}

# Run main function
main "$@"
