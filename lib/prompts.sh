#!/bin/sh
# lib/prompts.sh - User interaction helpers
# POSIX-compliant user prompts and colored output

# Color variables (set by setup_colors)
RED=""
GREEN=""
YELLOW=""
BLUE=""
MAGENTA=""
CYAN=""
BOLD=""
RESET=""

# setup_colors() - Initialize color variables if terminal supports them
# Sets: RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, BOLD, RESET
# Uses tput for portability, gracefully degrades if not supported
setup_colors() {
    # Check if stdout is a terminal and tput is available
    if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
        # Check if terminal supports colors (at least 8)
        if [ "$(tput colors 2>/dev/null)" -ge 8 ] 2>/dev/null; then
            RED=$(tput setaf 1)
            GREEN=$(tput setaf 2)
            YELLOW=$(tput setaf 3)
            BLUE=$(tput setaf 4)
            MAGENTA=$(tput setaf 5)
            CYAN=$(tput setaf 6)
            BOLD=$(tput bold)
            RESET=$(tput sgr0)
        fi
    fi
}

# print_header(text) - Print bold cyan header with underline
# Args: $1 = header text
print_header() {
    _text="$1"
    _len=${#_text}
    _underline=""

    # Build underline of same length
    _i=0
    while [ "$_i" -lt "$_len" ]; do
        _underline="${_underline}="
        _i=$((_i + 1))
    done

    printf '%s%s%s%s\n' "${BOLD}" "${CYAN}" "$_text" "${RESET}"
    printf '%s%s%s%s\n' "${BOLD}" "${CYAN}" "$_underline" "${RESET}"
}

# print_success(text) - Print "checkmark text" in green
# Args: $1 = success message
print_success() {
    printf '%s%s %s%s\n' "${GREEN}" "✓" "$1" "${RESET}"
}

# print_error(text) - Print "x text" in red
# Args: $1 = error message
print_error() {
    printf '%s%s %s%s\n' "${RED}" "✗" "$1" "${RESET}"
}

# print_warning(text) - Print "! text" in yellow
# Args: $1 = warning message
print_warning() {
    printf '%s%s %s%s\n' "${YELLOW}" "!" "$1" "${RESET}"
}

# print_info(text) - Print "arrow text" in blue
# Args: $1 = info message
print_info() {
    printf '%s%s %s%s\n' "${BLUE}" "→" "$1" "${RESET}"
}

# ask_yes(prompt) - Ask y/n question, default yes
# Args: $1 = prompt text
# Returns: 0=yes, 1=no
ask_yes() {
    _prompt="$1"
    printf '%s [Y/n] ' "$_prompt"

    # Read user input
    read -r _answer </dev/tty 2>/dev/null || read -r _answer

    # Default to yes if empty, check for explicit no
    case "$_answer" in
        [Nn]|[Nn][Oo])
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

# ask_no(prompt) - Ask y/n question, default no
# Args: $1 = prompt text
# Returns: 0=yes, 1=no
ask_no() {
    _prompt="$1"
    printf '%s [y/N] ' "$_prompt"

    # Read user input
    read -r _answer </dev/tty 2>/dev/null || read -r _answer

    # Default to no if empty, check for explicit yes
    case "$_answer" in
        [Yy]|[Yy][Ee][Ss])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ask_conflict(file) - Ask overwrite question with y/N/d options
# Args: $1 = filename that has conflict
# Returns: "overwrite", "diff", or "skip" (printed to stdout)
# Note: UI prompts go to stderr, only result goes to stdout
ask_conflict() {
    _file="$1"

    while true; do
        printf '%sFile already exists:%s %s\n' "${YELLOW}" "${RESET}" "$_file" >&2
        printf 'Overwrite? [y]es / [N]o / [d]iff: ' >&2

        # Read user input
        read -r _answer </dev/tty 2>/dev/null || read -r _answer

        case "$_answer" in
            [Yy]|[Yy][Ee][Ss])
                printf 'overwrite'
                return 0
                ;;
            [Dd]|[Dd][Ii][Ff][Ff])
                printf 'diff'
                return 0
                ;;
            ""|[Nn]|[Nn][Oo])
                printf 'skip'
                return 0
                ;;
            *)
                print_warning "Please enter y, n, or d" >&2
                ;;
        esac
    done
}

# prompt_tool_selection(tools) - Multi-select prompt
# Args: $1 = space-separated tool names "starship fzf zoxide"
# Shows tool list with [y] prefix
# User presses Enter for all, or types "y y n y" for selection
# Returns: space-separated selected tools (printed to stdout)
# Note: UI prompts go to stderr, only result goes to stdout
prompt_tool_selection() {
    _tools="$1"
    _count=0
    _tool_list=""

    # Display available tools (to stderr for UI)
    printf '%s%sAvailable tools:%s\n' "${BOLD}" "${CYAN}" "${RESET}" >&2

    for _tool in $_tools; do
        _count=$((_count + 1))
        printf '  %s[y]%s %s\n' "${GREEN}" "${RESET}" "$_tool" >&2
        if [ -z "$_tool_list" ]; then
            _tool_list="$_tool"
        else
            _tool_list="$_tool_list $_tool"
        fi
    done

    printf '\n' >&2
    printf '%sPress Enter to install all, or type selection (e.g., "y y n y"):%s ' "${BLUE}" "${RESET}" >&2

    # Read user input
    read -r _selection </dev/tty 2>/dev/null || read -r _selection

    # If empty, return all tools
    if [ -z "$_selection" ]; then
        printf '%s' "$_tool_list"
        return 0
    fi

    # Parse selection
    _selected=""
    _index=1

    # Convert selection to array-like processing
    set -- $_selection

    for _tool in $_tools; do
        # Get the corresponding answer (y/n)
        eval "_answer=\${$_index}"

        case "$_answer" in
            [Yy]|[Yy][Ee][Ss])
                if [ -z "$_selected" ]; then
                    _selected="$_tool"
                else
                    _selected="$_selected $_tool"
                fi
                ;;
        esac

        _index=$((_index + 1))
    done

    printf '%s' "$_selected"
}

# Initialize colors when sourced
setup_colors
