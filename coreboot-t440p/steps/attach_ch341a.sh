#!/bin/sh
# Step: Confirm CH341A programmer is connected to USB

# CH341A USB vendor:product ID
CH341A_USB_ID="1a86:5512"

step_attach_ch341a() {
  section "Connect CH341A Programmer"

  info "Before continuing:"
  echo "  1. Plug the CH341A into a USB port"
  echo "  2. Set the voltage jumper to 3.3V (NEVER 5V)"
  echo "  3. Leave the SOIC-8 clip UNATTACHED for now"
  echo ""
  warn "Using 5V WILL permanently damage the BIOS chips on the T440p."
  echo ""
  info "Clip orientation rules (applies later when reading/writing chips):"
  echo "  - The red wire on the ribbon = pin 1"
  echo "  - The dot/notch on the EEPROM chip = pin 1"
  echo "  - These MUST align, or the chip will be misread or damaged"
  echo ""

  # Show reference image (cached locally, rendered inline if possible)
  show_image "spi_flasher_assembly.png" "Reference: CH341A + SOIC-8 clip assembly"
  echo ""

  prompt_continue

  info "Checking USB for CH341A (id $CH341A_USB_ID)..."

  if ! check_command lsusb; then
    warn "lsusb not found. Install usbutils to enable programmer detection."
    if prompt_yes_default "Continue without USB verification?"; then
      return 0
    fi
    return 1
  fi

  if lsusb | grep -qi "$CH341A_USB_ID"; then
    success "CH341A detected on USB bus."
    return 0
  fi

  error "CH341A not found on USB bus."
  echo ""
  echo "  Troubleshooting:"
  echo "    - Re-plug the programmer (try a different USB port)"
  echo "    - Check with: lsusb | grep $CH341A_USB_ID"
  echo "    - If lsusb sees it under a different ID, the device may be"
  echo "      a clone with different firmware — note the ID and retry"
  echo ""

  if prompt_yes_no "Retry detection?"; then
    step_attach_ch341a
    return $?
  fi

  return 1
}
