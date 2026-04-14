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

# --- Inline image rendering ---

# Base URL for blog assets (override via env if needed).
IMAGE_BASE_URL="${IMAGE_BASE_URL:-https://timmypidashev.dev/blog/thinkpad-t440p-coreboot-guide}"

# Attempt to render $1 inline. Returns 0 on success, 1 if no supported backend.
_render_image() {
  _path="$1"

  # chafa handles kitty / iterm2 / sixel / ANSI fallback automatically
  if check_command chafa; then
    chafa --size=60x25 "$_path" 2>/dev/null && return 0
  fi

  # Native kitty icat
  if [ -n "$KITTY_WINDOW_ID" ] && check_command kitty; then
    kitty +kitten icat --align=left "$_path" 2>/dev/null && return 0
  fi

  # iTerm2 / WezTerm inline image protocol
  case "$TERM_PROGRAM" in
    iTerm.app|WezTerm)
      if check_command base64; then
        _b64=$(base64 < "$_path" | tr -d '\n')
        _sz=$(wc -c < "$_path")
        printf '\033]1337;File=inline=1;size=%s:%s\a\n' "$_sz" "$_b64"
        return 0
      fi
      ;;
  esac

  return 1
}

# Transcode a webp file to png next to it. Echoes the png path on success.
_webp_to_png() {
  _webp="$1"
  _png="${_webp%.webp}.png"

  [ -f "$_png" ] && { printf '%s' "$_png"; return 0; }

  if check_command dwebp; then
    dwebp "$_webp" -o "$_png" >/dev/null 2>&1 && {
      printf '%s' "$_png"; return 0;
    }
  fi
  if check_command magick; then
    magick "$_webp" "$_png" >/dev/null 2>&1 && {
      printf '%s' "$_png"; return 0;
    }
  fi
  if check_command convert; then
    convert "$_webp" "$_png" >/dev/null 2>&1 && {
      printf '%s' "$_png"; return 0;
    }
  fi

  return 1
}

# show_image <filename> [caption]
#   Downloads $IMAGE_BASE_URL/<filename> into $WORK_DIR/.images/,
#   renders inline if possible, otherwise prints the URL.
#   If the image is webp and the renderer can't decode it, transcodes to png.
show_image() {
  _name="$1"
  _caption="$2"
  _url="$IMAGE_BASE_URL/$_name"
  _cache="${WORK_DIR:-/tmp}/.images"
  _local="$_cache/$_name"

  mkdir -p "$_cache"

  if [ ! -f "$_local" ]; then
    if ! curl -fsSL "$_url" -o "$_local" 2>/dev/null; then
      rm -f "$_local"
      info "Reference image: $_url"
      [ -n "$_caption" ] && info "$_caption"
      return 1
    fi
  fi

  # First attempt: render the file as-is.
  if _render_image "$_local"; then
    [ -n "$_caption" ] && printf "  ${DIM}%s${NC}\n" "$_caption"
    return 0
  fi

  # Fallback: if webp, try to transcode to png and re-render.
  case "$_name" in
    *.webp)
      _png=$(_webp_to_png "$_local")
      if [ -n "$_png" ] && _render_image "$_png"; then
        [ -n "$_caption" ] && printf "  ${DIM}%s${NC}\n" "$_caption"
        return 0
      fi
      ;;
  esac

  # No renderer / transcode available — degrade to URL.
  info "Reference image: $_url"
  if ! check_command chafa; then
    info "(Install 'chafa' for inline image previews)"
  elif case "$_name" in *.webp) true ;; *) false ;; esac; then
    info "(Install 'libwebp' (dwebp) or 'imagemagick' to preview webp inline)"
  fi
  [ -n "$_caption" ] && info "$_caption"
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
