#!/usr/bin/env bash
#
# webcat installer — installs dependencies (defuddle, glow, chafa) and the
# webcat script itself. Supports Termux, Debian/Ubuntu, Fedora, Arch, and macOS.
#
#   ./install.sh            # install deps + webcat to ~/.local/bin
#   PREFIX=/usr/local ./install.sh   # install webcat to /usr/local/bin instead
#
set -euo pipefail

BIN_DIR="${PREFIX:-$HOME/.local}/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarning:\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

# ---- detect package manager -------------------------------------------------
PM=""
if have pkg && [ -n "${PREFIX:-}" ] && case "${PREFIX:-}" in *com.termux*) true;; *) false;; esac; then
    PM="termux"
elif [ -n "${TERMUX_VERSION:-}" ] || case "$(command -v pkg || true)" in *com.termux*) true;; *) false;; esac; then
    PM="termux"
elif have apt-get; then PM="apt"
elif have dnf;     then PM="dnf"
elif have pacman;  then PM="pacman"
elif have brew;    then PM="brew"
fi
say "Package manager: ${PM:-none detected}"

pm_install() {
    local pkg="$1"
    case "$PM" in
        termux) pkg install -y "$pkg" ;;
        apt)    sudo apt-get update -qq && sudo apt-get install -y "$pkg" ;;
        dnf)    sudo dnf install -y "$pkg" ;;
        pacman) sudo pacman -S --noconfirm "$pkg" ;;
        brew)   brew install "$pkg" ;;
        *)      return 1 ;;
    esac
}

# ---- python3 ----------------------------------------------------------------
if ! have python3; then
    say "Installing python3..."
    pm_install python || pm_install python3 || err "install python3 manually"
fi

# ---- glow (markdown text renderer) ------------------------------------------
if have glow; then
    say "glow already installed"
else
    say "Installing glow..."
    pm_install glow || warn "Could not install glow automatically — see https://github.com/charmbracelet/glow"
fi

# ---- chafa (terminal image renderer) ----------------------------------------
if have chafa; then
    say "chafa already installed"
else
    say "Installing chafa..."
    pm_install chafa || warn "Could not install chafa automatically — see https://hpjansson.org/chafa/"
fi

# ---- defuddle (URL -> clean markdown, via npm) ------------------------------
if have defuddle; then
    say "defuddle already installed"
elif have npm; then
    say "Installing defuddle (npm)..."
    npm install -g defuddle || warn "npm install defuddle failed"
    # Termux ships no /usr/bin/env, so fix the CLI shebang if needed.
    if [ "$PM" = "termux" ] && have termux-fix-shebang && have defuddle; then
        termux-fix-shebang "$(readlink -f "$(command -v defuddle)")" || true
    fi
else
    warn "npm not found — defuddle (needed for URLs) not installed. Local .md files still work."
fi

# ---- install webcat ---------------------------------------------------------
mkdir -p "$BIN_DIR"
install -m 755 "$SCRIPT_DIR/webcat" "$BIN_DIR/webcat"
say "Installed webcat -> $BIN_DIR/webcat"

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) warn "$BIN_DIR is not on your PATH. Add this to your shell rc:"
       printf '       export PATH="%s:$PATH"\n' "$BIN_DIR" ;;
esac

# ---- summary ----------------------------------------------------------------
echo
say "Done. Dependency status:"
for t in python3 glow chafa defuddle; do
    if have "$t"; then printf '   \033[32m✓\033[0m %s\n' "$t"
    else               printf '   \033[31m✗\033[0m %s (missing)\n' "$t"; fi
done
echo
echo "Try:  webcat https://github.com/alibaba/page-agent"
