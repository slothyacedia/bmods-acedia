#!/usr/bin/env bash
set -euo pipefail

# -----------------------
# Variables
# -----------------------
node=0
git=0
needInstalls=0
persist=0

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
# Install Missing Dependencies (Homebrew)
# -----------------------
if [[ "$needInstalls" -eq 1 ]]; then
  echo "Some Requirements Missing."

  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew Not Found."
    echo "Install It From https://brew.sh And Rerun This Script."
    exit 1
  fi

  echo "Using Homebrew..."
  echo

  [[ "$git" -eq 0 ]] && brew install git
  [[ "$node" -eq 0 ]] && brew install node

  echo
  echo "Dependencies Installed."
fi

# -----------------------
# NPM Install
# -----------------------
echo "Checking For Modules..."
if [[ -d "node_modules" ]]; then
  echo "Node_Modules Folder Exists, Skipping Module Installation..."
else
  echo "Node_Modules Folder Not Found, Running Additional Checks..."
  if [[ -f "package.json" ]]; then
    echo "Package.json Found, Installing Modules..."
    echo
    npm install
    echo
    echo "Modules Installed. Restarting Script..."
    exec "$0" "$@"
  else
    echo "Package.json Not Found, Skipping Module Installation..."
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

echo "All Checks Passed, Starting Bot.js..."

restartBot() {
  node bot.js
  exitCode=$?

  if [[ "$exitCode" -ne 0 ]]; then
    echo "Bot.js Exited With An Error..."
  else
    echo "Bot.js Exited Without An Error..."
  fi

  if [[ "$persist" -eq 1 ]]; then
    echo
    echo "Restarting Bot.js..."
    restartBot
  fi
}

restartBot
