#!/bin/bash


## DEBUG IS ENABLED BY DEFAULT.  Change lines 155/156 to manage DEBUG mode using Jamf script Parameter 6


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#						Name This Mac 1.0.0
#
#	Phil Benware
#	Harvard Medical School
#	Endpoint Services Team, Enterprise Platforms Group, Information Technology Dept
#	February 2024
#
#	Name This Mac is a inspired by, and no small amount of code is from, the work of Dan Snelson's Setup Your Mac.
#	https://snelson.us/
#	Name This Mac uses SwiftDialog (thanks Bart Reardon!)
#	https://github.com/swiftDialog/swiftDialog/wiki
#
#	About Name This Mac (NTM)
#	Name This Mac (NTM) is a script used to collect information from the user which is then used to construct and set a computer name.
#
#	Usage
#	NTM is intended to be used in several use cases using Jamf Script Parameters (Parameters 4 & 5)
#	- As a Self Service Policy by a "normal" user (Prevents modifying the suggested computer name, exits when finished)
#	- As a Self Service Policy by a field tech or Asset Team member (Allows modifying the suggested name, exits when finished)
#	- As part of SetupYourMac (SYM), by a "normal" user (Prevents modifying the suggested computer name, continues to SYM when finished)
#	- As part of SetupYourMac (SYM), by a field tech or Asset Team member (Allows modifying the suggested name, continues to SYM when finished)
#	User ID's
#	- Our User Id's are 2-4 letters followed by 1-4 numbers. We use regex to validate the format.  Replace Line 349 with Line 357 and modify your regex as needed.
#	- The User Id is added to Jamf recon so its recorded in Jamf
#	Asset tags
#	- Our Asset tags have :HMS as the prefix followed by 5 numbers.  We use regex to validate the format. Replace Line 351 with Line 360 and modify as neede.
#
#	When used in conjunction with SYM, HMS has injected NTM into the SYM script so that NTM launches *after* the SYM Welcome dialog, but before the Setup dialog.
#	Doing it this way resolved a long delay between the 2 scripts, and makes the overall flow much cleaner and freindlier.
#
#	History
#	16-May-2024 - Initial Public Release
#
#	I'm an imperfect human imperfectly learning to write imperfect scripts, thereby doing the right thing the wrong way for the right reasons.  Phil.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 	Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Change this path and file name to your preferred location.
logFile="/Users/Shared/NTM.log"

if [[ ! -f "${logFile}" ]]; then
	touch "${logFile}"
fi

#	Function to write out to the log file.
function updateLog() {
	echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) NTM:  - ${1}" | tee -a "${logFile}"
}

#	 Log file preface
updateLog "###"
updateLog "###"
updateLog "NAME THIS MAC: Initiating NTM"
updateLog "###"
updateLog "###"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 						Department and Locations Lists
#							IMPORTANT INFORMATION
#	A list of available Departments and Locations
#	These lists will need occasional maintenance as Departments and Locations are added and removed.
#	- Its vitally important that any changes made to the departmentListRaw and locationListRaw variables
#	- are carried over to the deptNameCodeList and locationNameCodeList variables as well.
#	- The text within these variables must match exactly, including case, spaces, punctuation, etc.
#	- Failure to match exactly will break the code that matches a name to a DeptCode or LocationCode
#	- and will cause the name calculation to fail as well.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 	Department List
#	An ordered group of Department names, followed by a comma and a single space.  Names will appear in the menu in the same order they appear here.
#	The value "Please select your department" is a default that appears in the Department field.  This is used in the event the user does not select a value, in whcih case the code is set to LAZ (for them being lazy)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
departmentListRaw="Please select your department,-Not Listed - On-Campus Department,-Not Listed - Off-Campus or Affiliate,-Not Listed - Other,Finance,Information Technology,Marketing,Operations,Custodial"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Department Codes
#	When editing, these must be in the format of DeptName=DeptCode followed by a comma then a return.
#	For each entry in departmentListRaw there must be an entry to deptNameCodeList
#	There isn't a limit on the character length for these codes.
# 
#	NOTE: Do not add any whitespace before the values in deptNameCodeList else the BASHREMATCH will fail.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# 	Department Code list
deptNameCodeList="
Please select your department=LAZ,
-Not Listed - On-Campus Department=OnC,
-Not Listed - Off-Campus or Affiliate=OfC,
-Not Listed - Other=Oth,
Finance=FIN,
Information Technology=IT,
Marketing=MKT,
Operations=OPS,
Custodial=CUS"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Locations List
#	An ordered group of Locations, followed by a comma and a single space.  Names will appear in the menu in the same order they appear here.
#	The value "Please select your Location" is a default that appears in the Location field.  This is used in the event the user does not select a value, in whcih case the code is set to LAZ (for them being lazy)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

