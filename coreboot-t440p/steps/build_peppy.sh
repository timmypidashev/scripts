#!/bin/sh
# Step: Download peppy ChromeOS image and extract mrc.bin

step_build_peppy() {
  section "Obtain mrc.bin"

  info "mrc.bin is a memory reference code blob needed for Haswell platforms."
  info "It will be extracted from a ChromeOS peppy firmware image."
  echo ""

  cd "$COREBOOT_DIR/util/chromeos" || return 1

  # Download peppy firmware
  info "Downloading peppy ChromeOS firmware image (this may take a while)..."
  run_cmd "./crosfirmware.sh peppy" || return 1

  # Find the downloaded image
  _peppy_image=$(ls coreboot-*.bin 2>/dev/null | head -1)
  if [ -z "$_peppy_image" ]; then
    error "Peppy firmware image not found after download."
    return 1
  fi
  info "Downloaded: $_peppy_image"

  # Extract mrc.bin using cbfstool
  info "Extracting mrc.bin..."
  run_cmd "../cbfstool/cbfstool $_peppy_image extract -f mrc.bin -n mrc.bin -r RO_SECTION" || return 1

  if [ ! -f "mrc.bin" ]; then
    error "mrc.bin not found after extraction."
    return 1
  fi

  mv mrc.bin "$BLOB_MRC"
  success "mrc.bin extracted to $BLOB_MRC"

  # Clean up the large peppy image
  if prompt_yes_default "Remove peppy firmware image to save space?"; then
    rm -f coreboot-*.bin
    info "Cleaned up peppy firmware image."
  fi
}
