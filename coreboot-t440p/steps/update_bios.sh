#!/bin/sh
# Step: Update coreboot internally (when already running coreboot)

step_update_bios() {
  section "Update Coreboot (Internal Flash)"

  info "This updates your coreboot installation without an external programmer."
  info "Only use this if your T440p is already running coreboot."
  echo ""

  if [ ! -f "$COREBOOT_DIR/build/coreboot.rom" ]; then
    error "coreboot.rom not found. Build coreboot first."
    return 1
  fi

  warn "This will overwrite your current BIOS using internal flashing."
  if ! prompt_yes_no "Continue?"; then
    return 0
  fi

  info "Flashing coreboot internally..."
  run_cmd "sudo flashrom -p internal:laptop=force_I_want_a_brick -w $COREBOOT_DIR/build/coreboot.rom" || return 1

  success "Coreboot updated! Reboot to apply."
}
