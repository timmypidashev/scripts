#!/bin/sh
# Step: Revert to original BIOS

step_revert_bios() {
  section "Revert to Original BIOS"

  if [ ! -f "$ORIGINAL_ROM" ]; then
    error "Original ROM not found: $ORIGINAL_ROM"
    error "Cannot revert without the original backup."
    return 1
  fi

  echo "  How would you like to revert?"
  echo ""
  echo "  1) Can't boot  - Use external CH341A programmer"
  echo "  2) Can boot     - Flash internally (requires iomem=relaxed)"
  echo "  3) Cancel"
  echo ""

  printf "${CYAN}Choice [1-3]:${NC} "
  read -r _choice

  case "$_choice" in
    1) _revert_external ;;
    2) _revert_internal ;;
    *) info "Revert cancelled."; return 0 ;;
  esac
}

_revert_external() {
  info "Reverting via external programmer..."
  echo ""

  cd "$WORK_DIR" || return 1

  # Split original ROM for both chips
  info "Splitting original ROM..."
  run_cmd "dd if=t440p-original.rom of=bottom.rom bs=1M count=8" || return 1
  run_cmd "dd if=t440p-original.rom of=top.rom bs=1M skip=8" || return 1

  _b=$(wc -c < bottom.rom)
  _t=$(wc -c < top.rom)
  if [ "$_b" -ne "$SIZE_8MB" ] || [ "$_t" -ne "$SIZE_4MB" ]; then
    error "Split sizes wrong (bottom=$_b, top=$_t). Aborting."
    return 1
  fi

  # Flash 4MB (top) chip
  info "Attach the programmer to the 4MB (top) chip."
  prompt_continue

  if [ -z "$CHIP_4MB" ]; then
    _resolve_chip CHIP_4MB || return 1
  fi
  info "Flashing original 4MB chip ($CHIP_4MB)..."
  run_cmd "sudo flashrom --programmer ch341a_spi -c \"$CHIP_4MB\" -w top.rom" || return 1
  success "4MB chip restored."

  # Flash 8MB (bottom) chip
  echo ""
  info "Now attach the programmer to the 8MB (bottom) chip."
  prompt_continue

  if [ -z "$CHIP_8MB" ]; then
    _resolve_chip CHIP_8MB || return 1
  fi
  info "Flashing original 8MB chip ($CHIP_8MB)..."
  run_cmd "sudo flashrom --programmer ch341a_spi -c \"$CHIP_8MB\" -w bottom.rom" || return 1
  success "8MB chip restored."

  echo ""
  success "Original BIOS restored! Reassemble and power on."
}

_revert_internal() {
  info "Reverting via internal flash..."
  echo ""

  warn "This requires the kernel parameter iomem=relaxed."
  echo ""

  if prompt_yes_default "Set iomem=relaxed in GRUB and reboot first?"; then
    info "Adding iomem=relaxed to GRUB config..."
    run_cmd "sudo sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/ s/\"/ iomem=relaxed\"/2' /etc/default/grub" || return 1
    run_cmd "sudo grub-mkconfig -o /boot/grub/grub.cfg" || return 1
    echo ""
    warn "You must reboot now for iomem=relaxed to take effect."
    info "After rebooting, run this script again and choose the internal revert option."
    return 0
  fi

  info "Flashing original BIOS internally..."
  run_cmd "sudo flashrom -p internal:laptop=force_I_want_a_brick -w $ORIGINAL_ROM" || return 1

  success "Original BIOS restored! Reboot to apply."
  echo ""
  warn "Remember to remove iomem=relaxed from your GRUB config after reverting."
}
