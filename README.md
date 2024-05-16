# NameThisMacwithSwiftDialog
16-MAY-2024
Name This Mac with Swift Dialog is a shell script used to set the computer name in Mac OS.
It uses Bart Reardon's [SwiftDialog[(https://github.com/swiftDialog/swiftDialog) and is inspired by Dan Snelson's [Setup Your Mac](https://github.com/setup-your-mac/Setup-Your-Mac) (and other works)

This script was written because my organization has a complicated computer naming policy established many years ago.  My grad school also manages Jamf for 1 other grad school and a large research department.
When we started using Setup Your Mac, the SYM script was heavily modified to accommodate our needs, but it wasn't quite perfect, as it didn't account for all 3 groups that use our Jamf environment. And it made upgrading to later versions of SYM difficult.

Enter *Name This Mac* (here on referenced as NTM).

With NTM, I was able to separate the script needed for computer naming from the SYM code, making upgrading SYM much easier.  Using Jamf parameters I was also able to create use cases where NTM could be run as a standalone Self Service policy or as part of the SYM provisioning process, and also create an option where the suggested name could be modifed by technicians running the policy.

## Using NTM
NTM is meant to run within a Jamf policy. Add the NTM script to Jamf, then create a new policy with the script as the payload.  Be sure to set the Parameters before running it.

Parameter #4: Self Service or Provisioning; Self Service is default. This parameter changes the text and the button behavior in the dialog windows.  If you want to run NTM during a provisioning workflow, set Parameter 4 to Provisioning and add the Jamf policy to your provisioning workflow.

Parameter #5: "Tech" mode or  "Standard" mode; Standard is default.  This parameter changes the text in the Name confirmation dialog.  In Tech mode, the person running the policy will be able to change the suggested name to something other than the suggested name.  Its useful for edge cases, but my organization does not allow this when used in conjunction with our provisioning workflow.

Parameter #6: Debug mode; true is default.  When true, the script runs in default mode.  It will log everything and do almost everything, except change the computer name.

*Parameter 7: Unfinished Work*; Harvard University is highly decentralized, with 13 major Schools and administrative groups, all with their own standards.  Harvard Medical School, just one of the 13, supports 2 other schools/major departments in our Jamf environment, each with their own computer naming standard.
Parameter 7 in this script is intended to account for each of the 3 naming standards in use, however as of this moment the other groups have not committed to using this naming tool or our SYM provisioning workflow so the effort around Paramenter 7 and naming conventions for multiple groups is incomplete. I left it there because the script works as is, and I do anticipate finishing it if only to know that I can do it. Do with it what you will.

### Buildings and Locations
There are 4 variable fields that need your editing.  Read the comments on or around Line 77.
departmentListRaw: A list of your departments, separated by a comma. Note that there is one called "Please select your department".  This selection is a default in case the user does not select a department from the menu.

deptNameCodeList: A list of Department names followed by a 2-3 letter code.  This needs to be formatted properly otherwise the code matching will fail.

locationListRaw: Just like the departmentListRaw, but for locations, ie Building or whatever you need.

locationNameCodeList: Just like deptNameCodeList, but for locations.

## Use cases
NTM is intended to be used in several use cases using Jamf Script Parameters (Parameters 4 & 5)
- As a Self Service Policy (Parameter 4) by a "normal" user (Prevents modifying the suggested computer name, exits when finished)
- As a Self Service Policy (Parameter 4) by a field tech or Asset Team member (Allows modifying the suggested name, exits when finished)
- Integrated with SetupYourMac (Parameter 5), by a "normal" user (Prevents modifying the suggested computer name, continues to SYM when finished)
- Integrated with SetupYourMac (Parameter 5), by a field tech or Asset Team member (Allows modifying the suggested name, continues to SYM when finished)

## User ID's
- Line 382: The regex used in the dialog will validate against a user ID containing 2-4 letters followed by 1-4 numbers.  Modify as needed.

## Asset tags
- Lines 382 and 390; There is regex in Line 390 intended to validate that the Asset # looks like it should, which in our case is 3 letters followed by 5 numbers. Replace Line 382 with Line 390, modified as needed.

## Using with SetupYourMac
When used in conjunction with SYM, I added a line to SYM to call the Jamf policy that runs NTM. This will cause NTM to launche *after* the SYM Welcome dialog but before the Setup dialog.
Doing it this way resolved a long delay between the 2 Jamf policies and made the overall flow much cleaner and freindlier.



### Disclaimer
I'm an imperfect human imperfectly learning to write imperfect scripts, thereby doing the right thing the wrong way for the right reasons.  Phil.
