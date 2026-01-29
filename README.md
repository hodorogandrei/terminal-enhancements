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
curl -fsSL https://raw.githubusercontent.com/hodorogandrei/terminal-enhancements/main/install.sh | bash
```

**Or clone and run:**

```bash
git clone https://github.com/hodorogandrei/terminal-enhancements.git
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

---

## Technical Details

### How the Installer Works

1. **System Detection** (`lib/detect.sh`): Identifies your OS via `uname -s`, detects your Linux distribution by parsing `/etc/os-release` (checking both `$ID` and `$ID_LIKE` for derivatives), and finds available shells.

2. **Package Manager Selection**: Priority order is `brew` → `apt` → `dnf` → `yum` → `pacman`. Homebrew takes precedence even on Linux if installed.

3. **Tool Installation** (`lib/packages.sh`): Each tool has a dedicated installer function. For tools not in your distro's repos (common with `eza`, `zoxide` on older systems), the installer automatically falls back to Cargo (Rust's package manager), installing `rustup` first if needed.

4. **Shell Configuration** (`lib/config.sh`): Enhancement files are copied to your home directory, and a source line is added to your shell's rc file (`.bashrc`, `.zshrc`, or `config.fish`).

### Package Name Differences by Distro

| Tool | Binary Name | Debian/Ubuntu Package | Other Distros |
|------|-------------|----------------------|---------------|
| bat | `bat` or `batcat` | `bat` (binary: `batcat`) | `bat` |
| fd | `fd` or `fdfind` | `fd-find` (binary: `fdfind`) | `fd` |
| ripgrep | `rg` | `ripgrep` | `ripgrep` |

The installer creates aliases to normalize these differences across platforms.

### Installation Methods by Tool

| Tool | Primary Method | Fallback |
|------|----------------|----------|
| starship | Package manager (brew/pacman) | [starship.rs](https://starship.rs) install script |
| fzf | Package manager | — |
| zoxide | Package manager | Cargo (`cargo install zoxide`) |
| eza | Package manager | Cargo (`cargo install eza`) |
| bat | Package manager | — |
| fd | Package manager | — |
| ripgrep | Package manager | — |

---

## License

MIT License - See [LICENSE](LICENSE) for details.
