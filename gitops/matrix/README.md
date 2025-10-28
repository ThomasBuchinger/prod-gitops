# Matrix

This Matrix Server has a few Problems in the Automation

* The User `@bot` is created "manually" in a PostStartLifecycleHook
  * The password is also in Plain-Text
* Rooms must be created manually?
* Media-Files are only stored in EmptyDir
* A bunch of Kays are auto-generated. restarting the Pod is probably going to cause problems until the user relogs
* Currently there is a Auto-join room for the Bot, that should not be joined by everyone
