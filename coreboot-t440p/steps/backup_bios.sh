#!/bin/sh
# Step: Verify BIOS backup integrity (with per-chip retry)

# Re-read a single chip until two reads match or user gives up
_reread_chip() {
  _label="$1"   # "4mb" or "8mb"
  _desc="$2"    # human-readable description

  while true; do
    warn "$_desc reads do NOT match. The chip may not be reading reliably."
    echo ""
    echo "  1) Re-seat programmer on $_desc chip and retry"
    echo "  2) Abort"
    echo ""
    printf "${CYAN}Choice [1-2]:${NC} "
    read -r _choice
    case "$_choice" in
      1)
        info "Re-reading $_desc chip (read 1 of 2)..."
        run_cmd "sudo flashrom --programmer ch341a_spi -r ${_label}_backup1.bin" || return 1
        info "Re-reading $_desc chip (read 2 of 2)..."
        run_cmd "sudo flashrom --programmer ch341a_spi -r ${_label}_backup2.bin" || return 1
        if diff "${_label}_backup1.bin" "${_label}_backup2.bin" >/dev/null 2>&1; then
          success "$_desc reads now match."
          return 0
        fi
        ;;
      *)
        return 1
        ;;
    esac
  done
}

step_backup_bios() {
  section "Verify BIOS Backups"

  cd "$WORK_DIR" || return 1

  info "Verifying 4MB chip reads match..."
  if diff 4mb_backup1.bin 4mb_backup2.bin >/dev/null 2>&1; then
    success "4MB chip reads are identical."
  else
    _reread_chip "4mb" "4MB (top)" || return 1
  fi

  info "Verifying 8MB chip reads match..."
  if diff 8mb_backup1.bin 8mb_backup2.bin >/dev/null 2>&1; then
    success "8MB chip reads are identical."
  else
    _reread_chip "8mb" "8MB (bottom)" || return 1
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
