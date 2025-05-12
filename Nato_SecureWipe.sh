#!/bin/bash

echo "Welcome to TechOS NATO-government grade secure file ERASURE. (100% free and secure)"
echo "Ver: 1.43 (First release, tested)"
echo "Report Bugs"
echo "Warning: This isn't actual NATO but it's emulated to do what it'd normally do to securely wipe files."

read -p "Do you want to install pv for the progress bar? (Y/N): " INSTALL_PV
if [[ "$INSTALL_PV" =~ ^[Yy](es)?$ ]]; then
  sudo apt update && sudo apt install pv
  echo "pv installed successfully."
else
  echo "Skipping pv installation."
fi

# Function to overwrite a file with specific data stream
overwrite_pass() {
  local FILE="$1"
  local STREAM="$2"
  
  # Calculate file size
  FILE_SIZE=$(stat -c %s "$FILE")
  
  # Display progress bar using pv
  head -c "$FILE_SIZE" < "$STREAM" | pv -s "$FILE_SIZE" | dd of="$FILE" bs=1M conv=notrunc,fdatasync status=none
}

# Logging setup
LOG_FILE="erase_log.txt"
> "$LOG_FILE" # Clear existing log

# Ask if user wants to enable logging
read -p "Do you want to enable logging? (Y/N): " LOGGING_CONFIRM
case "$LOGGING_CONFIRM" in
  [yY]|[yY][eE][sS]) 
    LOGGING_ENABLED=true
    log_message() {
      local msg="$1"
      echo "$msg" | tee -a "$LOG_FILE"
    }
    ;;
  *) 
    LOGGING_ENABLED=false
    log_message() { : ; }  # Do nothing
    ;;
esac

# Prompt for file or directory path if not provided as argument
if [ -z "$1" ]; then
  read -e -p "Enter PATH: " TARGET
else
  TARGET="$1"
fi

# Verify if path is a file or directory
if [ ! -e "$TARGET" ]; then
  echo "Error: '$TARGET' does not exist."
  exit 1
fi

# Absolute path
TARGET=$(readlink -f "$TARGET")

# Confirm with the user
echo "Notice: This will wipe all data in this directory or file"
echo "Target: $TARGET"
read -p "Are you sure you want to proceed? (Y/N): " CONFIRM
case "$CONFIRM" in
  [yY]|[yY][eE][sS]) ;;
  *) 
    echo "Aborted."
    exit 0
    ;;
esac

# Log Message Function
log_message() {
  if [ "$LOGGING_ENABLED" = true ]; then
    echo "$1" | tee -a "$LOG_FILE"
  else
    echo "$1"
  fi
}

# Check if we are processing a directory
if [ -d "$TARGET" ]; then
  # Process directory: iterate over files
  log_message "Starting NATO 7-pass wipe on directory '$TARGET'"

  # Find all files (excluding directories) and process them
  find "$TARGET" -type f | while read FILE; do
    log_message "Processing file: $FILE"
    
    # Pass 1: overwrite with 0x00 (zeroes)
    overwrite_pass "$FILE" /dev/zero
    log_message "Pass 1: Overwritten with zeroes"
    
    # Pass 2: overwrite with 0xFF (ones)
    overwrite_pass "$FILE" <(dd if=/dev/zero bs=1M count=1 | tr '\000' '\377')
    log_message "Pass 2: Overwritten with ones"
    
    # Pass 3: overwrite with 0x00 (zeroes)
    overwrite_pass "$FILE" /dev/zero
    log_message "Pass 3: Overwritten with zeroes"
    
    # Pass 4: overwrite with 0xFF (ones)
    overwrite_pass "$FILE" <(dd if=/dev/zero bs=1M count=1 | tr '\000' '\377')
    log_message "Pass 4: Overwritten with ones"
    
    # Pass 5: overwrite with 0x00 (zeroes)
    overwrite_pass "$FILE" /dev/zero
    log_message "Pass 5: Overwritten with zeroes"
    
    # Pass 6: overwrite with 0xFF (ones)
    overwrite_pass "$FILE" <(dd if=/dev/zero bs=1M count=1 | tr '\000' '\377')
    log_message "Pass 6: Overwritten with ones"
    
    # Pass 7: overwrite with random data
    overwrite_pass "$FILE" /dev/urandom
    log_message "Pass 7: Overwritten with random data"
    
    # Delete the file after overwriting
    rm -f "$FILE"
    log_message "File '$FILE' has been securely wiped and deleted."
  done

  # Remove empty directories in the target directory
  find "$TARGET" -type d -empty -delete
  log_message "Empty directories in '$TARGET' have been deleted."

elif [ -f "$TARGET" ]; then
  # Process single file: overwrite with 7 passes
  log_message "Starting NATO 7-pass wipe on file '$TARGET'"

  # Pass 1: overwrite with 0x00 (zeroes)
  overwrite_pass "$TARGET" /dev/zero
  log_message "Pass 1: Overwritten with zeroes"
  
  # Pass 2: overwrite with 0xFF (ones)
  overwrite_pass "$TARGET" <(dd if=/dev/zero bs=1M count=1 | tr '\000' '\377')
  log_message "Pass 2: Overwritten with ones"
  
  # Pass 3: overwrite with 0x00 (zeroes)
  overwrite_pass "$TARGET" /dev/zero
  log_message "Pass 3: Overwritten with zeroes"
  
  # Pass 4: overwrite with 0xFF (ones)
  overwrite_pass "$TARGET" <(dd if=/dev/zero bs=1M count=1 | tr '\000' '\377')
  log_message "Pass 4: Overwritten with ones"
  
  # Pass 5: overwrite with 0x00 (zeroes)
  overwrite_pass "$TARGET" /dev/zero
  log_message "Pass 5: Overwritten with zeroes"
  
  # Pass 6: overwrite with 0xFF (ones)
  overwrite_pass "$TARGET" <(dd if=/dev/zero bs=1M count=1 | tr '\000' '\377')
  log_message "Pass 6: Overwritten with ones"
  
  # Pass 7: overwrite with random data
  overwrite_pass "$TARGET" /dev/urandom
  log_message "Pass 7: Overwritten with random data"
  
  # Delete the file after overwriting
  rm -f "$TARGET"
  log_message "File '$TARGET' has been securely wiped and deleted."
fi

echo "Erasure process complete. Logs saved in '$LOG_FILE'."
echo "Note: Logs may be large if the file being erased is large."
