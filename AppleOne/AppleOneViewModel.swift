//
//  AppleOneViewModel.swift
//  AppleOne
//
//  Created by James Weatherley on 26/11/2025.
//

import Foundation
import Combine
import os

import Swift6502

public final class AppleOneViewModel: ObservableObject {
    
    @Published var text = ""
    @Published var halt = false
    @Published var echoDelete = true
    @Published var loadAddress = "0x2000"

    var appleOne: AppleOne?
    var oldLoadAddress = "0x2000"
    
    init() {
        reset()
    }
    
    func reset() {
        Task {
            await appleOne?.haltExecution(true)
            text = ""
            appleOne?.freeMemory()
            
            await appleOne = AppleOne(outputCharacterHandler: outputCharacterHandler)
            await appleOne?.run()
            await appleOne?.haltExecution(halt)
        }
    }
    
    func haltExecution() async {
        await appleOne?.haltExecution(halt)
    }
    
    func outputCharacterHandler(_ key: UInt8) {
        var output = key
        
        // The Apple 1 uses 0x0D (CR) for newline, so translate to 0x0A (NL) for the host.
        if output == 0x0D {
            output = 0x0A
        }
        
        if output == 0x0A || (0x20..<0x7F).contains(output) {
            // WozMon uses 0x5F '_' for backspace.
            if output == 0x5F {
                if echoDelete {
                    let _ = text.popLast()
                }
            } else {
                text.append(String(UnicodeScalar(output)))
            }
        }
    }
    
    func keyPressed(_ key: String) {
        // Ignore non-ASCII
        if key.count == 1, var asciiValue = key.uppercased().unicodeScalars.first?.value, asciiValue < 0x80 {
            // The Apple 1 uses 0x0D (CR) for newline, so translate from 0x0A (NL) provided by the host.
            //
            // Strangely, it uses 0x5F ('_') for backspace, so translate from the host which provides 0x7F.
            // This could be a mistake from Woz, interpreting a terminal rubout causing '_' to be displayed,
            // so WozMon looks for a literal 0x5F, rather than 0x7F which would have generated the '_' as
            // a placeholder for 0x7F.
            if asciiValue == 0x0A {
                asciiValue = 0x0D
            } else if asciiValue == 0x7F {
                asciiValue = 0x5F
            }
            appleOne?.inputCharacter(UInt8(asciiValue))
        }
    }
 
    func load(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            Logger().error("Sandbox issue, can't read file")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            
            if let address = UInt16(loadAddress.removePrefix("0x"), radix: 16) {
                if data.count >= UInt16.max {
                    Logger().error("Error: File too large for this Apple 1.")
                } else if Int(address) + data.count > UInt16.max {
                    Logger().error("Error: File too large at the given load address.")
                }
                
                Task {
                    await appleOne?.blitData(data, toAddress: address)
                }
            }
        } catch {
            Logger().error("Error loading file (\(url)): (error.localizedDescription)")
        }
        url.stopAccessingSecurityScopedResource()
    }
    
    func validateLoadAddress() {
        let regex = /^(0x)?[0-9A-Fa-f]{,4}$/
        if loadAddress.firstMatch(of: regex) == nil {
            loadAddress = oldLoadAddress
        }
        
        loadAddress = "0x" + loadAddress
            .removePrefix("0x")
            .uppercased()
            .leftPadding(toLength: 4, withPad: "0")
        oldLoadAddress = loadAddress
    }
}

