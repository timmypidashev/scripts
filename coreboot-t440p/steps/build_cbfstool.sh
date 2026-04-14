#!/bin/sh
# Step: Build cbfstool

step_build_cbfstool() {
  section "Build cbfstool"

  info "Building cbfstool (Coreboot Filesystem tool)..."
  cd "$COREBOOT_DIR" || return 1
  run_cmd "make -C util/cbfstool" || return 1

  if [ ! -f "$COREBOOT_DIR/util/cbfstool/cbfstool" ]; then
    error "cbfstool binary not found after build."
    return 1
  fi

  success "cbfstool built."
}
