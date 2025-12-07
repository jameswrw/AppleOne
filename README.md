# AppleOne

**This is a work in progess.**

An Apple I emulator that uses the [Swift6502](https://github.com/jameswrw/Swift6502) CPU core. It starts you off in WozMon, and you can find some instructions on how to use it [here](https://www.sbprojects.net/projects/apple1/wozmon.php).

There is functionality for loading binary blobs into memory. The data loads successfully, and you can jump to it from WozMon, but success is in the hands of the 6502 emulation gods.

Integer BASIC works for simple programs at least.

```
10 FOR X = 0 to 10
20 PRINT "HELLO"
30 NEXT X
```

The above runs as expected. The final line `*** END ERR` is the same as that in another [emulator](https://stid.me). Simple immediate commands like `LIST` also work.
