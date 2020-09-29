This is the source for the progs.dat for https://github.com/Paril/quake2c
Please see the main project if you're looking to actually run the progs. This is just the source for creating your own progs.dat.

## How to setup ##
* Create a mod folder in your Quake II directory with the name you wish to use for your mod.
* In that folder, Check-out this repository into a subfolder named "progs" (or "progsrc", whatever you wish, just as long as you can tell it's for your prog's source code); this way you have "quake2/\<mod\>/progs/.git" et al ready to go.
* (WINDOWS ONLY) Download the latest release of Quake2C's binaries and plop them in the mod directory.
* Grab compilers from https://fte.triptohell.info/moodles/fteqcc/ - you'll need fteqcc, and probably fteqccgui if you plan on editing with that IDE. Place them in the /progs/ directory, as the quick-batches use these paths to compile. You can use the GUI from anywhere, though, but you'll have to edit `config.qc` to enable/disable debug by hand.
* Good 2 go!! Test the setup by running build-debug.bat; if a progs.dat gets spat out, you're ready to cook.
