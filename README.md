# AppleOne

**This is a work in progess.**

An Apple I emulator that uses the [Swift6502](https://github.com/jameswrw/Swift6502) CPU core. It starts you off in WozMon, and you can find some instructions on how to use it [here](https://www.sbprojects.net/projects/apple1/wozmon.php).

There is functionality for loading binary blobs into memory. The data loads successfully, and you can jump to it from WozMon, but success is in the hands of the 6502 emulation gods. For instance Apple Integer BASIC is built in starting at **0xE000**, so **E2000R** in WozMon will enter it. However, it doesn't work properly. The '**>**' cursor has a trailing zero, and pretty much any text entry results in a syntax error. As mentioned previously, this is likely an issue with the 6502 emulation.