locationListRaw="Please select your location,-Not Listed - Other,-Work From Home,Building A1,Building A2,Building B,Building C-West,Building D-North"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Location Codes
#	When editing, these must be in the format of Location Name=LocationCode followed by a comma then a return.
#	For each entry in locationtListRaw there must be an entry to locationNameCodeList
#
#	NOTE: Do not add any whitespace before the values in locationNameCodeList else the BASHREMATCH will fail.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# 	Location Code list
locationNameCodeList="
Please select your location=LAZ,
-Work From Home=WFH,
-Not Listed - Other=NLO,
Building A1=A1,
Building A2=A2,
Building B=B,
Building C-West=C,
Building D-North=D
"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Jamf Script Parameters
#	These determine how NTM behaves depending on the use case.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 	Parameter 4: Script mode [ Self Service (default) | Provisioning ] If Self Service, the script will exit after setting the name, otherwise will continue on to Provisioning. Determines what text will appear on button1.  Will be either Done or Continue, depending on Jamf Script parameter #4
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
selfServiceScriptMode="${4:-"Self Service"}"  #Comment to test Provisioning workflow
#selfServiceScriptMode="Provisioning" # Uncomment to test the Provisioning workflow

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 	Parameter 5: User mode [ Standard (default) | Tech ] If Standard, the script dialog will be limited, user will not be able to modify the name prior to moving to next steps.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
selfServiceUserID="${5:-"Standard"}" # Comment to test the Tech workflow
#selfServiceUserID="${5:-"Tech"}"  # Uncomment to test the Tech workflow

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 	Parameter 6: Debug mode [false | true (default) ].  If debugMode="false" the computer name will be changed; If debugMode="true": changes will be logged but computer name will not be changed.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#debugMode="${6:-"true"}" # Comment this line for internal testing and devolopment.  Uncomment for production.
debugMode="true" #Uncomment this line for internal development and testing. Comment for production. for my own sanity.

if [[ "$debugMode" = "true" ]]; then
	updateLog "NAME THIS MAC: Debug Mode enabled."
	debugState="Debug Mode Enabled;"
else
	updateLog "NAME THIS MAC: Debug Mode disabled."
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Dialog variables	
#	Variables used to build the Dialog interface
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

#	Intro messages
#	Parameter 4- When set to Tech, this message will appear in the body of the dialog window
techInstructionsMessage="**Name This Mac** will set a compliant computer name based on the organizational computer naming standard using the information provided below.  \n\n### Instructions  \n**User ID (required):** Enter the User ID of the **Assigned to User**. _Do not use a technicians ID or your Employee ID_.  \n**Asset Tag:** Enter the Asset Tag number.  If you are unable to find the Asset Tag leave this field empty.  \n**Department:** If the department is not listed select \'Not Listed\'. \n\n**Location:** Select the user primary work location.  \n\nWhen finished, click **Continue** or press Return."

#	Parameter 4- When set to Standard, this message will appear in the body of the dialog window
userInstructionsMessage="**Name This Mac** will set a compliant computer name based on the organizational computer naming standard using the information provided below.  \n\n### Instructions  \n**User ID (required):** Enter the User ID of the **Assigned to User**. _Do not use a technicians ID or your Employee ID_.  \n**Asset Tag:** Enter the Asset Tag number.  If you are unable find the Asset Tag leave this field empty.  \n**Department:** Select a Department.  If the correct department is not listed select \'Not Listed\'.  \n**Location:** Select the building or primary work location.  For example, if the primary work location is Work From Home or remote, select \'~Work from Home\', otherwise select the building.  \n\nWhen finished, click **Continue** or press Return."

#	Text that appears in the header of the dialog window.
title="Name This Mac" 

#	Images used in the header and sidebar of the dialog window.
#	Branding background image in the header of the dialog window
bannerimage="https://img.freepik.com/free-photo/liquid-marbling-paint-texture-background-fluid-painting-abstract-texture-intensive-color-mix-wallpaper_1258-101465.jpg" # [Image by benzoix on Freepik](https://www.freepik.com/author/benzoix)" 
# 	Branding icon in the sidebar of the dialog window
icon="https://cdn-icons-png.flaticon.com/512/979/979585.png" 

