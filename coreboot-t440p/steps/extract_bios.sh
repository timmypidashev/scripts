#!/bin/sh
# Step: Extract original BIOS from both EEPROM chips

step_extract_bios() {
  section "Extract Original BIOS"

  info "The T440p has two EEPROM chips that need to be read:"
  echo "  - 4MB (top) chip"
  echo "  - 8MB (bottom) chip"
  echo ""
  info "Each chip will be read twice to verify data integrity."
  warn "Make sure the programmer is attached to the correct chip!"

  cd "$WORK_DIR" || return 1

  # --- 4MB chip ---
  echo ""
  info "Attach the programmer to the 4MB (top) chip."
  prompt_continue

  info "Reading 4MB chip (read 1 of 2)..."
  run_cmd "sudo flashrom --programmer ch341a_spi -r 4mb_backup1.bin" || return 1

  info "Reading 4MB chip (read 2 of 2)..."
  run_cmd "sudo flashrom --programmer ch341a_spi -r 4mb_backup2.bin" || return 1

  success "4MB chip reads complete."

  # --- 8MB chip ---
  echo ""
  info "Now attach the programmer to the 8MB (bottom) chip."
  prompt_continue

  info "Reading 8MB chip (read 1 of 2)..."
  run_cmd "sudo flashrom --programmer ch341a_spi -r 8mb_backup1.bin" || return 1

  info "Reading 8MB chip (read 2 of 2)..."
  run_cmd "sudo flashrom --programmer ch341a_spi -r 8mb_backup2.bin" || return 1

  success "8MB chip reads complete."
}
