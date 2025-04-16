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
      echo "Usage: curl -fsSL https://timmypidashev.dev/scripts/run.sh | sh -s -- [OPTIONS]"
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

# Function to download a single script/file
download_script() {
  script_path="$1"
  output_path="$TEMP_DIR/$1"
  
  # Create directory if needed
  mkdir -p "$(dirname "$output_path")"
  
  # Download the script
  echo "Downloading $script_path..."
  curl -fsSL "$BASE_URL/$script_path" -o "$output_path"
  
  # Make executable if it's a script
  if echo "$script_path" | grep -q "\.\(sh\|bash\|pl\|py\)$"; then
    chmod +x "$output_path"
  fi
  
  echo "$output_path"
}

# Function to download a directory listing
get_directory_listing() {
  dir_path="$1"
  echo "Getting file listing for $dir_path..."
  
  # Use curl to fetch directory listing (this assumes your web server has directory listing enabled)
  # This is a simple approach that may need customization based on your web server
  listing=$(curl -s "$BASE_URL/$dir_path/" | grep -o 'href="[^"]*"' | cut -d'"' -f2)
  
  echo "$listing"
}

# Function to download an entire directory structure
download_directory() {
  dir_path="$1"
  output_dir="$TEMP_DIR/$dir_path"
  
  echo "Downloading directory: $dir_path"
  mkdir -p "$output_dir"
  
  # Option 1: If you have a manifest.txt file that lists all files in the directory
  if curl -s -f "$BASE_URL/$dir_path/manifest.txt" -o "$output_dir/manifest.txt"; then
    echo "Found manifest.txt, using it to download files..."
    while read -r file; do
      # Skip empty lines and comments
      [ -z "$file" ] || [ "${file#\#}" != "$file" ] && continue
      download_script "$dir_path/$file"
    done < "$output_dir/manifest.txt"
  
  fi
  
  # Make all shell scripts executable
  find "$output_dir" -name "*.sh" -exec chmod +x {} \;
  
  echo "$output_dir"
}

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
    # Download the entire directory structure
    script_dir=$(download_directory "scripts/coreboot-t440p")
    
    # Run the main script if it exists
    if [ -f "$script_dir/main.sh" ]; then
      "$script_dir/main.sh" "$@"
    else
      # Try to find any executable script
      main_script=$(find "$script_dir" -name "*.sh" -executable | head -1)
      if [ -n "$main_script" ]; then
        "$main_script" "$@"
      else
        echo "Error: No executable scripts found in $script_dir"
        exit 1
      fi
    fi
    ;;
  *)
    echo "Unknown script type: $SCRIPT_TYPE"
    exit 1
    ;;
esac