#	Pull down menus
#	Warning: Changing these values will break the variable extraction below
selecttitle="Department"
selecttitle="Location"

#	Text to appear in the InfoBox on the sidebar, underneath the logo. Formatted with Markdown
infoBoxText="#### Your Organization Name"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 	Script Parameter Logic
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

#	Is the script running Self Service or Provisioning mode.  This is set in Parameter 4
#	"Self Service": The script is running in Self Service mode. Button1 text on screen 2 = Quit; The script will exit and the policy will be complete.
#	"Provisioning": The script is running in conjunction with Provisioning.  Button1 text on screen 2 = Continue; the script will continue on to complete SYM.
if [[ $selfServiceScriptMode == "Self Service" ]];then
	updateLog "NAME THIS MAC PREFLIGHT: Script mode is Self Service; Quit when finished"
	button1Value="Quit"
else
	updateLog "NAME THIS MAC PREFLIGHT: Script mode is Provisioning; Transition to provisioning process when finished"
	button1Value="Continue"
	# Change button1 text to "Continue" then move on to continue provisioning.
fi

# 	Is this being run by a Tech or a user.  This is set in Parameter 5
# 	"Tech": Gives the technician the opportunity to modify the suggested name (This functionality was specifically requested by field support for the edge cases)
#	"Standard": Normal user.  The propsed computer name is displayed, but not changeable.  If it needs to be changed, then it has to be done in the OS.
if [[ $selfServiceUserID == "Tech" ]]; then
	userType="Tech"
	updateLog "NAME THIS MAC PREFLIGHT: User is a member of the technicians group; Computer Name modifications allowed within the interface."
else
	userType="Standard"
	updateLog "NAME THIS MAC PREFLIGHT: User is a standard user; no name changes allowed."
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 	Get computer type code based on whether the Mac is a desktop or laptop
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
if system_profiler SPPowerDataType | grep -q "Battery Power"; then
	compType="L"
else
	compType="D"
fi

#	OS check, Dialog Check complements of Dan Snelson and Bart Reardon.
#	These variables tell us which OS version is running.  Swift Dialog requires macOS 12 or later.
osVersion=$( sw_vers -productVersion )
osBuild=$( sw_vers -buildVersion )
osMajorVersion=$( echo "${osVersion}" | awk -F '.' '{print $1}' )
requiredMinimumBuild="20G"  # The minimum OS required to run Dialog - currently macOS 12)

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	 Check the OS version.  Dialog requires macOS 12 or later
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
if [[ "${osMajorVersion}" -ge 11 ]] ; then
	
	updateLog "NAME THIS MAC PREFLIGHT: macOS ${osMajorVersion} installed; checking build version ..."
	
	# Confirm the Mac is running `requiredMinimumBuild` (or later)
	if [[ "${osBuild}" > "${requiredMinimumBuild}" ]]; then
		
		updateLog "NAME THIS MAC PREFLIGHT: macOS ${osVersion} (${osBuild}) installed; proceeding ..."
	else
		# When the current `osBuild` is older than `requiredMinimumBuild`; exit with error
		# Since Dialog is not running, the error is processed using osascript and AppleScript with a simple dialog box.
		updateLog "NAME THIS MAC PREFLIGHT: The installed operating system, macOS ${osVersion} (${osBuild}), needs to be updated to Build ${requiredMinimumBuild}; exiting with error."
		osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\rExpected macOS Build '${requiredMinimumBuild}' (or newer), but found macOS '${osVersion}' ('${osBuild}').\r\r" with title "Mac Deployment Toolkit: Detected Outdated Operating System" buttons {"Open Software Update"} with icon caution'
		updateLog "NAME THIS MAC PREFLIGHT: Executing /usr/bin/open '${outdatedOsAction}' …"
		su - "${loggedInUser}" -c "/usr/bin/open \"${outdatedOsAction}\""
		exit 1
		
	fi
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Function to check to see if Swift Dialog is installed, and its the correct version.
#	Swift Dialog (Thanks Bart Reardon! https://github.com/bartreardon)
#	https://github.com/swiftDialog/swiftDialog/wiki
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# 	Location of the Swift Dialog binary
dialogApp="/usr/local/bin/dialog"

