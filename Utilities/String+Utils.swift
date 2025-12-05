//
//  String+HexUtils.swift
//  AppleOne
//
//  Created by James Weatherley on 29/11/2025.
//

import Foundation

extension String {
    func removePrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    
    func leftPadding(toLength: Int, withPad pad: String) -> String {
        String(String(reversed()).padding(toLength: toLength, withPad: pad, startingAt: 0).reversed())
    }
}
