//
//  AppleOne.swift
//  AppleOne
//
//  Created by James Weatherley on 26/11/2025.
//

import Foundation
import os

import Swift6502

typealias OutputCharacterHandler = (_: UInt8) -> Void

// A small, lock-protected byte FIFO suitable for synchronous access from CPU callbacks.
private final class LockedByteBuffer: @unchecked Sendable {
    // We're using locks, so this should be safe.
    nonisolated(unsafe) private var storage: [UInt8] = []
    private let lock = NSLock()

    nonisolated func append(_ byte: UInt8) {
        lock.lock()
        storage.append(byte)
        lock.unlock()
    }

    nonisolated func isEmpty() -> Bool {
        lock.lock()
        let empty = storage.isEmpty
        lock.unlock()
        return empty
    }

    nonisolated func popFirst() -> UInt8? {
        lock.lock()
        let value = storage.isEmpty ? nil : storage.removeFirst()
        lock.unlock()
        return value
    }
}

final class AppleOne {
    fileprivate let KBD: UInt16 = 0xD010    // Keyboard input register
    fileprivate let KBDCR: UInt16 = 0xD011  // If bit 7 is 1 then KBD has valid data. Bit is cleared on reading KBD
    fileprivate let DSP: UInt16 = 0xD012    // Bits 6 to 0 are the character output
    fileprivate let DSPCR: UInt16 = 0xD013  // Do not touch apparently!
    
    var outputCharacterHandler: OutputCharacterHandler? = nil
    private var cpu: CPU6502!
    nonisolated(unsafe) private var memory: UnsafeMutablePointer<UInt8>!

    // Host-to-Apple-1 keypress buffer (bytes with bit 7 already set, as Apple-1 expects).
    private let keyboardBuffer = LockedByteBuffer()
    
    init?(outputCharacterHandler: OutputCharacterHandler? = nil) async {
        self.outputCharacterHandler = outputCharacterHandler

        memory = initMemory()
        cpu = initCPU(memory: memory, ioAddresses: [KBD, KBDCR, DSP, DSPCR])
        await initIO(cpu: cpu)
    }
    
    deinit {
        memory.deallocate()
    }
    
    func inputCharacter(_ characterCode: UInt8) {
        // Apple-1 expects bit 7 set when presenting to KBD.
        keyboardBuffer.append(characterCode | 0x80)
    }
    
    func run() async {
        let clockspeedMHz = 1.0
        let fps = 60
        let frameInterval = UInt64(1_000_000_000 / fps)
        
        while true {
            await cpu.runForFrame(clockspeed: clockspeedMHz, fps: fps)
//            await cpu.singlestep()
            try? await Task.sleep(nanoseconds: frameInterval)
        }
    }
    
    fileprivate func initMemory() -> UnsafeMutablePointer<UInt8> {
        let memory = UnsafeMutablePointer<UInt8>.allocate(capacity: 0x10000)
        memset(memory, 0, 0x10000)
        
        let rom = WozMonROM().rom
        let _ = rom.withUnsafeBytes { (romBytes: UnsafeRawBufferPointer) in
            memcpy(memory + 0xFF00, romBytes.baseAddress, romBytes.count)
        }

        return memory
    }
    
    fileprivate func initCPU(memory: UnsafeMutablePointer<UInt8>, ioAddresses: Set<UInt16> = []) -> CPU6502 {
        CPU6502(memory: MemoryWrapper(memory), ioAddresses: ioAddresses)
    }
    
    // Execute on the CPU actor so we can call its actor-isolated methods.
    fileprivate func initIO(cpu: isolated CPU6502) async {
        // Some info here: https://www.sbprojects.net/projects/apple1/wozmon.php - more in the annotated disassembly.
        // See also the Apple I manual: https://s3data.computerhistory.org/brochures/apple.applei.1976.102646518.pdf
        //
        // WozMon RESET does the following:
        // • Write 0x7F to DSP
        // • Write 0xA7 to KBDCR and DSPCR
        // • Fall through to GETLINE
        //
        // This can be seen as:
        //   I/O write of 0x7F (0x7F) to DSP
        //   I/O write of 0xA7 (0x27) to KBDCR
        //   I/O write of 0xA7 (0x27) to DSPCR
        // In the debug console on launch.
        // The writes are initialisations of the PIA hardware. Here we just squirrel them away in
        // emulated RAM in case anyone cares later on. They obviously don't care about DSP, as the
        // next section indicates, as it writes PROMPT and NEWLINE there. I guess it's a way of
        // clobbering the high bit to indicate it's ready for reading.
        //
        // GETLINE inherits 0x7F in A from RESET, which leads to an escape, which in turn leads to
        // PROMPT (0x5C - '\') being written to DSP. In fact 0xDC (0x5C with bit 7 set) is written.
        // WozMon then polls DSP until it sees the high bit has been cleared and then outputs a new
        // line (0x0D). Again it sets the high bit, so actually 0x8D.
        //
        // Next it gets into a loop:
        //  I/O read at KBDCR - high bit is clear indicating not ready - i.e. keyboardBuffer is empty.
        //  Repeat
        //
        // When the host receives a key press it is added to keyboardBuffer. 0x0A (NL) is translated to OX0D (CR)
        // and everything gets the msb set, because that's what the Apple I expects. KBDCR will also have the high bit
        // set, as there is stuff in keyboardBuffer. This causes WozMon to read KBD, which sends the first item in
        // the buffer. This will then be echoed to screen via a write to DSP. Again there is a translation. This time
        // 0x0D (CR) is translated to OX0A (NL). If the host provides a CR to WozMon the line is interpreted as a
        // command and executed.
        
        cpu.setIOReadCallback { [weak self] (address: UInt16) in
            guard let self = self else { return nil }
            
            switch address {
            case self.KBDCR: // 0xD011
                // Bit 7 indicates “data ready”
                return self.keyboardBuffer.isEmpty() ? 0x00 : 0x80
            case self.KBD: // 0xD010
                // Return next queued byte (already has bit 7 set), or nil if none
                if let byte = self.keyboardBuffer.popFirst() {
                    Logger().info("I/O read of \(byte) from KBD")
                    return byte
                }
                return nil
            default:
                return nil
            }
        }
        cpu.setIOWriteCallback { [weak self] (address: UInt16, value: UInt8) in
            guard let self = self else { return value }

            if address == self.DSP {
                // Hop to the main actor to invoke UI-bound handler safely.
                Task { @MainActor in
                    self.outputCharacterHandler?(value & 0x7F)
                    let logMessage = String(
                        format: "I/O write of %c to DSP", value & 0x7F, address
                    )
                    Logger().info("\(logMessage)")
                }
                
                // Clear msb to indicate we've dealt with the write to display.
                return value & 0x7F
            }
            return value
        }
    }
    
    fileprivate nonisolated func addressToMnemonic(_ address: UInt16) -> String {
        switch address {
        case 0xD010: return " (KBD)"
        case 0xD011: return " (KBDCR)"
        case 0xD012: return " (DSP)"
        case 0xD013: return " (DSPCR)"
        default:
            return ""
        }
    }
}
