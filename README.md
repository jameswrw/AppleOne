# AppleOne

**This is a work in progess.**

An Apple I emulator that uses the [Swift6502](https://github.com/jameswrw/Swift6502) CPU core. It starts you off in WozMon, and you can find some instructions on how to use it [here](https://www.sbprojects.net/projects/apple1/wozmon.php).

There's currently no convenient way to load or save code into the emulator, so you had better like typing hex, or hacking up the source. 

It would be nice to get something like Apple Integer BASIC running, but I lack confidence in Swift6502. Running the 256 bytes of WozMon is one thing, something meatier will likely expose issues in the CPU core.