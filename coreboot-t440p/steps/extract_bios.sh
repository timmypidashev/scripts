#!/bin/sh
# Step: Extract original BIOS from both EEPROM chips
#
# Order rationale: read 4MB (top) chip first — smaller, faster,
# surfaces setup issues (clip alignment, voltage, ribbon) sooner.

# Read a chip with inline retry on failure.
#   $1 = output filename
#   $2 = human label (e.g. "4MB (top) — read 1 of 2")
_read_with_retry() {
  _out="$1"
  _label="$2"

  while true; do
    info "Reading $_label ..."
    if run_cmd "sudo flashrom --programmer ch341a_spi -r $_out"; then
      return 0
    fi

    echo ""
    warn "Read failed. Most common causes:"
    echo "    - Clip not seated flush on chip (try pressing down gently)"
    echo "    - Pin 1 misaligned (red wire must match chip's dot/notch)"
    echo "    - Laptop still has residual power (remove battery + CMOS)"
    echo "    - Cheap SOIC-8 clips can make intermittent contact"
    echo ""
    echo "  1) Re-seat clip and retry"
    echo "  2) Abort"
    echo ""
    printf "${CYAN}Choice [1-2]:${NC} "
    read -r _choice
    case "$_choice" in
      1) continue ;;
      *) return 1 ;;
    esac
  done
}

step_extract_bios() {
  section "Extract Original BIOS"

  info "The T440p has two EEPROM chips beside the SODIMM slots:"
  echo "  - 4MB (top)    — smaller SOIC-8, farther from CPU"
  echo "  - 8MB (bottom) — larger SOIC-8, closer to CPU (holds ME firmware)"
  echo ""
  info "Each chip is read twice so we can diff the results and catch flaky reads."
  echo ""

  cd "$WORK_DIR" || return 1

  # --- 4MB chip (do first: smaller = faster iteration on setup) ---
  echo ""
  show_image "eeprom_chip_4mb.webp" "Reference: 4MB (top) chip location on T440p"
  echo ""
  info "Clip the CH341A onto the ${BOLD}4MB (top)${NC} chip shown above."
  info "Align the red ribbon wire with the dot/notch on the chip (pin 1)."
  prompt_continue

  _read_with_retry "4mb_backup1.bin" "4MB chip (read 1 of 2)" || return 1
  _read_with_retry "4mb_backup2.bin" "4MB chip (read 2 of 2)" || return 1
  success "4MB chip reads complete."

  # --- 8MB chip ---
  echo ""
  show_image "eeprom_chip_8mb.webp" "Reference: 8MB (bottom) chip location on T440p"
  echo ""
  info "Now move the clip to the ${BOLD}8MB (bottom)${NC} chip shown above."
  info "Re-check pin 1 alignment before pressing down."
  prompt_continue

  _read_with_retry "8mb_backup1.bin" "8MB chip (read 1 of 2)" || return 1
  _read_with_retry "8mb_backup2.bin" "8MB chip (read 2 of 2)" || return 1
  success "8MB chip reads complete."
}
