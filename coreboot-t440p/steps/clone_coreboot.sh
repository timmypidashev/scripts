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

      # Resolve the target ref (may be a tag or a SHA) to a SHA for comparison.
      run_cmd "git fetch --tags origin" || return 1
      _target_sha=$(git rev-parse --verify "$COREBOOT_COMMIT^{commit}" 2>/dev/null)
      _current_sha=$(git rev-parse HEAD 2>/dev/null)

      if [ -n "$_target_sha" ] && [ "$_current_sha" = "$_target_sha" ]; then
        success "Already on $COREBOOT_COMMIT."
        return 0
      fi

      warn "Current HEAD ($_current_sha) differs from target ($COREBOOT_COMMIT)."
      if prompt_yes_no "Checkout $COREBOOT_COMMIT?"; then
        run_cmd "git checkout $COREBOOT_COMMIT" || return 1
        run_cmd "git submodule update --init --checkout" || return 1
        success "Checked out $COREBOOT_COMMIT."
      fi
      return 0
    fi
  fi

  info "Cloning coreboot (this may take a while)..."
  run_cmd "git clone https://review.coreboot.org/coreboot $COREBOOT_DIR" || return 1

  cd "$COREBOOT_DIR" || return 1

  info "Fetching tags..."
  run_cmd "git fetch --tags origin" || return 1

  info "Checking out: $COREBOOT_COMMIT"
  run_cmd "git checkout $COREBOOT_COMMIT" || return 1

  info "Initializing submodules..."
  run_cmd "git submodule update --init --checkout" || return 1

  success "Coreboot repository ready on $COREBOOT_COMMIT."
}
