#!/bin/sh

# Base URL for fetching additional scripts
BASE_URL="https://timmypidashev.dev/scripts"

# Parse arguments
SCRIPT_TYPE=""
while [ $# -gt 0 ]; do
  case $1 in
    --type|-t)
      SCRIPT_TYPE="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: curl -fsSL https://timmypidashev.dev/scripts/run | sh -s -- [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  -t, --type TYPE    Specify which script to run"
      echo "  -h, --help         Show this help message"
      exit 0
      ;;
    *)
      # Remaining arguments will be passed to the script
      break
      ;;
  esac
done

# Create a temporary directory for our scripts
TEMP_DIR=$(mktemp -d)
cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Function to download a script
download_script() {
  script_path="$1"
  output_path="$TEMP_DIR/$script_path"
  
  # Create directory if needed
  mkdir -p "$(dirname "$output_path")"
  
  # Download the script
  echo "Downloading $script_path..."
  curl -fsSL "$BASE_URL/$script_path" -o "$output_path"
  chmod +x "$output_path"
}

# Download common utilities first
#download_script "utils/common"

# Source common utilities
#. "$TEMP_DIR/utils/common"

# Interactive menu if no script type was specified
if [ -z "$SCRIPT_TYPE" ]; then
  echo "╔════════════════════════════════════════════╗"
  echo "║     Welcome to Timmy's scripts library!    ║"
  echo "╚════════════════════════════════════════════╝"
  echo ""
  echo "Please select a script to run:"
  echo "1) coreboot-t440p - Coreboot a T440p"
  echo "5) Quit"
  echo ""
  
  selected=0
  while [ $selected -lt 1 ] || [ $selected -gt 5 ]; do
    printf "Enter your choice [1-5]: "
    read -r selected
    
    # Validate input
    if ! echo "$selected" | grep -q '^[1-5]$'; then
      echo "Please enter a number between 1 and 5."
      selected=0
    fi
  done
  
  case $selected in
    1) SCRIPT_TYPE="coreboot-t440p" ;;
    5) echo "Exiting."; exit 0 ;;
  esac
  
  echo "Running $SCRIPT_TYPE script..."
fi

# Run the requested script type
case "$SCRIPT_TYPE" in
  coreboot-t440p)
    download_script "scripts/coreboot"
    "$TEMP_DIR/scripts/coreboot" "$@"
    ;;
  *)
    echo "Unknown script type: $SCRIPT_TYPE"
    exit 1
    ;;
esac
