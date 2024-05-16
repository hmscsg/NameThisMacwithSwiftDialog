# NameThisMacwithSwiftDialog
Name This Mac with Swift Dialog is a shell script used to set the computer name in Mac OS.
It uses Bart Reardon's [SwiftDialog[(https://github.com/swiftDialog/swiftDialog) and is inspired by Dan Snelson's [Setup Your Mac](https://github.com/setup-your-mac/Setup-Your-Mac) (and other works)

This script was written because my organization has a complicated computer naming policy established many years ago.  My grad school also manages Jamf for 1 other grad school and a large research department.
When we started using Setup Your Mac, the SYM script was heavily modified to accommodate our needs, but it wasn't quite perfect, as it didn't account for all 3 groups that use our Jamf environment. And it made upgrading to later versions of SYM difficult.

Enter Name This Mac (here on referenced as NTM).

With NTM, I was able to separate the script needed for computer naming from the SYM code, making upgrading SYM much easier.  Using Jamf parameters I was also able to create use cases where NTM could be run as a standalone Self Service policy or as part of the SYM provisioning process, and also create an option where the suggested name could be modifed by technicians running the policy.
