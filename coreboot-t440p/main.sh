#!/bin/sh
# Coreboot T440p Interactive Installer
# https://timmypidashev.dev/blog/thinkpad-t440p-coreboot-guide

set -e

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source dependencies
. "$SCRIPT_DIR/utils.sh"
. "$SCRIPT_DIR/config.sh"
. "$SCRIPT_DIR/system.sh"

# Source all step scripts
for _step_file in "$SCRIPT_DIR/steps/"*.sh; do
  [ -f "$_step_file" ] && . "$_step_file"
done

# Disable set -e after sourcing (we handle errors per-step)
set +e

# --- Banner ---

show_banner() {
  printf "${BOLD}${PURPLE}"
  echo ""
  echo "  ╔════════════════════════════════════════════════════╗"
  echo "  ║        Coreboot T440p Interactive Installer        ║"
  echo "  ╚════════════════════════════════════════════════════╝"
  printf "${NC}"
  echo ""
  echo "  Guide: timmypidashev.dev/blog/thinkpad-t440p-coreboot-guide"
  echo ""
}

# --- Step runner ---

# Run a step function with retry/skip handling
run_step() {
  _step_num="$1"
  _step_name="$2"
  _step_func="$3"

  printf "\n${BOLD}${CYAN}[Step %s/12] %s${NC}\n" "$_step_num" "$_step_name"
  echo ""

  while true; do
    "$_step_func"
    _rc=$?

    if [ $_rc -eq 0 ]; then
      return 0
    fi

    # Step failed — prompt retry-or-quit.
    # handle_failure exits the whole script on "quit"; otherwise loop retries.
    handle_failure "$_step_name"
  done
}

# --- Main flow ---

run_full_install() {
  _start="${1:-1}"

  [ "$_start" -le 1 ]  && run_step 1  "Install Dependencies"          install_dependencies
  [ "$_start" -le 2 ]  && run_step 2  "Connect CH341A Programmer"     step_attach_ch341a
  [ "$_start" -le 3 ]  && run_step 3  "Extract Original BIOS"         step_extract_bios
  [ "$_start" -le 4 ]  && run_step 4  "Verify BIOS Backups"           step_backup_bios
  [ "$_start" -le 5 ]  && run_step 5  "Combine BIOS Images"           step_combine_bios
  [ "$_start" -le 6 ]  && run_step 6  "Clone Coreboot Repository"     step_clone_coreboot
  [ "$_start" -le 7 ]  && run_step 7  "Build ifdtool & Extract Blobs" step_build_ifdtool
  [ "$_start" -le 8 ]  && run_step 8  "Build cbfstool"                step_build_cbfstool
  [ "$_start" -le 9 ]  && run_step 9  "Obtain mrc.bin"                step_build_peppy
  [ "$_start" -le 10 ] && run_step 10 "Configure Coreboot"            step_configure
  [ "$_start" -le 11 ] && run_step 11 "Build Coreboot"                step_build_bios
  [ "$_start" -le 12 ] && run_step 12 "Flash Coreboot"                step_flash_bios

  echo ""
  printf "${BOLD}${GREEN}"
  echo "  ╔════════════════════════════════════════════════════╗"
  echo "  ║                 All steps complete!                ║"
  echo "  ╚════════════════════════════════════════════════════╝"
  printf "${NC}\n"
}

# --- Entry point ---

main() {
  show_banner
  detect_distro

  info "Detected distro: $DISTRO"

  setup_work_dir
  info "Working directory: $WORK_DIR"
  echo ""

  echo "  What would you like to do?"
  echo ""
  echo "  1) Full install        - Run all steps from the beginning"
  echo "  2) Resume from step    - Start from a specific step"
  echo "  3) Update coreboot     - Internal flash (already running coreboot)"
  echo "  4) Revert to original  - Restore original BIOS"
  echo "  5) Quit"
  echo ""

  printf "${CYAN}Choice [1-5]:${NC} "
  read -r _choice

  case "$_choice" in
    1)
      run_full_install 1
      ;;
    2)
      echo ""
      echo "  Steps:"
      echo "   1. Install dependencies       7. Build ifdtool & extract blobs"
      echo "   2. Verify CH341A programmer   8. Build cbfstool"
      echo "   3. Extract original BIOS      9. Obtain mrc.bin"
      echo "   4. Verify BIOS backups       10. Configure coreboot"
      echo "   5. Combine BIOS images       11. Build coreboot"
      echo "   6. Clone coreboot repo       12. Flash coreboot"
      echo ""
      _start=$(prompt_value "Start from step" "1")
      run_full_install "$_start"
      ;;
    3)
      step_update_bios
      ;;
    4)
      step_revert_bios
      ;;
    *)
      echo "Exiting."
      exit 0
      ;;
  esac
}

main "$@"
