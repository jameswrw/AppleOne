//
//  AppleOneTests.swift
//  AppleOneTests
//
//  Created by James Weatherley on 26/11/2025.
//

import Testing
import Combine
@testable import AppleOne

@MainActor
struct AppleOneTests {

    @Test func initViewModel() async throws {
        let viewModel = AppleOneViewModel()
        let updates = viewModel.$text.dropFirst().eraseToAnyPublisher()
        
        await waitForInitialPrompt(viewModel: viewModel, updates: updates)
    }
    
    @Test func viewMemoryLocation() async throws {
        let viewModel = AppleOneViewModel()
        let updates = viewModel.$text.dropFirst().eraseToAnyPublisher()
        await waitForInitialPrompt(viewModel: viewModel, updates: updates)
        
        // Expected output after typing FFFD\n
        let expectedOutput =
        """
        \\
        FFFD
        
        FFFD: FF
        
        """

        // Type the command synchronously on the main actor
        for char in "FFFD\n" {
            viewModel.keyPressed(String(char))
        }

        await checkOutput(expectedOutput: expectedOutput, updates: updates)
    }
    
    @Test func backspaceEchoDelete() async throws {
        let viewModel = AppleOneViewModel()
        viewModel.echoDelete = true
        let updates = viewModel.$text.dropFirst().eraseToAnyPublisher()
        await waitForInitialPrompt(viewModel: viewModel, updates: updates)
                
        // Expected output after typing FFFC\bD\n
        let expectedOutput =
        """
        \\
        FFFD
        """
        
        let delete = UnicodeScalar(0x7F)!
        for char in "FFFC\(delete)D" {
            viewModel.keyPressed(String(char))
        }
        await checkOutput(expectedOutput: expectedOutput, updates: updates)
    }

    @Test func backspaceNoEchoDelete() async throws {
        let viewModel = AppleOneViewModel()
        viewModel.echoDelete = false
        let updates = viewModel.$text.dropFirst().eraseToAnyPublisher()
        await waitForInitialPrompt(viewModel: viewModel, updates: updates)
                
        // Expected output after typing FFFC\bD\n
        let expectedOutput =
        """
        \\
        FFFCD
        """

        let delete = UnicodeScalar(0x7F)!
        for char in "FFFC\(delete)D" {
            viewModel.keyPressed(String(char))
        }
        await checkOutput(expectedOutput: expectedOutput, updates: updates)
    }

    @Test func viewRange() async throws {
        let viewModel = AppleOneViewModel()
        let updates = viewModel.$text.dropFirst().eraseToAnyPublisher()
        await waitForInitialPrompt(viewModel: viewModel, updates: updates)
        
        // Expected output after typing FFF0.FFFF\n
        let expectedOutput =
        """
        \\
        FFF0.FFFF

        FFF0: 12 D0 30 FB 8D 12 D0 60
        FFF8: 00 00 00 0F 00 FF 00 00

        """
        
        for char in "FFF0.FFFF\n" {
            viewModel.keyPressed(String(char))
        }
        await checkOutput(expectedOutput: expectedOutput, updates: updates)
    }
    
    @Test func viewMultipleLocations() async throws {
        let viewModel = AppleOneViewModel()
        let updates = viewModel.$text.dropFirst().eraseToAnyPublisher()
        await waitForInitialPrompt(viewModel: viewModel, updates: updates)
        
        // Expected output after typing "FF00 FF0F FFC2\n"
        let expectedOutput =
        """
        \\
        FF00 FF0F FFC2

        FF00: D8
        FF0F: C9
        FFC2: DC
        
        """
        
        for char in "FF00 FF0F FFC2\n" {
            viewModel.keyPressed(String(char))
        }
        await checkOutput(expectedOutput: expectedOutput, updates: updates)
    }
    
    @Test func viewMultipleRanges() async throws {
        let viewModel = AppleOneViewModel()
        let updates = viewModel.$text.dropFirst().eraseToAnyPublisher()
        await waitForInitialPrompt(viewModel: viewModel, updates: updates)
        
        // Expected output after typing "FF00.FF10 FF20.FF28\n"
        let expectedOutput =
        """
        \\
        FF00.FF10 FF20.FF28

        FF00: D8 58 A0 7F 8C 12 D0 A9
        FF08: A7 8D 11 D0 8D 13 D0 C9
        FF10: DF
        FF20: 8D 20 EF FF A0 01 88 30
        FF28: F6

        """
        
        for char in "FF00.FF10 FF20.FF28\n" {
            viewModel.keyPressed(String(char))
        }
        await checkOutput(expectedOutput: expectedOutput, updates: updates)
    }
    
