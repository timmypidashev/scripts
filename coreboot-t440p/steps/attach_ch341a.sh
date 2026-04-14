#!/bin/sh
# Step: Verify CH341A programmer connection

step_attach_ch341a() {
  section "Verify CH341A Programmer"

  info "Make sure your CH341A programmer is:"
  echo "  1. Connected to your computer via USB"
  echo "  2. Set to 3.3V (NOT 5V!)"
  echo "  3. Ribbon cable seated in the correct orientation"
  echo ""
  warn "Using 5V WILL damage your BIOS chip permanently!"

  prompt_continue

  info "Checking if flashrom detects the CH341A programmer..."
  if run_cmd "flashrom --programmer ch341a_spi"; then
    success "CH341A programmer detected!"
    return 0
  fi

  error "CH341A programmer not detected."
  echo ""
  echo "  Troubleshooting:"
  echo "    - Ensure the programmer is plugged in"
  echo "    - Try a different USB port"
  echo "    - Check the driver: lsusb | grep 1a86:5512"
  echo "    - Make sure you have permissions (try with sudo)"
  echo ""

  if prompt_yes_no "Retry detection?"; then
    step_attach_ch341a
    return $?
  fi

  return 1
}
