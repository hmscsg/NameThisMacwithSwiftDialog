# NameThisMacwithSwiftDialog
Name This Mac with Swift Dialog is a shell script used to set the computer name in Mac OS.
It uses Bart Reardon's [SwiftDialog[(https://github.com/swiftDialog/swiftDialog) and is inspired by Dan Snelson's [Setup Your Mac](https://github.com/setup-your-mac/Setup-Your-Mac) (and other works)

This script was written because my organization has a complicated computer naming policy established many years ago.  My grad school also manages Jamf for 1 other grad school and a large research department.
When we started using Setup Your Mac, the SYM script was heavily modified to accommodate our needs, but it wasn't quite perfect, as it didn't account for all 3 groups that use our Jamf environment. And it made upgrading to later versions of SYM difficult.

Enter Name This Mac (here on referenced as NTM).

With NTM, I was able to separate the script needed for computer naming from the SYM code, making upgrading SYM much easier.  Using Jamf parameters I was also able to create use cases where NTM could be run as a standalone Self Service policy or as part of the SYM provisioning process, and also create an option where the suggested name could be modifed by technicians running the policy.

Another task that I started, but unfortunately have not yet completed, is an option to allow different groups (in my case 3 different schools) to have different naming conventions based on their needs.  The other two schools have not committed to using this tool or our provisioning workflow as of yet, so I have not finished this aspect of the this script. Much of code is present but there is still work to be done there.

## Usage
NTM is intended to be used in several use cases using Jamf Script Parameters (Parameters 4 & 5)
- As a Self Service Policy by a "normal" user (Prevents modifying the suggested computer name, exits when finished)
- As a Self Service Policy by a field tech or Asset Team member (Allows modifying the suggested name, exits when finished)
- As part of SetupYourMac (SYM), by a "normal" user (Prevents modifying the suggested computer name, continues to SYM when finished)
- As part of SetupYourMac (SYM), by a field tech or Asset Team member (Allows modifying the suggested name, continues to SYM when finished)

## User ID's
- Line 382 The regex used in the dialog will validate against a user ID containing 2-4 letters followed by 1-4 numbers.  Modify as needed.

## Asset tags
- Lines 382 and 390; There is regex in Line 390 intended to validate that the Asset # looks like it should, which in our case is 3 letters followed by 5 numbers. Replace Line 382 with Line 390, modified as needed.

## Using with SetupYourMac
When used in conjunction with SYM, I added a line to SYM to call the Jamf policy that runs NTM. This will cause NTM to launche *after* the SYM Welcome dialog but before the Setup dialog.
Doing it this way resolved a long delay between the 2 Jamf policies and made the overall flow much cleaner and freindlier.
