#!/bin/sh
# Step: Clone and prepare the coreboot repository

step_clone_coreboot() {
  section "Clone Coreboot Repository"

  if [ -d "$COREBOOT_DIR" ]; then
    warn "Coreboot directory already exists: $COREBOOT_DIR"
    if prompt_yes_no "Remove and re-clone?"; then
      rm -rf "$COREBOOT_DIR"
    else
      info "Using existing coreboot directory."
      cd "$COREBOOT_DIR" || return 1

      _current=$(git rev-parse HEAD 2>/dev/null)
      if [ "$_current" = "$COREBOOT_COMMIT" ]; then
        success "Already on correct commit."
        return 0
      else
        warn "Current commit ($_current) differs from expected ($COREBOOT_COMMIT)."
        if prompt_yes_no "Checkout the correct commit?"; then
          run_cmd "git checkout $COREBOOT_COMMIT" || return 1
          run_cmd "git submodule update --init --checkout" || return 1
        fi
        return 0
      fi
    fi
  fi

  info "Cloning coreboot (this may take a while)..."
  run_cmd "git clone https://review.coreboot.org/coreboot $COREBOOT_DIR" || return 1

  cd "$COREBOOT_DIR" || return 1

  info "Checking out commit: $COREBOOT_COMMIT"
  run_cmd "git checkout $COREBOOT_COMMIT" || return 1

  info "Initializing submodules..."
  run_cmd "git submodule update --init --checkout" || return 1

  success "Coreboot repository ready."
}
