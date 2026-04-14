#!/bin/sh
# Step: Flash coreboot to the T440p

step_flash_bios() {
  section "Flash Coreboot"

  cd "$COREBOOT_DIR/build" || return 1

  if [ ! -f "coreboot.rom" ]; then
    error "coreboot.rom not found. Run the build step first."
    return 1
  fi

  # Split the ROM
  info "Splitting ROM for 8MB (bottom) and 4MB (top) chips..."
  run_cmd "dd if=coreboot.rom of=bottom.rom bs=1M count=8" || return 1
  run_cmd "dd if=coreboot.rom of=top.rom bs=1M skip=8" || return 1

  _bottom_size=$(wc -c < bottom.rom)
  _top_size=$(wc -c < top.rom)
  info "bottom.rom: $_bottom_size bytes (expected $SIZE_8MB)"
  info "top.rom: $_top_size bytes (expected $SIZE_4MB)"

  if [ "$_bottom_size" -ne "$SIZE_8MB" ] || [ "$_top_size" -ne "$SIZE_4MB" ]; then
    error "Split ROM sizes wrong. Refusing to flash."
    return 1
  fi

  echo ""
  warn "You are about to flash coreboot onto your T440p."
  warn "Make sure your laptop is powered off and the battery is removed."
  warn "DO NOT interrupt the flashing process!"
  echo ""

  if ! prompt_yes_no "Ready to flash?"; then
    info "Flash cancelled."
    return 0
  fi

  # Flash 4MB (top) chip
  echo ""
  info "Attach the programmer to the 4MB (top) chip."
  prompt_continue

  info "Flashing 4MB chip..."
  run_cmd "sudo flashrom --programmer ch341a_spi -w top.rom" || return 1
  success "4MB chip flashed."

  # Flash 8MB (bottom) chip
  echo ""
  info "Now attach the programmer to the 8MB (bottom) chip."
  prompt_continue

  info "Flashing 8MB chip..."
  run_cmd "sudo flashrom --programmer ch341a_spi -w bottom.rom" || return 1
  success "8MB chip flashed."

  echo ""
  success "Coreboot has been flashed successfully!"
  echo ""
  info "Reassemble your laptop and power it on."
  info "If everything went well, you should see coreboot boot!"
}
