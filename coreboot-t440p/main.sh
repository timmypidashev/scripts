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

# Validate a step number (1-12). Coerces invalid input to 1.
_sanitize_step() {
  case "$1" in
    ''|*[!0-9]*) echo 1; return ;;
  esac
  if [ "$1" -lt 1 ] || [ "$1" -gt 12 ]; then
    echo 1
  else
    echo "$1"
  fi
}

run_full_install() {
  _start=$(_sanitize_step "${1:-1}")

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

# --- CLI ---

print_usage() {
  cat <<USAGE
Usage: $(basename "$0") [OPTIONS]

Options:
  -s, --start N        Skip interactive menu; run full install from step N.
                       Useful when BIOS is already extracted / blobs ready.
  -u, --update         Skip menu; internal-flash coreboot (already running it).
  -r, --revert         Skip menu; restore original BIOS.
  -w, --work-dir PATH  Override WORK_DIR (default: \$HOME/t440p-coreboot).
  -h, --help           Show this help.

Steps (for --start):
   1. Install dependencies       7. Build ifdtool & extract blobs
   2. Connect CH341A programmer  8. Build cbfstool
   3. Extract original BIOS      9. Obtain mrc.bin
   4. Verify BIOS backups       10. Configure coreboot
   5. Combine BIOS images       11. Build coreboot
   6. Clone coreboot repo       12. Flash coreboot

Example — skip hardware steps when backups already extracted:
  $(basename "$0") --start 5
USAGE
}

# Parse CLI flags. Populates CLI_MODE and CLI_START.
CLI_MODE=""
CLI_START=""
_parse_cli() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -s|--start)
        [ -z "$2" ] && { error "--start needs a step number"; exit 2; }
        CLI_MODE="start"
        CLI_START=$(_sanitize_step "$2")
        shift 2
        ;;
      -u|--update) CLI_MODE="update"; shift ;;
      -r|--revert) CLI_MODE="revert"; shift ;;
      -w|--work-dir)
        [ -z "$2" ] && { error "--work-dir needs a path"; exit 2; }
        WORK_DIR="$2"
        COREBOOT_DIR="$WORK_DIR/coreboot"
        BLOB_IFD="$WORK_DIR/ifd.bin"
        BLOB_ME="$WORK_DIR/me.bin"
        BLOB_GBE="$WORK_DIR/gbe.bin"
        BLOB_MRC="$WORK_DIR/mrc.bin"
        ORIGINAL_ROM="$WORK_DIR/t440p-original.rom"
        shift 2
        ;;
      -h|--help) print_usage; exit 0 ;;
      *) error "Unknown flag: $1"; print_usage; exit 2 ;;
    esac
  done
}

# --- Entry point ---

main() {
  _parse_cli "$@"

  show_banner
  detect_distro

  info "Detected distro: $DISTRO"

  setup_work_dir
  info "Working directory: $WORK_DIR"
  echo ""

  # Non-interactive modes (from CLI flags) — skip the menu entirely.
  case "$CLI_MODE" in
    start)  run_full_install "$CLI_START"; return ;;
    update) step_update_bios; return ;;
    revert) step_revert_bios; return ;;
  esac

  echo "  What would you like to do?"
  echo ""
  echo "  1) Full install        - Run all steps from the beginning"
  echo "  2) Resume from step    - Start from a specific step"
  echo "  3) Update coreboot     - Internal flash (already running coreboot)"
  echo "  4) Revert to original  - Restore original BIOS"
  echo "  5) Quit"
  echo ""
  info "Tip: pass --start N / --update / --revert to skip this menu."
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
      echo "   2. Connect CH341A programmer  8. Build cbfstool"
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
