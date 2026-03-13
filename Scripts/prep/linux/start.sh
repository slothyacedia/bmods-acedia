#!/usr/bin/env bash
set -euo pipefail

scriptDir="$(cd "$(dirname "$0")" && pwd)"
cd "$scriptDir"

# -----------------------
# Variables
# -----------------------
node=0
git=0
needInstalls=0
persist=0
logging=0

echo "Running Checks..."
echo

# -----------------------
# Parse Arguments
# -----------------------
for arg in "$@"; do
  case "$arg" in
    -p|--persist)
      persist=1
      ;;
  esac
done

# -----------------------
# Check Node.js
# -----------------------
echo "Checking For Node.js..."
if command -v node >/dev/null 2>&1; then
  echo "Node.js Detected"
  node=1
else
  echo "Node.js Missing"
  needInstalls=1
fi
echo

# -----------------------
# Check git
# -----------------------
echo "Checking For git..."
if command -v git >/dev/null 2>&1; then
  echo "git Detected"
  git=1
else
  echo "git Missing"
  needInstalls=1
fi
echo

# -----------------------
# Install Missing Dependencies
# -----------------------
if [[ "$needInstalls" -eq 1 ]]; then
  echo "Some Requirements Missing."

  if command -v apt >/dev/null 2>&1; then
    PKG="apt"
  elif command -v dnf >/dev/null 2>&1; then
    PKG="dnf"
  elif command -v pacman >/dev/null 2>&1; then
    PKG="pacman"
  else
    echo "No Supported Package Manager Found."
    echo "Install Node.js And git Manually."
    exit 1
  fi

  echo "Using Package Manager: $PKG"
  echo

  if [[ "$PKG" == "apt" ]]; then
    sudo apt update
    [[ "$node" -eq 0 ]] && sudo apt install -y nodejs npm
    [[ "$git" -eq 0 ]] && sudo apt install -y git
  elif [[ "$PKG" == "dnf" ]]; then
    [[ "$node" -eq 0 ]] && sudo dnf install -y nodejs
    [[ "$git" -eq 0 ]] && sudo dnf install -y git
  elif [[ "$PKG" == "pacman" ]]; then
    [[ "$node" -eq 0 ]] && sudo pacman -S --noconfirm nodejs npm
    [[ "$git" -eq 0 ]] && sudo pacman -S --noconfirm git
  fi

  echo
  echo "Dependencies Installed."
fi

# -----------------------
# NPM Install
# -----------------------
echo "Checking For Modules..."
if [[ -d "node_modules" ]]; then
  echo "node_modules Folder Exists, Skipping Module Installation..."
else
  echo "node_modules Folder Not Found, Running Additional Checks..."
  if [[ -f "package.json" ]]; then
    echo "package.json Found, Installing Modules..."
    echo
    npm install
    echo
    echo "Modules Installed. Restarting Script..."
    exec "$0" "$@"
  else
    echo "package.json Not Found, Skipping Module Installation..."
  fi
fi
echo

# -----------------------
# Start Bot
# -----------------------
clear

if [[ "$persist" -eq 1 ]]; then
  echo "Persist Enabled..."
else
  echo "Persist Disabled..."
  echo "To Enable Persist, Start The Script With -p"
fi
echo

echo "All Checks Passed, Starting bot.js..."

restartBot() {
  mkdir -p logs
  logFile="logs/$(date '+%Y-%m-%d_%H-%M-%S').log"

  node bot.js 2>&1 | tee -a "$logFile"
  exitCode=${PIPESTATUS[0]}

  if [[ "$exitCode" -ne 0 ]]; then
    echo "bot.js Exited With An Error..."
  else
    echo "bot.js Exited Without An Error..."
  fi

  if [[ "$persist" -eq 1 ]]; then
    echo
    echo "Restarting bot.js..."
    restartBot
  fi
}

restartBot
