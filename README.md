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
curl -fsSL https://raw.githubusercontent.com/hodorogandrei/terminal-enhancements/refs/heads/master/install.sh | bash
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

## Troubleshooting

### Installation Issues

#### "Permission denied" errors

The installer uses `sudo` for system package managers. Ensure you have sudo privileges:

```bash
# Check sudo access
sudo -v

# If sudo is not configured, you may need to:
# 1. Add yourself to the sudo/wheel group
# 2. Or run specific package commands manually with root
```

#### "Package not found" for eza or zoxide

Older distributions (Ubuntu < 24.04, Debian < 12, Fedora < 38) may not have `eza` or `zoxide` in their repos. The installer will automatically attempt to install via Cargo:

```bash
# If Cargo fallback fails, install Rust manually:
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Then install the tool:
cargo install eza
cargo install zoxide
```

#### starship fails to install

On non-Homebrew/non-Arch systems, starship uses its own install script. If that fails:

```bash
# Manual installation
curl -sS https://starship.rs/install.sh | sh

# Or via Cargo (slower, compiles from source):
cargo install starship

# Or download binary directly from GitHub releases:
# https://github.com/starship/starship/releases
```

#### curl-to-bash fails with "git: command not found"

The curl-to-bash installer requires `git` to clone the repository. Install git first:

```bash
# Debian/Ubuntu
sudo apt-get install git

# Fedora
sudo dnf install git

# Arch
sudo pacman -S git

# macOS (installs Xcode CLI tools)
xcode-select --install
```

### Post-Installation Issues

#### Enhancements not working after install

Shell configurations only load on new shell sessions. Either:

```bash
# Reload your current shell:
source ~/.bashrc     # for bash
source ~/.zshrc      # for zsh
source ~/.config/fish/config.fish  # for fish

# Or start a new terminal session
exec $SHELL
```

#### Icons not displaying (showing boxes or question marks)

`eza` requires a Nerd Font for icons. Install one:

```bash
# Option 1: Download from https://www.nerdfonts.com/
# Recommended: "JetBrainsMono Nerd Font" or "FiraCode Nerd Font"

# Option 2: On macOS with Homebrew
brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono-nerd-font

# Option 3: On Arch Linux
sudo pacman -S ttf-jetbrains-mono-nerd

# Then set your terminal emulator to use the Nerd Font
```

If you don't want icons, edit `~/.bash_enhancements` (or equivalent) and remove the `--icons` flag from the `eza` aliases.

#### `bat` command not found (Debian/Ubuntu)

On Debian/Ubuntu, the binary is named `batcat` to avoid conflict with another package. The installer creates an alias, but if it's not working:

```bash
# Check if batcat is installed:
which batcat

# Add alias manually to your ~/.bashrc or ~/.zshrc:
alias bat='batcat'

# Or create a symlink:
mkdir -p ~/.local/bin
ln -s /usr/bin/batcat ~/.local/bin/bat
export PATH="$HOME/.local/bin:$PATH"
```

#### `fd` command not found (Debian/Ubuntu)

Similar to `bat`, Debian/Ubuntu uses `fdfind`:

```bash
# Check if fdfind is installed:
which fdfind

# Add alias manually:
alias fd='fdfind'

# Or create a symlink:
ln -s /usr/bin/fdfind ~/.local/bin/fd
```

#### `z` command doesn't work (zoxide)

Zoxide needs to learn your directories first. Use `cd` normally for a while, then `z` will start suggesting directories based on frequency and recency ("frecency").

```bash
# Check if zoxide is initialized:
zoxide --version

# Force initialization (should happen automatically):
eval "$(zoxide init bash)"   # for bash
eval "$(zoxide init zsh)"    # for zsh

# In fish, it should auto-initialize via the config
```

#### Ctrl+R history search not working (fzf)

Ensure fzf key bindings are loaded:

```bash
# For bash, add to ~/.bashrc:
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
# Or if using the package manager version:
source /usr/share/fzf/key-bindings.bash  # Debian/Ubuntu
source /usr/share/fzf/shell/key-bindings.bash  # Fedora

# For zsh, add to ~/.zshrc:
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# Or:
source /usr/share/fzf/key-bindings.zsh

# For fish:
fzf --fish | source
```

#### starship prompt not appearing

Ensure the init script is in your shell config:

```bash
# For bash (~/.bashrc):
eval "$(starship init bash)"

# For zsh (~/.zshrc):
eval "$(starship init zsh)"

# For fish (~/.config/fish/config.fish):
starship init fish | source
```

If starship is installed via the install script, ensure `/usr/local/bin` is in your PATH:

```bash
export PATH="/usr/local/bin:$PATH"
```

### Conflict Resolution

#### Existing configuration files

When running the installer with existing enhancement files, you'll be prompted:
- **[y]es**: Overwrite (creates backup first in `~/.terminal-enhancements-backup/`)
- **[N]o**: Skip this file (keep your existing configuration)
- **[d]iff**: Show differences before deciding

#### Restoring backups

Backups are timestamped in `~/.terminal-enhancements-backup/`:

```bash
# List backups:
ls -la ~/.terminal-enhancements-backup/

# Manually restore a backup:
cp ~/.terminal-enhancements-backup/.bash_enhancements.2024-01-15_143022 ~/.bash_enhancements

# Or use the uninstaller which offers backup restoration
./uninstall.sh
```

### Uninstallation Issues

#### Uninstaller can't find lib/detect.sh

Run the uninstaller from the terminal-enhancements directory:

```bash
cd /path/to/terminal-enhancements
./uninstall.sh
```

#### Aliases still active after uninstall

Restart your shell completely:

```bash
exec $SHELL -l  # Start a new login shell
# Or simply close and reopen your terminal
```

If aliases persist, check if source lines remain in your rc files:

```bash
# Check for leftover configuration:
grep -n "terminal-enhancements\|bash_enhancements\|zsh_enhancements" ~/.bashrc ~/.zshrc 2>/dev/null

# Manually remove any remaining lines
```

### Platform-Specific Notes

#### macOS: Homebrew not found

Install Homebrew first:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# For Apple Silicon, add to PATH:
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

#### WSL (Windows Subsystem for Linux)

The installer works in WSL. For best results:
- Use WSL2 (better performance)
- Install a Nerd Font in Windows Terminal settings
- If using VS Code, set terminal font in settings

#### SSH sessions without color/icons

Remote SSH sessions may not support colors or icon fonts:

```bash
# Check terminal capabilities:
echo $TERM  # Should be xterm-256color or similar

# Set TERM if needed:
export TERM=xterm-256color
```

### Getting Help

- **GitHub Issues**: [https://github.com/hodorogandrei/terminal-enhancements/issues](https://github.com/hodorogandrei/terminal-enhancements/issues)
- **Tool Documentation**:
  - [starship](https://starship.rs/config/)
  - [fzf](https://github.com/junegunn/fzf#usage)
  - [zoxide](https://github.com/ajeetdsouza/zoxide#usage)
  - [eza](https://github.com/eza-community/eza#usage)
  - [bat](https://github.com/sharkdp/bat#usage)
  - [fd](https://github.com/sharkdp/fd#usage)
  - [ripgrep](https://github.com/BurntSushi/ripgrep#usage)

---

## License

MIT License - See [LICENSE](LICENSE) for details.
