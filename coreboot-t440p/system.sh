#!/bin/sh
# System dependency installation for coreboot-t440p

install_dependencies() {
  section "Installing Dependencies"

  case "$DISTRO" in
    arch)
      info "Installing packages via pacman..."
      run_cmd "sudo pacman -S --needed base-devel curl git gcc-ada ncurses zlib nasm sharutils unzip flashrom usbutils chafa libwebp"
      ;;
    debian)
      info "Installing packages via apt..."
      run_cmd "sudo apt update"
      run_cmd "sudo apt install -y build-essential curl git gnat libncurses-dev zlib1g-dev nasm sharutils unzip flashrom usbutils chafa webp"
      ;;
    fedora)
      info "Installing packages via dnf..."
      run_cmd "sudo dnf install -y @development-tools curl git gcc-gnat ncurses-devel zlib-devel nasm sharutils unzip flashrom usbutils chafa libwebp-tools"
      ;;
    gentoo)
      info "Installing packages via emerge..."
      run_cmd "sudo emerge --ask sys-devel/base-devel net-misc/curl dev-vcs/git sys-devel/gcc ncurses dev-libs/zlib dev-lang/nasm app-arch/sharutils app-arch/unzip sys-apps/flashrom sys-apps/usbutils media-gfx/chafa media-libs/libwebp"
      ;;
    nix)
      info "Installing packages via nix-env..."
      run_cmd "nix-env -i stdenv curl git gcc gnat ncurses zlib nasm sharutils unzip flashrom usbutils chafa libwebp"
      ;;
    *)
      warn "Could not detect your distribution."
      echo ""
      echo "  Please install these packages manually:"
      echo "    build-essential/base-devel, curl, git, gcc-ada/gnat,"
      echo "    ncurses, zlib, nasm, sharutils, unzip, flashrom, usbutils"
      echo "  Optional: chafa (for inline image previews in this script)"
      echo ""
      prompt_continue
      return 0
      ;;
  esac

  echo ""
  _missing=0
  for _cmd in git make gcc flashrom; do
    if check_command "$_cmd"; then
      success "$_cmd found"
    else
      error "$_cmd not found"
      _missing=1
    fi
  done

  if [ "$_missing" -eq 1 ]; then
    error "Some required tools are missing. Please install them before continuing."
    return 1
  fi

  success "All dependencies installed."
}
