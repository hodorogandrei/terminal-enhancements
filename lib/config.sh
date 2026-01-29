#!/bin/sh
# lib/config.sh - Shell configuration file management
# POSIX-compliant for maximum compatibility

BACKUP_DIR="$HOME/.terminal-enhancements-backup"

# Determine SCRIPT_DIR (project root) for finding configs/
# Try multiple approaches to find the project root
_LIB_DIR="${0%/*}"
[ "$_LIB_DIR" = "$0" ] && _LIB_DIR="."

# Check relative to script, then relative to current dir
if [ -f "${_LIB_DIR}/prompts.sh" ]; then
    # We're in the lib directory, go up one level
    SCRIPT_DIR="$(cd "${_LIB_DIR}/.." 2>/dev/null && pwd)"
elif [ -f "${_LIB_DIR}/lib/prompts.sh" ]; then
    SCRIPT_DIR="$(cd "${_LIB_DIR}" 2>/dev/null && pwd)"
elif [ -f "./lib/prompts.sh" ]; then
    SCRIPT_DIR="$(pwd)"
elif [ -f "$(dirname "$0")/lib/prompts.sh" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
else
    # Fallback: assume parent of lib directory
    SCRIPT_DIR="$(cd "${_LIB_DIR}/.." 2>/dev/null && pwd)"
fi

# Source prompts.sh for ask_conflict, ask_yes, print_* functions
if [ -f "${SCRIPT_DIR}/lib/prompts.sh" ]; then
    # shellcheck disable=SC1091
    . "${SCRIPT_DIR}/lib/prompts.sh"
elif [ -f "${_LIB_DIR}/prompts.sh" ]; then
    # shellcheck disable=SC1091
    . "${_LIB_DIR}/prompts.sh"
fi

# backup_file(file) - Create timestamped backup
#   Creates BACKUP_DIR if needed
#   Copies file to BACKUP_DIR/filename.YYYY-MM-DD_HHMMSS
#   Returns the backup path (printed to stdout)
backup_file() {
    _file="$1"
    _timestamp=$(date +%Y-%m-%d_%H%M%S)
    _basename="${_file##*/}"

    # Create backup directory if needed
    mkdir -p "$BACKUP_DIR"

    if [ -f "$_file" ]; then
        _backup_path="${BACKUP_DIR}/${_basename}.${_timestamp}"
        cp "$_file" "$_backup_path"
        echo "$_backup_path"
        return 0
    fi

    return 1
}

# has_source_line(rc_file, source_file) - Check if source line exists
#   Returns 0 if rc_file contains a line referencing source_file
has_source_line() {
    _rc_file="$1"
    _source_file="$2"

    [ -f "$_rc_file" ] && grep -q "$_source_file" "$_rc_file" 2>/dev/null
}

# add_source_line(rc_file, source_file) - Add source line
#   For bash/zsh: [ -f source_file ] && source source_file
#   For fish: source source_file
#   Returns 0 if added, 1 if already exists
add_source_line() {
    _rc_file="$1"
    _source_file="$2"
    _source_line=""

    # Determine the appropriate source line based on shell type
    case "$_rc_file" in
        *fish*|*.fish)
            _source_line="source $_source_file"
            ;;
        *)
            _source_line="[ -f $_source_file ] && source $_source_file"
            ;;
    esac

    # Check if already present
    if has_source_line "$_rc_file" "$_source_file"; then
        return 1
    fi

    # Add the source line with a header comment
    printf '\n# Terminal Enhancements\n%s\n' "$_source_line" >> "$_rc_file"
    return 0
}

# show_config_diff(existing, new) - Show diff between configs
#   Uses diff -u if available, otherwise shows head of both
show_config_diff() {
    _existing="$1"
    _new="$2"

    if command -v diff >/dev/null 2>&1; then
        printf '%s%sDiff (existing vs new):%s\n' "${BOLD:-}" "${CYAN:-}" "${RESET:-}"
        diff -u "$_existing" "$_new" 2>/dev/null || true
    else
        printf '%s%s=== Existing ===%s\n' "${BOLD:-}" "${CYAN:-}" "${RESET:-}"
        head -20 "$_existing" 2>/dev/null || true
        printf '\n%s%s=== New ===%s\n' "${BOLD:-}" "${CYAN:-}" "${RESET:-}"
        head -20 "$_new" 2>/dev/null || true
    fi
}

