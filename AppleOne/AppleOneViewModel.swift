//
//  AppleOneViewModel.swift
//  AppleOne
//
//  Created by James Weatherley on 26/11/2025.
//

import Foundation
import Combine

import Swift6502

public final class AppleOneViewModel: ObservableObject {
    
    @Published var text: String = ""
    var appleOne: AppleOne?
    
    init() {
        Task {
            await appleOne = AppleOne(outputCharacterHandler: outputCharacterHandler)
            await appleOne?.run()
        }
    }
    
    func outputCharacterHandler(_ key: UInt8) {
        var output = key
        if output == 0x0D {
            output = 0x0A
        }
        text.append(String(UnicodeScalar(output)))
    }
    
    func keyPressed(_ key: String) {
        // Ignore non-ASCII
        if key.count == 1, var asciiValue = key.uppercased().unicodeScalars.first?.value, asciiValue < 0x80 {
            if asciiValue == 0x0A {
                asciiValue = 0x0D
            }
            appleOne?.inputCharacter(UInt8(asciiValue))
        }
    }
    
}