    @Test func viewRangeAndLocation() async throws {
        let viewModel = AppleOneViewModel()
        let updates = viewModel.$text.dropFirst().eraseToAnyPublisher()
        await waitForInitialPrompt(viewModel: viewModel, updates: updates)
        
        // Expected output after typing "FF00.FF10 FFFD\n"
        let expectedOutput =
        """
        \\
        FF00.FF10 FFFD

        FF00: D8 58 A0 7F 8C 12 D0 A9
        FF08: A7 8D 11 D0 8D 13 D0 C9
        FF10: DF
        FFFD: FF
        
        """
        
        for char in "FF00.FF10 FFFD\n" {
            viewModel.keyPressed(String(char))
        }
        await checkOutput(expectedOutput: expectedOutput, updates: updates)
    }
    
    @Test func viewLocationAndRange() async throws {
        let viewModel = AppleOneViewModel()
        let updates = viewModel.$text.dropFirst().eraseToAnyPublisher()
        await waitForInitialPrompt(viewModel: viewModel, updates: updates)
        
        // Expected output after typing "FFFD FF00.FF10\n"
        let expectedOutput =
        """
        \\
        FFFD FF00.FF10

        FFFD: FF
        FF00: D8 58 A0 7F 8C 12 D0 A9
        FF08: A7 8D 11 D0 8D 13 D0 C9
        FF10: DF
        
        """
        
        for char in "FFFD FF00.FF10\n" {
            viewModel.keyPressed(String(char))
        }
        await checkOutput(expectedOutput: expectedOutput, updates: updates)
    }
    
    @Test func writeMemoryLocation() async throws {
        let viewModel = AppleOneViewModel()
        let updates = viewModel.$text.dropFirst().eraseToAnyPublisher()
        await waitForInitialPrompt(viewModel: viewModel, updates: updates)
        
        // Expected output after typing "30\n30:AA\n30\n"
        let expectedOutput =
        """
        \\
        30

        0030: 00
        30:AA

        0030: 00
        30

        0030: AA

        """
        
        for char in "30\n30:AA\n30\n" {
            viewModel.keyPressed(String(char))
        }
        await checkOutput(expectedOutput: expectedOutput, updates: updates)
    }
    
    @Test func writeMemoryRange() async throws {
        let viewModel = AppleOneViewModel()
        let updates = viewModel.$text.dropFirst().eraseToAnyPublisher()
        await waitForInitialPrompt(viewModel: viewModel, updates: updates)
        
        // Expected output after typing "30.33\n30:A1 A2 A3\n30.33\n"
        let expectedOutput =
        """
        \\
        30.33
        
        0030: 00 00 00 00
        30:A1 A2 A3
        
        0030: 00
        30.33
        
        0030: A1 A2 A3 00
        """
        
        for char in "30.33\n30:A1 A2 A3\n30.33\n" {
            viewModel.keyPressed(String(char))
        }
        await checkOutput(expectedOutput: expectedOutput, updates: updates)
    }
    
    @Test func runProgram() async throws {
        let viewModel = AppleOneViewModel()
        let updates = viewModel.$text.dropFirst().eraseToAnyPublisher()
        await waitForInitialPrompt(viewModel: viewModel, updates: updates)
        
        // Expected output after typing and executing program
        let expectedOutput =
        """
        \\
        3000:A9 57 20 EF FF A9 6F 20 EF FF A9 7A 20 EF FF A9 21 20 EF FF 4C 1F FF

        3000: 00
        R
        Woz!

        """
        
        for char in "3000:A9 57 20 EF FF A9 6F 20 EF FF A9 7A 20 EF FF A9 21 20 EF FF 4C 1F FF\nR\n" {
            viewModel.keyPressed(String(char))
        }
        await checkOutput(expectedOutput: expectedOutput, updates: updates)
    }

}
