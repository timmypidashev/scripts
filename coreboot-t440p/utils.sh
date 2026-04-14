#!/bin/sh
# Utility functions for coreboot-t440p interactive script

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Logging
info()    { printf "${BLUE}[*]${NC} %s\n" "$1"; }
warn()    { printf "${YELLOW}[!]${NC} %s\n" "$1"; }
error()   { printf "${RED}[x]${NC} %s\n" "$1"; }
success() { printf "${GREEN}[+]${NC} %s\n" "$1"; }

# Print a section header
section() {
  printf "\n${BOLD}${PURPLE}--- %s ---${NC}\n\n" "$1"
}

# Prompt user to continue or quit
prompt_continue() {
  printf "\n${CYAN}Press Enter to continue (or 'q' to quit)...${NC} "
  read -r _response
  case "$_response" in
    q|Q) echo "Exiting."; exit 0 ;;
  esac
}

# Prompt yes/no, default no
prompt_yes_no() {
  printf "${CYAN}%s [y/N]:${NC} " "$1"
  read -r _response
  case "$_response" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

# Prompt yes/no, default yes
prompt_yes_default() {
  printf "${CYAN}%s [Y/n]:${NC} " "$1"
  read -r _response
  case "$_response" in
    [nN]|[nN][oO]) return 1 ;;
    *) return 0 ;;
  esac
}

# Prompt for a value with a default
prompt_value() {
  printf "${CYAN}%s [%s]:${NC} " "$1" "$2"
  read -r _response
  if [ -z "$_response" ]; then
    echo "$2"
  else
    echo "$_response"
  fi
}

# Check if a command is available
check_command() {
  command -v "$1" >/dev/null 2>&1
}

# Run a command with display
run_cmd() {
  printf "  ${DIM}\$ %s${NC}\n" "$1"
  eval "$1"
  _status=$?
  if [ $_status -ne 0 ]; then
    error "Command failed (exit code $_status)"
  fi
  return $_status
}

# Handle step failure - ask user how to proceed
handle_failure() {
  echo ""
  error "Step failed: $1"
  echo ""
  echo "  1) Retry this step"
  echo "  2) Skip and continue"
  echo "  3) Quit"
  echo ""
  printf "${CYAN}Choice [1-3]:${NC} "
  read -r _choice
  case "$_choice" in
    1) return 1 ;; # Signal retry
    2) return 0 ;; # Signal skip
    *) exit 1 ;;
  esac
}