function dialogCheck() {			
	# Get the URL of the latest PKG From the Dialog GitHub repo
	dialogURL=$(curl -L --silent --fail "https://api.github.com/repos/swiftDialog/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
	
	# Expected Team ID of the downloaded PKG
	expectedDialogTeamID="PWA5E9TQ59"
	
	# Check for Dialog and install if not found
	if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
		# Create temporary working directory
		workDirectory=$( /usr/bin/basename "$0" )
		tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )
		
		# Download the installer package
		/usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"
		
		# Verify the download
		teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
		
		# Install the package if Team ID validates
		if [[ "$expectedDialogTeamID" == "$teamID" ]]; then
			
			/usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
			sleep 2
			dialogVersion=$( /usr/local/bin/dialog --version )
			
		else
			# Display a so-called "simple" dialog if Team ID fails to validate
			osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\r• Dialog Team ID verification failed\r\r" with title "Mac Deployment Toolkit: Error" buttons {"Close"} with icon caution'
			completionActionOption="Quit"
			exitCode="1"
			quitScript
			
		fi
		# Remove the temporary working directory when done
		/bin/rm -Rf "$tempDirectory"
		
	else
		
		updateLog "NAME THIS MAC PREFLIGHT: SwiftDialog version $(/usr/local/bin/dialog --version) found; proceeding..."
		
	fi
	
}

if [[ ! -e "/Library/Application Support/Dialog/Dialog.app" ]]; then
	dialogCheck
else
	updateLog "NAME THIS MAC PREFLIGHT: SwiftDialog version $(/usr/local/bin/dialog --version) found; proceeding..."
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Build out the arguments used to configure the dialog window.
#	!Be careful making changes to the textfield arguments!
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

#	Text to appear in the information line at the bottom of the window.
scriptVersion="Name This Mac v1.0"
infoText="$debugState Version: $scriptVersion; macOS: $osVersion"


#	Set which Intro message to use
if [[  $userType == "Tech" ]]; then
	instructionsMessage=$techInstructionsMessage
else
	instructionsMessage=$userInstructionsMessage
fi

#	Variable that constructs the instructions window dialog
dialogCMD="$dialogApp -p \
--bannerimage \"$bannerimage\" \
--height '650' \
--bannertitle \"$title\" \
--titlefont 'shadow=true, size=36,colour=#6E6E6E' \
--icon \"$icon\" \
--blurscreen 'true' \
--message \"$instructionsMessage\" \
--messagefont 'size=12' \
--infobox \"$infoBoxText\" \
--infotext \"$infoText\" \
--textfield \"User ID (Assigned to User)\",required,prompt=\"Enter the User ID (Not the Employee ID!) of the Assigned to User.\" \
--textfield \"Room #\",prompt=\"Optional\" \
--textfield \"Asset Tag\",prompt=\"Black or blue barcode sticker\" \
--selecttitle \"Department\",required --selectvalues \"$departmentListRaw\" --selectdefault \"Please select your department\" \
--selecttitle \"Location\",required --selectvalues \"$locationListRaw\" --selectdefault \"Please select your location\" \
--button1text \"Continue\"
"
# For the purposes of other organizations that might want to use this script the regex validation was removed from Line 349  If User ID validation is desired, modify the labels and the regex on the line as needed then replace Line 349 with the updated value.
# --textfield \"User ID (Assigned to User)\",required,prompt=\"Enter the User ID (Not the Employee ID!) of the Assigned to User.\",regex='^[a-zA-Z]{2,4}[0-9]{1,4}$',regexerror=\"This may not be a valid Asset ID.  If you are not sure, leave this field blank.\" \

# For the purposes of other organizations that might want to use this script the regex validation was removed from Line 351.  If Asset tag validation is desired, modify the labels and the regex on the line below as needed then replace Line 351 with the updated value.
#--textfield \"Asset Tag\",prompt=\"Group 1/Group 3 only: Black or blue barcode sticker\" \regex='^(Group 1|group 1|Group 3|group 3)?(-)?[0-9]{5,}',regexerror=\"This may not be a valid Asset ID.  If you are not sure, leave this field blank.\"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Run the command and show the output (output goes to stdout)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
fullValue=$(eval "$dialogCMD" )
#updateLog "The full output is: $fullValue" #uncomment for testing

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Capture the exit code.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
dialogResults=$?
#echo $dialogResults #uncomment for testing

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Variable Extraction
#	Here we extract user entered values to variables used to build the computer name
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
userID=$(echo "$fullValue" | awk -F' : ' '/User ID : /{print $2}' )
assetTag=$(echo "$fullValue" | awk -F' : ' '/Asset Tag : /{print $2}' )
roomNumber=$(echo "$fullValue" | awk -F' : ' '/Room/{print $2}' )
department=$(echo "$fullValue" | awk -F' : ' '/"Department" : /{print $2}'  | sed 's/"//g')
location=$(echo "$fullValue" | awk -F' : ' '/"Location" : /{print $2}'  | sed 's/"//g')


