#!/bin/sh
# Step: Configure coreboot

step_configure() {
  section "Configure Coreboot"

  cd "$COREBOOT_DIR" || return 1

  # Verify all blobs are present
  info "Checking for required firmware blobs..."
  _missing=0
  for _blob in "$BLOB_IFD" "$BLOB_ME" "$BLOB_GBE" "$BLOB_MRC"; do
    if [ -f "$_blob" ]; then
      success "Found: $_blob"
    else
      error "Missing: $_blob"
      _missing=1
    fi
  done

  if [ "$_missing" -eq 1 ]; then
    error "Some blobs are missing. Complete the previous steps first."
    return 1
  fi

  # Warn before overwriting existing .config
  if [ -f "$COREBOOT_DIR/.config" ]; then
    echo ""
    warn "An existing .config was found in $COREBOOT_DIR."
    if ! prompt_yes_no "Overwrite it?"; then
      info "Keeping existing .config. Opening nconfig for review..."
      make nconfig
      return $?
    fi
  fi

  echo ""
  info "Choose a payload for your coreboot build:"
  echo ""
  echo "  1) GRUB2     - Direct Linux boot, includes memtest/nvramcui/coreinfo"
  echo "  2) SeaBIOS   - Traditional BIOS, best compatibility (Windows/BSD)"
  echo "  3) edk2      - UEFI firmware, modern boot interface"
  echo "  4) Custom    - Open the full configuration menu"
  echo ""

  _payload=""
  while [ -z "$_payload" ]; do
    printf "${CYAN}Choice [1-4]:${NC} "
    read -r _choice
    case "$_choice" in
      1) _payload="grub2" ;;
      2) _payload="seabios" ;;
      3) _payload="edk2" ;;
      4) _payload="custom" ;;
      *) echo "Please enter 1-4." ;;
    esac
  done

  _has_dgpu="n"
  _dgpu_vbios=""
  if [ "$_payload" != "custom" ]; then
    echo ""
    if prompt_yes_no "Does your T440p have the GT730M dGPU?"; then
      _has_dgpu="y"
      echo ""
      info "dGPU support needs a VGA option ROM (VBIOS) for the GT730M."
      info "Extract it from your original ROM, dump from live Windows, or obtain separately."
      _dgpu_vbios=$(prompt_value "Path to GT730M VBIOS file (leave empty to skip auto-set)" "")
      if [ -n "$_dgpu_vbios" ] && [ ! -f "$_dgpu_vbios" ]; then
        warn "File not found: $_dgpu_vbios. Will set flags only; fill path in nconfig."
        _dgpu_vbios=""
      fi
    fi
  fi

  if [ "$_payload" = "custom" ]; then
    info "Opening full coreboot configuration..."
    info "Key settings to configure:"
    echo "  - Mainboard vendor: Lenovo"
    echo "  - Mainboard model: ThinkPad T440p / W541"
    echo "  - Set blob paths under Chipset:"
    echo "    IFD: $BLOB_IFD"
    echo "    ME:  $BLOB_ME"
    echo "    GbE: $BLOB_GBE"
    echo "    MRC: $BLOB_MRC"
    echo ""
    prompt_continue
    make nconfig
    return $?
  fi

  # Generate seed .config
  info "Generating configuration for: $_payload"

  cat > .config << COREBOOT_CONFIG
# Mainboard
CONFIG_VENDOR_LENOVO=y
CONFIG_BOARD_LENOVO_THINKPAD_T440P=y

# Firmware blobs
CONFIG_HAVE_IFD_BIN=y
CONFIG_IFD_BIN_PATH="$BLOB_IFD"
CONFIG_HAVE_ME_BIN=y
CONFIG_ME_BIN_PATH="$BLOB_ME"
CONFIG_HAVE_GBE_BIN=y
CONFIG_GBE_BIN_PATH="$BLOB_GBE"
CONFIG_HAVE_MRC=y
CONFIG_MRC_FILE="$BLOB_MRC"
COREBOOT_CONFIG

  # Payload-specific options
  case "$_payload" in
    grub2)
      cat >> .config << 'GRUB_CONFIG'

# Payload
CONFIG_PAYLOAD_GRUB2=y
CONFIG_GRUB2_INCLUDE_RUNTIME_CONFIG_FILE=y

# Secondary payloads
CONFIG_MEMTEST_SECONDARY_PAYLOAD=y
CONFIG_NVRAMCUI_SECONDARY_PAYLOAD=y
CONFIG_COREINFO_SECONDARY_PAYLOAD=y
GRUB_CONFIG
      ;;
    seabios)
      cat >> .config << 'SEABIOS_CONFIG'

# Payload
CONFIG_PAYLOAD_SEABIOS=y
CONFIG_SEABIOS_STABLE=y
SEABIOS_CONFIG
      ;;
    edk2)
      cat >> .config << 'EDK2_CONFIG'

# Payload (tianocore/edk2)
CONFIG_PAYLOAD_TIANOCORE=y
EDK2_CONFIG
      ;;
  esac

  # dGPU option ROM (GT730M)
  if [ "$_has_dgpu" = "y" ]; then
    cat >> .config << DGPU_CONFIG

# dGPU (GT730M) VGA option ROM
CONFIG_VGA_BIOS_DGPU=y
CONFIG_VGA_BIOS_DGPU_FILE="$_dgpu_vbios"
CONFIG_VGA_BIOS_DGPU_ID="10de,1292"
DGPU_CONFIG
    if [ -z "$_dgpu_vbios" ]; then
      warn "dGPU VBIOS path empty — set CONFIG_VGA_BIOS_DGPU_FILE in nconfig before building."
    else
      info "dGPU option ROM configured: $_dgpu_vbios"
    fi
  fi

  # Fill in remaining defaults
  info "Resolving full configuration with defaults..."
  run_cmd "make olddefconfig" || {
    warn "olddefconfig failed. Opening full configuration menu instead."
    make nconfig
    return $?
  }

  success "Configuration generated for: $_payload"

  echo ""
  if prompt_yes_no "Open the configuration menu to review/customize?"; then
    make nconfig
  fi

  return 0
}
