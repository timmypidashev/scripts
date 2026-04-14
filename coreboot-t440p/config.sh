#!/bin/sh
# Configuration for coreboot-t440p interactive script

# Paths
WORK_DIR="${WORK_DIR:-$HOME/t440p-coreboot}"
COREBOOT_DIR="$WORK_DIR/coreboot"

# The coreboot commit known to work with this guide
COREBOOT_COMMIT="e1e762716cf925c621d58163133ed1c3e006a903"

# Blob paths (populated after extraction)
BLOB_IFD="$WORK_DIR/ifd.bin"
BLOB_ME="$WORK_DIR/me.bin"
BLOB_GBE="$WORK_DIR/gbe.bin"
BLOB_MRC="$WORK_DIR/mrc.bin"
ORIGINAL_ROM="$WORK_DIR/t440p-original.rom"

# Expected ROM sizes in bytes
SIZE_4MB=4194304
SIZE_8MB=8388608
SIZE_12MB=12582912

# Resolved flashrom chip names (set at runtime by _resolve_chip).
# Needed because some Winbond variants share a silicon ID and flashrom
# refuses to pick one without an explicit -c <chipname>.
CHIP_4MB="${CHIP_4MB:-}"
CHIP_8MB="${CHIP_8MB:-}"

# Detect the Linux distribution
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
      arch|manjaro|endeavouros|artix|garuda)
        DISTRO="arch" ;;
      debian|ubuntu|pop|linuxmint|elementary|zorin|kali)
        DISTRO="debian" ;;
      fedora|centos|rhel|rocky|alma|nobara)
        DISTRO="fedora" ;;
      gentoo|funtoo)
        DISTRO="gentoo" ;;
      nixos)
        DISTRO="nix" ;;
      *)
        DISTRO="unknown" ;;
    esac
  elif command -v nix-env >/dev/null 2>&1; then
    DISTRO="nix"
  elif command -v pacman >/dev/null 2>&1; then
    DISTRO="arch"
  elif command -v apt >/dev/null 2>&1; then
    DISTRO="debian"
  elif command -v dnf >/dev/null 2>&1; then
    DISTRO="fedora"
  elif command -v emerge >/dev/null 2>&1; then
    DISTRO="gentoo"
  else
    DISTRO="unknown"
  fi

  export DISTRO
}

# Create working directory
setup_work_dir() {
  if [ ! -d "$WORK_DIR" ]; then
    mkdir -p "$WORK_DIR"
  fi
}
