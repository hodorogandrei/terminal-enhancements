# Terminal Enhancements

A one-command installer for modern terminal tools. Upgrade your shell with fuzzy finding, smart navigation, syntax highlighting, and more.

## What You Get

| Tool | Description |
|------|-------------|
| **starship** | Cross-shell prompt with git info, battery status, and more |
| **fzf** | Fuzzy finder for files, history, and anything else |
| **zoxide** | Smart `cd` that learns your most-used directories |
| **eza** | Modern `ls` replacement with icons and git status |
| **bat** | `cat` with syntax highlighting and line numbers |
| **fd** | Fast, user-friendly alternative to `find` |
| **ripgrep** | Blazingly fast `grep` replacement |

## Quick Install

**One-liner (curl-to-bash):**

```bash
curl -fsSL https://raw.githubusercontent.com/USER/terminal-enhancements/main/install.sh | bash
```

**Or clone and run:**

```bash
git clone https://github.com/USER/terminal-enhancements.git
cd terminal-enhancements
./install.sh
```

The installer will detect your system and install packages using the appropriate package manager.

## Supported Platforms

**Linux:**
- Debian / Ubuntu (and derivatives: Mint, Pop!_OS, etc.)
- Fedora
- RHEL / CentOS / Rocky / Alma
- Arch Linux (and derivatives: Manjaro, EndeavourOS, etc.)

**macOS:**
- Intel and Apple Silicon (via Homebrew)

**Shells:**
- Bash
- Zsh
- Fish

## What Gets Installed

### Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `ls` | `eza --icons` | List files with icons |
| `ll` | `eza -la --git` | Detailed list with git status |
| `lt` | `eza --tree` | Tree view (2 levels deep) |
| `cat` | `bat --paging=never` | Syntax-highlighted file viewer |
| `fd` | `fdfind` | Fast find (Debian/Ubuntu only) |

### Functions

| Function | Description |
|----------|-------------|
| `fcd` | Fuzzy `cd` - interactively jump to any directory |
| `fe` | Fuzzy edit - find and open files in your editor |
| `z <dir>` | Smart `cd` - jump to frecent directories |
| `extract <file>` | Extract any archive (tar, zip, 7z, rar, etc.) |
| `mkcd <dir>` | Create directory and `cd` into it |

### Key Bindings

| Binding | Action |
|---------|--------|
| `Ctrl+R` | Fuzzy search command history |
| `Ctrl+T` | Fuzzy find files in current directory |
| `Alt+C` | Fuzzy `cd` to subdirectory |

## Uninstall

To remove all enhancements and optionally uninstall packages:

```bash
./uninstall.sh
```

The uninstaller will:
- Remove shell configuration files
- Offer to restore backups if they exist
- Optionally uninstall the packages
- Clean up source lines from your shell rc files

## Configuration

Shell enhancement files are installed to:

| Shell | Config File |
|-------|-------------|
| Bash | `~/.bash_enhancements` |
| Zsh | `~/.zsh_enhancements` |
| Fish | `~/.config/fish/conf.d/enhancements.fish` |

Backups are stored in `~/.terminal-enhancements-backup/`.

To customize, edit the enhancement files directly. Your changes will be preserved unless you re-run the installer and choose to overwrite.

## License

MIT License - See [LICENSE](LICENSE) for details.
