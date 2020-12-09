#!/bin/bash

# Backblaze variables
bb_username=$(defaults read "/Library/Managed Preferences/com.airwatch.UserDetails.plist" EmailAddress)
bb_grpID=00000                             # Fill with group ID
bb_grpToken=abcd12345efghij67890klmnop     # Fill with Group Token

# System Preferences is blocked by app install, but just in case, this checks for it and then kills the process if so
sysPrefPID=$(pgrep System\ Preferences)

if [[ $sysPrefPID != "" ]]; then
  echo "System Preferences open, killing app..."
  kill $sysPrefPID
fi

# Run installer
echo "${bb_username},${bb_grpID},${bb_grpToken}"
echo "About to run the Backblaze installer with this command:"
echo /Applications/Backblaze\ Installer.app/Contents/MacOS/bzinstall_mate -nogui  -createaccount "$bb_username" none "$bb_grpID" "$bb_grpToken"
/Applications/Backblaze\ Installer.app/Contents/MacOS/bzinstall_mate -nogui  -createaccount "$bb_username" none "$bb_grpID" "$bb_grpToken"
echo "Finished running Backblaze silent installer"

# Check to see if Backblaze.app is installed then remove installer app
if [[ -d "/Applications/Backblaze.app" ]]; then
  echo "Removing Backblaze Installer"
  rm -rf /Applications/Backblaze\ Installer.app
else
  echo "Backblaze not installed, try again."
  exit 1
fi

exit 0