# install_shell_config(shell) - Install enhancement file for shell
#   shell: "bash", "zsh", or "fish"
#   Copies from configs/ to appropriate location
#   Handles conflicts via ask_conflict() from prompts.sh
#   Adds source line to rc file
install_shell_config() {
    _shell="$1"
    _source_config=""
    _dest_config=""
    _rc_file=""

    case "$_shell" in
        bash)
            _source_config="$SCRIPT_DIR/configs/bash_enhancements"
            _dest_config="$HOME/.bash_enhancements"
            _rc_file="$HOME/.bashrc"
            ;;
        zsh)
            _source_config="$SCRIPT_DIR/configs/zsh_enhancements"
            _dest_config="$HOME/.zsh_enhancements"
            _rc_file="$HOME/.zshrc"
            ;;
        fish)
            _source_config="$SCRIPT_DIR/configs/fish_enhancements"
            _dest_config="$HOME/.config/fish/conf.d/enhancements.fish"
            _rc_file="$HOME/.config/fish/config.fish"
            # Ensure fish config directory exists
            mkdir -p "$HOME/.config/fish/conf.d"
            ;;
        *)
            print_error "Unknown shell: $_shell" 2>/dev/null || echo "Unknown shell: $_shell" >&2
            return 1
            ;;
    esac

    # Check if source config exists
    if [ ! -f "$_source_config" ]; then
        print_error "Source config not found: $_source_config" 2>/dev/null || echo "Source config not found: $_source_config" >&2
        return 1
    fi

    # Handle existing destination config (conflict resolution)
    if [ -f "$_dest_config" ]; then
        _action=$(ask_conflict "$_dest_config")

        case "$_action" in
            overwrite)
                _backup=$(backup_file "$_dest_config")
                cp "$_source_config" "$_dest_config"
                print_success "Installed $_dest_config (backup: $_backup)" 2>/dev/null || echo "Installed $_dest_config (backup: $_backup)"
                ;;
            diff)
                show_config_diff "$_dest_config" "$_source_config"
                # Ask again after showing diff
                if ask_no "Overwrite after seeing diff?"; then
                    _backup=$(backup_file "$_dest_config")
                    cp "$_source_config" "$_dest_config"
                    print_success "Installed $_dest_config (backup: $_backup)" 2>/dev/null || echo "Installed $_dest_config (backup: $_backup)"
                else
                    print_info "Skipped $_dest_config" 2>/dev/null || echo "Skipped $_dest_config"
                    return 0
                fi
                ;;
            skip)
                print_info "Skipped $_dest_config" 2>/dev/null || echo "Skipped $_dest_config"
                return 0
                ;;
        esac
    else
        # No conflict, just copy
        cp "$_source_config" "$_dest_config"
        print_success "Created $_dest_config" 2>/dev/null || echo "Created $_dest_config"
    fi

    # Add source line to rc file
    if [ -f "$_rc_file" ]; then
        if add_source_line "$_rc_file" "$_dest_config"; then
            print_success "Added source line to $_rc_file" 2>/dev/null || echo "Added source line to $_rc_file"
        else
            print_info "Source line already in $_rc_file" 2>/dev/null || echo "Source line already in $_rc_file"
        fi
    else
        # Create rc file with source line
        case "$_shell" in
            fish)
                mkdir -p "$(dirname "$_rc_file")"
                printf '# Fish shell config\nsource %s\n' "$_dest_config" > "$_rc_file"
                ;;
            *)
                printf '# Shell config\n[ -f %s ] && source %s\n' "$_dest_config" "$_dest_config" > "$_rc_file"
                ;;
        esac
        print_success "Created $_rc_file" 2>/dev/null || echo "Created $_rc_file"
    fi

    return 0
}

# remove_shell_config(shell) - Remove enhancement config
#   Removes config file (offers to restore backup)
#   Removes source line from rc file
remove_shell_config() {
    _shell="$1"
    _config_file=""
    _rc_file=""

    case "$_shell" in
        bash)
            _config_file="$HOME/.bash_enhancements"
            _rc_file="$HOME/.bashrc"
            ;;
        zsh)
            _config_file="$HOME/.zsh_enhancements"
            _rc_file="$HOME/.zshrc"
            ;;
        fish)
            _config_file="$HOME/.config/fish/conf.d/enhancements.fish"
            _rc_file="$HOME/.config/fish/config.fish"
            ;;
        *)
            print_error "Unknown shell: $_shell" 2>/dev/null || echo "Unknown shell: $_shell" >&2
            return 1
            ;;
    esac

    # Remove config file (with option to restore backup)
    if [ -f "$_config_file" ]; then
        _basename="${_config_file##*/}"
        # Find the latest backup
        _latest_backup=""
        if [ -d "$BACKUP_DIR" ]; then
            _latest_backup=$(ls -t "$BACKUP_DIR/${_basename}".* 2>/dev/null | head -1)
        fi

        if [ -n "$_latest_backup" ]; then
            if ask_yes "Restore from backup $_latest_backup?"; then
                cp "$_latest_backup" "$_config_file"
                print_success "Restored $_config_file from backup" 2>/dev/null || echo "Restored $_config_file from backup"
            else
                rm "$_config_file"
                print_success "Removed $_config_file" 2>/dev/null || echo "Removed $_config_file"
            fi
        else
            rm "$_config_file"
            print_success "Removed $_config_file" 2>/dev/null || echo "Removed $_config_file"
        fi
    else
        print_info "Config file not found: $_config_file" 2>/dev/null || echo "Config file not found: $_config_file"
    fi

    # Remove source line from rc file
    if [ -f "$_rc_file" ]; then
        # Create temp file without the terminal-enhancements lines
        _temp_file="${_rc_file}.tmp.$$"
        grep -v "Terminal Enhancements\|terminal-enhancements\|${_config_file}" "$_rc_file" > "$_temp_file" 2>/dev/null || true
        mv "$_temp_file" "$_rc_file"
        print_success "Removed source line from $_rc_file" 2>/dev/null || echo "Removed source line from $_rc_file"
    fi

    return 0
}
