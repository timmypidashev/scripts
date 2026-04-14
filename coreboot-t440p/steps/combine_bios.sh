#!/bin/sh
# Step: Combine BIOS chip images into a single ROM

step_combine_bios() {
  section "Combine BIOS Images"

  cd "$WORK_DIR" || return 1

  # Short-circuit if the combined ROM already exists at the right size.
  if [ -f t440p-original.rom ]; then
    _existing=$(wc -c < t440p-original.rom)
    if [ "$_existing" -eq "$SIZE_12MB" ]; then
      info "Existing 12MB ROM found: $WORK_DIR/t440p-original.rom"
      if prompt_yes_default "Use the existing combined ROM?"; then
        success "Using existing t440p-original.rom."
        return 0
      fi
    fi
  fi

  info "Combining 8MB (bottom) + 4MB (top) into a single 12MB ROM..."
  run_cmd "cat 8mb_backup1.bin 4mb_backup1.bin > t440p-original.rom" || return 1

  _size=$(wc -c < t440p-original.rom)
  info "Combined ROM size: $_size bytes"

  if [ "$_size" -eq "$SIZE_12MB" ]; then
    success "ROM size correct (12MB)."
  else
    warn "ROM size is not 12MB ($_size bytes). This may indicate an issue."
    if ! prompt_yes_no "Continue anyway?"; then
      return 1
    fi
  fi

  success "Original BIOS saved: $WORK_DIR/t440p-original.rom"
  echo ""
  warn "Keep this file safe! You will need it if you ever want to revert."
}
