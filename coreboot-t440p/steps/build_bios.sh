#!/bin/sh
# Step: Build coreboot

step_build_bios() {
  section "Build Coreboot"

  cd "$COREBOOT_DIR" || return 1

  if [ ! -f ".config" ]; then
    error "No .config found. Run the configure step first."
    return 1
  fi

  _nproc=$(nproc 2>/dev/null || echo 1)

  # Build the cross-compiler
  info "Building cross-compiler toolchain (this will take a while)..."
  info "Using $_nproc parallel jobs."
  run_cmd "make crossgcc-i386 CPUS=$_nproc" || return 1
  success "Cross-compiler ready."

  # Build coreboot
  echo ""
  info "Building coreboot..."
  run_cmd "make -j$_nproc" || return 1

  if [ ! -f "$COREBOOT_DIR/build/coreboot.rom" ]; then
    error "coreboot.rom not found after build."
    return 1
  fi

  _size=$(wc -c < "$COREBOOT_DIR/build/coreboot.rom")
  success "Build complete: $COREBOOT_DIR/build/coreboot.rom ($_size bytes)"
}
