#!/bin/sh
# Step: Verify BIOS backup integrity

step_backup_bios() {
  section "Verify BIOS Backups"

  cd "$WORK_DIR" || return 1

  info "Verifying 4MB chip reads match..."
  if diff 4mb_backup1.bin 4mb_backup2.bin >/dev/null 2>&1; then
    success "4MB chip reads are identical."
  else
    error "4MB chip reads do NOT match!"
    warn "The chip may not be reading reliably. Re-seat the programmer and try again."
    return 1
  fi

  info "Verifying 8MB chip reads match..."
  if diff 8mb_backup1.bin 8mb_backup2.bin >/dev/null 2>&1; then
    success "8MB chip reads are identical."
  else
    error "8MB chip reads do NOT match!"
    warn "The chip may not be reading reliably. Re-seat the programmer and try again."
    return 1
  fi

  # Validate file sizes
  _size_4mb=$(wc -c < 4mb_backup1.bin)
  _size_8mb=$(wc -c < 8mb_backup1.bin)
  info "4MB chip size: $_size_4mb bytes (expected $SIZE_4MB)"
  info "8MB chip size: $_size_8mb bytes (expected $SIZE_8MB)"

  if [ "$_size_4mb" -ne "$SIZE_4MB" ]; then
    warn "4MB chip size mismatch. Expected $SIZE_4MB bytes, got $_size_4mb."
    if ! prompt_yes_no "Continue anyway?"; then
      return 1
    fi
  fi

  if [ "$_size_8mb" -ne "$SIZE_8MB" ]; then
    warn "8MB chip size mismatch. Expected $SIZE_8MB bytes, got $_size_8mb."
    if ! prompt_yes_no "Continue anyway?"; then
      return 1
    fi
  fi

  success "All BIOS backups verified."
}
