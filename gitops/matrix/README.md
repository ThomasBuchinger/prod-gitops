# Matrix

This Matrix Server has a few Problems in the Automation

* The User `@bot` is created "manually" in a PostStartLifecycleHook
  * The password reuses the `S3_SECRET_KEY` variable currently
* Rooms are auto-created, but everyone Joining the server auto-joins ALL the rooms
  * Figure out how to auto-create rooms without everyone joining
  * Maybe make the Room-names a bit nicer?
* Media-Files are only stored in EmptyDir
* E2E Encryption is not active for Rooms per default

Things that need to be done manually:

* Add a local Name to the Rooms
* Add message exiration to Rooms
* Moble-App Login & Device verification
