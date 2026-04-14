#!/bin/sh
# Step: Extract original BIOS from both EEPROM chips
#
# Order rationale: read 4MB (top) chip first — smaller, faster,
# surfaces setup issues (clip alignment, voltage, ribbon) sooner.

# Probe the currently-clipped chip and resolve the flashrom chip name.
#   $1 = variable name to populate (e.g. "CHIP_4MB")
# Handles the "Multiple flash chip definitions match" case by prompting.
_resolve_chip() {
  _var="$1"

  eval _cur=\"\$$_var\"
  if [ -n "$_cur" ]; then
    info "Using previously-selected chip for this size: $_cur"
    return 0
  fi

  _log=$(mktemp)

  while true; do
    printf "  ${DIM}\$ sudo flashrom --programmer ch341a_spi${NC}\n"
    sudo flashrom --programmer ch341a_spi >"$_log" 2>&1
    _st=$?

    # Unambiguous success: one "Found ... chip \"NAME\"" line, exit 0.
    if [ $_st -eq 0 ]; then
      _chip=$(sed -nE 's/.*Found .* flash chip "([^"]+)".*/\1/p' "$_log" | head -1)
      if [ -n "$_chip" ]; then
        eval "$_var=\"\$_chip\""
        info "Detected chip: $_chip"
        rm -f "$_log"
        return 0
      fi
    fi

    # Ambiguous match: flashrom lists candidates but refuses to pick.
    if grep -q "Multiple flash chip definitions match" "$_log"; then
      _candidates=$(sed -nE 's/.*Found .* flash chip "([^"]+)".*/\1/p' "$_log")
      _count=$(printf '%s\n' "$_candidates" | wc -l | tr -d ' ')
      echo ""
      warn "Flashrom read the chip but multiple variants match the same silicon ID."
      info "This is normal for Winbond W25Q* parts. Pick one (the newest is safe):"
      echo ""
      _i=1
      for _c in $_candidates; do
        if [ "$_i" = "$_count" ]; then
          echo "  $_i) $_c   (default — newest)"
        else
          echo "  $_i) $_c"
        fi
        _i=$((_i+1))
      done
      echo ""

      _picked=""
      while [ -z "$_picked" ]; do
        printf "${CYAN}Choice [1-%s] (Enter = %s):${NC} " "$_count" "$_count"
        read -r _sel
        [ -z "$_sel" ] && _sel="$_count"
        case "$_sel" in
          ''|*[!0-9]*) echo "Enter a number."; continue ;;
        esac
        if [ "$_sel" -lt 1 ] || [ "$_sel" -gt "$_count" ]; then
          echo "Out of range."
          continue
        fi
        _picked=$(printf '%s\n' "$_candidates" | sed -n "${_sel}p")
      done
      eval "$_var=\"\$_picked\""
      info "Using chip definition: $_picked"
      rm -f "$_log"
      return 0
    fi

    # Hard failure — no chip detected. Show output and offer re-seat retry.
    echo ""
    error "Chip probe failed. flashrom output:"
    sed 's/^/    /' "$_log"
    echo ""
    warn "Most common causes:"
    echo "    - Clip not seated flush on chip (press down gently, wiggle)"
    echo "    - Pin 1 misaligned (red ribbon wire ↔ chip dot/notch)"
    echo "    - Clipped onto the wrong chip (try the other one, then switch back)"
    echo "    - Residual laptop power (remove main battery + CMOS coin cell)"
    echo "    - Cheap SOIC-8 clips can make intermittent contact"
    echo ""
    echo "  1) Re-seat clip and retry"
    echo "  2) Abort"
    echo ""
    printf "${CYAN}Choice [1-2]:${NC} "
    read -r _choice
    case "$_choice" in
      1) continue ;;
      *) rm -f "$_log"; return 1 ;;
    esac
  done
}

# Read a chip with inline retry on failure.
#   $1 = output filename
#   $2 = human label
#   $3 = chip name (from _resolve_chip)
_read_with_retry() {
  _out="$1"
  _label="$2"
  _chip="$3"

  while true; do
    info "Reading $_label ..."
    if run_cmd "sudo flashrom --programmer ch341a_spi -c \"$_chip\" -r $_out"; then
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

  cd "$WORK_DIR" || return 1

  # Short-circuit: if all four backups already exist and are the right size,
  # assume the user already pulled them off the board and offer to skip.
  if [ -f 4mb_backup1.bin ] && [ -f 4mb_backup2.bin ] \
     && [ -f 8mb_backup1.bin ] && [ -f 8mb_backup2.bin ]; then
    _s1=$(wc -c < 4mb_backup1.bin)
    _s2=$(wc -c < 8mb_backup1.bin)
    if [ "$_s1" -eq "$SIZE_4MB" ] && [ "$_s2" -eq "$SIZE_8MB" ]; then
      info "Existing backups found in $WORK_DIR:"
      echo "    4mb_backup1.bin, 4mb_backup2.bin, 8mb_backup1.bin, 8mb_backup2.bin"
      echo ""
      if prompt_yes_default "Skip re-reading the chips and use the existing backups?"; then
        success "Using existing backups. Skipping extraction."
        return 0
      fi
    fi
  fi

  info "The T440p has two EEPROM chips beside the SODIMM slots:"
  echo "  - 4MB (top)    — smaller SOIC-8, farther from CPU"
  echo "  - 8MB (bottom) — larger SOIC-8, closer to CPU (holds ME firmware)"
  echo ""
  info "Each chip is read twice so we can diff the results and catch flaky reads."
  echo ""

  # --- 4MB chip (do first: smaller = faster iteration on setup) ---
  echo ""
  show_image "eeprom_chip_4mb.webp" "Reference: 4MB (top) chip location on T440p"
  echo ""
  info "Clip the CH341A onto the ${BOLD}4MB (top)${NC} chip shown above."
  info "Align the red ribbon wire with the dot/notch on the chip (pin 1)."
  prompt_continue

  _resolve_chip CHIP_4MB || return 1
  _read_with_retry "4mb_backup1.bin" "4MB chip (read 1 of 2)" "$CHIP_4MB" || return 1
  _read_with_retry "4mb_backup2.bin" "4MB chip (read 2 of 2)" "$CHIP_4MB" || return 1
  success "4MB chip reads complete ($CHIP_4MB)."

  # --- 8MB chip ---
  echo ""
  show_image "eeprom_chip_8mb.webp" "Reference: 8MB (bottom) chip location on T440p"
  echo ""
  info "Now move the clip to the ${BOLD}8MB (bottom)${NC} chip shown above."
  info "Re-check pin 1 alignment before pressing down."
  prompt_continue

  _resolve_chip CHIP_8MB || return 1
  _read_with_retry "8mb_backup1.bin" "8MB chip (read 1 of 2)" "$CHIP_8MB" || return 1
  _read_with_retry "8mb_backup2.bin" "8MB chip (read 2 of 2)" "$CHIP_8MB" || return 1
  success "8MB chip reads complete ($CHIP_8MB)."
}
