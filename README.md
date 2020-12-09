# Install Backblaze to MacOS with VMware Workspace One
 A guide for installing Backblaze using the VMware Workspace One MDM (formerly known as Airwatch)

<p align="center">
  <img height="200" src="/Assets/Backblaze Installer.png">
  <img height="200" src="/Assets/workspace-one.png">
</p>

This document is cobbled together from several places in order to help those who wish to deploy Backblaze silently using Workspace One. Special thanks to Mark from the Mac Admins Slack for helping this come together in a scalable manner and saved me around 8 hours of work.

**NOTE**: This document assumes that this is for a new installation where you'll be creating a new account for the end users.

## Preparing to Deploy

In order to make the deployment as painless as possible, you will need to gather a few pieces of information from your Backblaze account as well as deploy a Custom Settings profile to gather the user details from your Macs.

First download the Backblaze Installer app from [here](https://secure.backblaze.com/update.htm).

Sign into your group admin's Backblaze account. Then either create a Backblaze group or find an existing group. From the Invite & Approve page for that group, click on the "Advanced Deployment Instructions" and locate the `groupID` and the `groupToken` for that group.

On WS1, create a Custom Settings profile, name it something like Workspace One User Details, and copy the following XML to the Custom Settings payload:

```xml
<dict>
    <key>PayloadIdentifier</key>
    <string>com.airwatch.UserDetails</string>
    <key>PayloadType</key>
    <string>com.airwatch.UserDetails</string>
    <key>PayloadUUID</key>
    <string>ABCDEFGH-1234-5678-90IJ-KLMNOPQRSTUV</string>
    <!-- Fill above with output of terminal command: uuidgen -->
    <key>DeviceSerialNumber</key><string>{DeviceSerialNumber}</string>
    <key>EmailAddress</key><string>{EmailAddress}</string>
    <key>EnrollmentUser</key><string>{EnrollmentUser}</string>
    <key>FirstName</key><string>{FirstName}</string>
    <key>LastName</key><string>{LastName}</string>
    <key>UserPrincipalName</key><string>{UserPrincipalName}</string>
</dict>
```

In a Terminal window run the command `uuidgen` and replace the string under `PayloadUUID` with the output.

Deploy the profile to all devices in your organization, the details can be referenced later for other potential deployments.

In order to use these items, assign a variable to the output of a `defaults read` command.

e.g.:
```bash
email=$(defaults read "/Library/Managed Preferences/com.airwatch.UserDetails" EmailAddress)
```

Since Backblaze needs an email address to set up an account for a user at installation, we'll be using the key  `EmailAddress`.



## Deploying Backblaze

After the profile has deployed, use the Workspace One Admin Assistant to parse the Backblaze Installer DMG and upload to WS1 as normal.

After the upload, add "System Preferences.app" to the list of blocking apps. Then copy/paste the following shell script to your Post Install, replacing the variables `bb_grpID` and `bb_grpToken` with the info from your Backblaze group:

```bash
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
```

During the assignment process, make sure to turn off Desired State Management in Restrictions to allow the app to be deleted by the post install script. Then assign and publish the app as normal.

If there's anything I missed, or improvements I could make to this repo, feel free to submit a PR!
