#!/bin/sh
# Step: Build ifdtool and extract firmware blobs

step_build_ifdtool() {
  section "Build ifdtool & Extract Firmware Blobs"

  # Build ifdtool
  info "Building ifdtool (Intel Firmware Descriptor tool)..."
  cd "$COREBOOT_DIR/util/ifdtool" || return 1
  run_cmd "make" || return 1

  if [ ! -f "$COREBOOT_DIR/util/ifdtool/ifdtool" ]; then
    error "ifdtool binary not found after build."
    return 1
  fi
  success "ifdtool built."

  # Extract firmware blobs from the original ROM
  echo ""
  info "Extracting firmware blobs from original BIOS..."

  if [ ! -f "$ORIGINAL_ROM" ]; then
    error "Original ROM not found: $ORIGINAL_ROM"
    error "Complete the BIOS extraction steps first."
    return 1
  fi

  run_cmd "./ifdtool -x $ORIGINAL_ROM" || return 1

  # Move blobs to working directory
  if [ -f "flashregion_0_flashdescriptor.bin" ]; then
    mv flashregion_0_flashdescriptor.bin "$BLOB_IFD"
    success "Extracted: ifd.bin (flash descriptor)"
  else
    error "Flash descriptor not found in extraction output."
    return 1
  fi

  if [ -f "flashregion_2_intel_me.bin" ]; then
    mv flashregion_2_intel_me.bin "$BLOB_ME"
    success "Extracted: me.bin (Intel ME firmware)"
  else
    error "Intel ME firmware not found in extraction output."
    return 1
  fi

  if [ -f "flashregion_3_gbe.bin" ]; then
    mv flashregion_3_gbe.bin "$BLOB_GBE"
    success "Extracted: gbe.bin (Gigabit Ethernet config)"
  else
    error "GbE config not found in extraction output."
    return 1
  fi

  # Clean up any other extraction artifacts
  rm -f flashregion_*.bin

  echo ""
  success "All firmware blobs extracted to $WORK_DIR"
}