#	Check if user entered an Asset tag #.  If not, create a random string
if [[  -z "$assetTag" ]]; then
	updateLog "NAME THIS MAC USER INFO:  The user did not enter an Asset Tag."
	computerNameRandomString=$(uuidgen | tr -d '-' | cut -c -5 )
	updateLog "NAME THIS MAC USER INFO:  Random string: $computerNameRandomString"
else
	updateLog "NAME THIS MAC USER INFO:  The Asset Tag is: $assetTag"
	# Get the number portion of the Asset Tag
	assetTagNumber=${assetTag: -5}
	updateLog "NAME THIS MAC USER INFO:  Asset Numbers Only: $assetTagNumber."
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Get the Dept and Location values needed to construct the new name
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Get the deptCode from the selected Department name
[[ $deptNameCodeList =~ $'\n'"$department"=([^$'\n',]*) ]]
deptCode=${BASH_REMATCH[1]}

# Get the locationCode from the selected Location
[[ $locationNameCodeList =~ $'\n'"$location"=([^$'\n',]*) ]]
locationCode=${BASH_REMATCH[1]}

#	Logging the Department and Location info
if [[ $department == "Please select your department" ]]; then
	updateLog "NAME THIS MAC USER INFO:  User did not select a Department; using default selection."
else
	updateLog "NAME THIS MAC USER INFO:  The Department is: $department."
	updateLog "NAME THIS MAC USER INFO:  The DeptCode is: $deptCode."
fi
if [[ $location == "Please select your location" ]]; then
	updateLog "NAME THIS MAC USER INFO:  User did not select Location; using default selection."
else
	updateLog "NAME THIS MAC USER INFO:  The Location is: $location."
	updateLog "NAME THIS MAC USER INFO:  The LocationCode is: $locationCode."
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Build the new ComputerName, HostName and LocalHostName
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
computerNamePrefix="" # Leave this empty and/or remove from lines 430/433 if not needed
computerNameSuffix="" # Leave this empty and/or remove from lines 430/433 if not needed

if [ -z ${assetTag} ]; then
	newComputerName=($computerNamePrefix$deptCode$locationCode$compType$computerNameRandomString$computerNameSuffix)  #User did not enter an Asset Tag value.  Use random string
	updateLog "NAME THIS MAC USER INFO:  Proposing standard computer name with random string: $newComputerName"
else
	newComputerName=($computerNamePrefix$deptCode$locationCode$compType$assetTagNumber$computerNameSuffix)
	updateLog "NAME THIS MAC USER INFO:  Proposing standard computer name with asset tag number: $newComputerName"
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Get the current ComputerName, HostName and LocalHostName
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
currentHostName=$(scutil --get HostName)
currentLocalHostName=$(scutil --get LocalHostName)
currentCompterName=$(scutil --get ComputerName)
updateLog "NAME THIS MAC CONFIRM NAME: Current HostName: $currentHostName"
updateLog "NAME THIS MAC CONFIRM NAME: Current LocalHostName: $currentLocalHostName"
updateLog "NAME THIS MAC CONFIRM NAME: Current ComputerName: $currentCompterName"
updateLog "NAME THIS MAC CONFIRM NAME: - Transitioning to Name Confirmation window."

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Create a new Dialog window showing the suggested computer name
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
techupdateNameMessage="The new computer name is shown below; this name is compliant with Standard Desktop Name requirements.  \n\nIf the name needs to be modified enter the updated name in the field below then click **$button1Value** or press Return to update the computer name and close this window. The new computer name will be set and the computer inventory record updated with the new name."

userupdateNameMessage="New computer name: **$newComputerName**.  \n\nThis name is compliant with Standard Desktop Name requirements.  \n\nClick **$button1Value** or press Return to update the computer name and close this window. The new computer name will be set and the computer inventory record updated with the new name."

