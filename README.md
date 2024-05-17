# NameThisMacwithSwiftDialog
16-MAY-2024

Name This Mac with Swift Dialog is a shell script used to set the computer name in Mac OS.
It uses Bart Reardon's [SwiftDialog](https://github.com/swiftDialog/swiftDialog) and is inspired by Dan Snelson's [Setup Your Mac](https://github.com/setup-your-mac/Setup-Your-Mac) (SYM) and other works.

When run the script will check for and if necessary install Swift Dialog.  It will then create a nice to look at user interface with several fields and menus to be filled out by the user.

NTM collects the necessary information needed to construct the name, informs the user what the name will be, sets the name, then sends a jamf recon with the User ID to update the computer record.

This script was written because my organization has a complicated computer naming policy established many years ago.  My grad school also manages Jamf for 1 other grad school and a large research department.
When we started using Setup Your Mac, 100's of lines in the SYM script were heavily modified to accommodate our computer naming needs, but it wasn't quite perfect, as it didn't account for all 3 groups that use our Jamf environment. And it made upgrading to later versions of SYM difficult.

Enter *Name This Mac* (here on referenced as NTM).

With NTM, I was able to separate the script needed for computer naming from the SYM code.  Now, when upgrading SYM, I need to edit less than 30 lines of code to make SYM ready for testing, making my job much easier.  Using Jamf parameters I'm able to create use cases where NTM could be run as a standalone Self Service policy or as a policy that runs as part of our internal provisioning workflow with SYM and also create an option where the suggested name could be modifed by technicians running the policy to account for edge cases.

### About the naming convention

This script constructs a computername in the following format:

**Prefix**: Set in Line 426

**Department Code**: Established by code starting in Line 85. Read more about this in the **Buildings and Locations** section below

**Location Code**: Established by code starting in Line 113

**Computer Type**: "L" (Laptop) or "D" (Desktop)

**Asset Tag** (or random string): If a value is entered in the Asset Tag field, the last 5 characters will be used as a unique identifier, otherwise a random string up to 5 characters is generated.

**Suffix**: Set in Line 427

The final name will look like `<prefix><Department Code><Location Code><Computer Type><Asset Tag><Suffix>`

Of course your needs may  be very different.  Hopefully this script will help point you in the right direction or give you some new ideas to solve the problem.

## Using NTM

You can run NTM as is in Terminal without making any changes just to see what it does.  The default setup will prevent any changes from actually being made (See notes about Parameter 6 below)

NTM is meant to run within one or more Jamf policies. Add the NTM script to Jamf, then create a new policy with the script as the payload.  You can create multiple policies with the same payload and different parameters, so if the script needs updating you only need to do it once.

**Parameter #4**: "Self Service" or "Provisioning"; Self Service is default. This parameter changes the text and the button behavior in the dialog windows.  If you want to run NTM during a provisioning workflow, set Parameter 4 to Provisioning and add the Jamf policy to your provisioning workflow.

**Parameter #5**: "Tech" mode or  "Standard" mode; Standard is default.  This parameter changes the text in the Name confirmation dialog.  In Tech mode, the person running the policy will be able to change the suggested name to something other than the suggested name.  Its useful for edge cases, but my organization does not allow this when used in conjunction with our provisioning workflow.

**Parameter #6**: Debug mode; true is default.  When true, the script runs in default mode.  It will log everything and do almost everything, except change the computer name.  **NOTE**: Read line 4!  DEBUG is hard coded to be enabled so that unintentional mistakes aren't made.  I made enough of them myself that I needed to do this to maintain what little sanity I have left.  When ready to put into your Jamf enviroment, modify lines 155/156 to enable the Jamf parameter.

**Other variables**

Modify other variables according ot your needs, such as log file location, branding and icon images, language that appears in each of the dialog windows, etc.

### Buildings and Locations
There are 4 variable fields that need to be changed to meet your needs.  Read the comments starting around Line 68.

**departmentListRaw**: A list of your departments, separated by a comma. Note that there is one called "Please select your department".  This selection is a default in case the user does not select a department from the menu.

**deptNameCodeList**: A list of Department names followed by a 2-3 letter code.  This needs to be formatted properly otherwise the code matching will fail.

**locationListRaw**: Just like the departmentListRaw, but for locations, ie Building or whatever you need.

**locationNameCodeList**: Just like deptNameCodeList, but for locations.

## Use cases
NTM is intended to be used in several use cases using Jamf Script Parameters (Parameters 4 & 5)
- As a Self Service Policy (Parameter 4) by a "normal" user (Prevents modifying the suggested computer name, exits when finished)
- As a Self Service Policy (Parameter 4) by a field tech or Asset Team member (Allows modifying the suggested name, exits when finished)
- Integrated with SetupYourMac (Parameter 5), by a "normal" user (Prevents modifying the suggested computer name, continues to SYM when finished)
- Integrated with SetupYourMac (Parameter 5), by a field tech or Asset Team member (Allows modifying the suggested name, continues to SYM when finished)

## User ID's
- Line 349: This line accepts a user ID in any format, without any sort of validation. If you need User ID validation replace Line 349 with Line 357.
- Line 357: Contains regex to validate against a user ID containing 2-4 letters followed by 1-4 numbers.  Modify as needed.
- User ID information is passed to Jamf during a Jamf recon at the end of the script.

## Asset tags
- Lines 382: This line accepts a an Asset tag value in any format, without any sort of validation. If you need Asset tag validation replace Line 382 with Line 390.
- Line 390: Contains regex to validate against an Asset tag containing 3 letters followed by 5 numbers. Modify as needed.
- Asset tag information is passed to Jamf during a Jamf recon at the end of the script.

## Using with SetupYourMac
Using SYM-Helper, I disabled all of the Setup Your Mac user input fields, as they were no longer needed.  The Setup Your Mac Welcome dialog is only used to convey support information to the user.
In the SetupYourMac script reference version I added 2 lines, 2863/2864 (plus supporting comments), to call NTM from within SYM.

`eval "${jamfBinary} policy -event MPT-NameThisMac ${suppressRecon}"`

`updateScriptLog "NAME THIS MAC: Setting up the computer name …"`
  
The first line will call to Jamf to run the NTM policy, causing NTM to launch *after* the SYM Welcome dialog but before the Setup dialog.
The second line updates the log file, and both SYM and NTM are configured to write to the same log file.
Doing it this way resolved a long delay between the NTM and SYM Jamf policies when they were run as 2 independent policies and made the overall flow much cleaner and freindlier.

### Disclaimer
I'm an imperfect human imperfectly learning to write imperfect scripts, thereby doing the right thing the wrong way for the right reasons.  With that in mind feel free to use this script in whatever way you choose.  I enjoy learning new things even if I don't always pick them up right away, so if you find ways to improve it or add new features please let me know.

Support; Writing scripts is not my strength and not my primary function and most of this work off-hours so please use this script at your own risk. I can't gaurantee it will work in your enviroment or for your needs.  If you need help, I'll try, but I'll probably google it just like you.  You'll probably google it better.

If you don't like comments, you'll hate this script.  I like comments, as it helps the current me, the future me and the future replacement me figure out what was going on inside the vacant lot in my head.

If your question is related to SwiftDialog, please see the [SwiftDialog](https://github.com/swiftDialog/swiftDialog/wiki) wiki page.