if [ "$dialogResults" = 0 ]; then # Transition to the name confirmation window.
	if [[ "$userType" == "Tech" ]]; then # Techs are allowed to modify the suggested computer name prior to it being set.
		updateLog "NAME THIS MAC CONFIRM NAME: User clicked Continue: Update the window with the new computer name."
		DialogCMD="$dialogApp -p \
		--bannerimage \"$bannerimage\" \
		--height '500' \
		--bannertitle \"$title\" \
		--titlefont 'shadow=1,colour=#6E6E6E' \
		--icon \"$icon\" \
		--blurscreen 'true' \
		--timer '30' \
		--message \"$techupdateNameMessage\" \
		--messagefont 'size=14' \
		--infobox \"$infoBoxText\" \
		--infotext \"$infoText\" \
		--textfield \"Default Computer Name\",value=\"$newComputerName\" \
		--button1text \"$button1Value\" "
		
		computerNameValue=$(eval "$DialogCMD" )
		updatedComputerNameValue=$(echo "$computerNameValue" | awk -F' : ' '/Default Computer Name : /{print $2}' ) # result of the tech changing the name from the default selection.
		if [[ $upatedComputerNameValue != $newComputerName ]]; then
			updateLog "NAME THIS MAC CONFIRM NAME: The tech entered a non-standard computer name of $updatedComputerNameValue"
			newComputerName=$updatedComputerNameValue
		else
			updateLog "NAME THIS MAC CONFIRM NAME: The tech used the suggested computer name of $newComputerName"
		fi
	
	else # standard users are not allowed to change the computer name
		updateLog "NAME THIS MAC CONFIRM NAME: User clicked Continue: Updating the window with the new computer name."
		DialogCMD="$dialogApp -p \
		--bannerimage \"$bannerimage\" \
		--height '500' \
		--bannertitle \"$title\" \
		--titlefont 'shadow=1,colour=#6E6E6E' \
		--icon \"$icon\" \
		--blurscreen 'true' \
		--timer '30' \
		--message \"$userupdateNameMessage\" \
		--messagefont 'size=14' \
		--infobox \"$infoBoxText\" \
		--infotext \"$infoText\" \
		--button1text \"$button1Value\" "
		
		computerNameValue=$(eval "$DialogCMD" )
		updateLog "NAME THIS MAC CONFIRM NAME: The computer name will be set to $newComputerName."
	fi
dialogResults=$?
	if [ "$dialogResults" = 0 ]; then # do the things to change the computer name.
		updateLog "NAME THIS MAC CONFIRM NAME: User clicked Done."
		updateLog "###"
		updateLog "###"
		if [ "$debugMode" = "true" ]; then # for testing debug can be manually enabled/disabled on lines #155/156
			updateLog "NTM DEBUG MODE ENABLED: In Production Mode the new ComputerName would be set to $newComputerName"
			updateLog "NTM DEBUG MODE ENABLED: In Production Mode the new HostName would be set to $newComputerName"
			updateLog "NTM DEBUG MODE ENABLED: In Production Mode the new LocalHostName would be set  to $newComputerName"
			updateLog "NTM DEBUG MODE ENABLED: In Production Mode a Jamf recon would be performed."
		else
			updateLog "NAME THIS MAC CONFIRM NAME: Setting Computer Name."
			scutil --set HostName $newComputerName
			scutil --set LocalHostName $newComputerName
			scutil --set ComputerName $newComputerName
			updateLog "NAME THIS MAC CONFIRM NAME: Setting the new ComputerName to $newComputerName"
			updateLog "NAME THIS MAC CONFIRM NAME: Setting the new HostName to $newComputerName"
			updateLog "NAME THIS MAC CONFIRM NAME: Setting the new LocalHostName to $newComputerName"
			updateLog "NAME THIS MAC CONFIRM NAME: Sending info to JSS"
			jamf recon -assetTag "$AssetTag" -endUsername "$userID" #optionally add other values as needed.
		fi
		if [[ $selfServiceScriptMode == "Self Service" ]]; then
			updateLog "NAME THIS MAC CONFIRM NAME: Name setting is complete.  Script is running in Self Service mode; exiting."
			updateLog "NAME THIS MAC CONFIRM NAME: Name This Mac is complete"
		else
			updateLog "NAME THIS MAC CONFIRM NAME: Name setting is complete.  Script is running in Provisioning mode; continuing to provisioning workflow."
		fi
		updateLog "NAME THIS MAC CONFIRM NAME: Exiting with result $dialogResults"
	else
		updateLog "NAME THIS MAC CONFIRM NAME: Exited with some other error"
	fi
else
	updateLog "NAME THIS MAC CONFIRM NAME: Dialog exited with an unexpected code."
	updateLog "NAME THIS MAC CONFIRM NAME: Could be an error in the dialog command"
	updateLog "NAME THIS MAC CONFIRM NAME: Could be the process killed somehow."
	updateLog "NAME THIS MAC CONFIRM NAME: Exit with an error code."
	
fi
exit "$dialogResults"
