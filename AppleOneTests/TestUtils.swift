//
//  TestUtils.swift
//  AppleOne
//
//  Created by James Weatherley on 28/11/2025.
//

import Foundation
import Combine
import Testing
@testable import AppleOne

@MainActor
func waitForInitialPrompt(viewModel: AppleOneViewModel, updates: AnyPublisher<String, Never>) async {
    // Expected output after initialisation
    let expectedOutput =
    """
    \\
    
    """

    // Await until the entire published text equals our expected transcript
    guard let result = await first(in: updates, timeout: 3.0, where: { $0 == expectedOutput }) else {
        Issue.record("Timed out")
        return
    }
    
    #expect(result == "\\\n")
    #expect(viewModel.appleOne != nil)
}

// Check the actual output matched the expected output.
func checkOutput(expectedOutput: String, updates: AnyPublisher<String, Never>) async {
    guard let finalValue = await first(in: updates, timeout: 3.0, where: { $0 == expectedOutput}) else {
        Issue.record("Timed out")
        return
    }
    #expect(finalValue == expectedOutput)
}

// As above, but chattier. Use if you need to understand why actual ans expected values differ.
func checkOutputDebug(expectedOutput: String, updates: AnyPublisher<String, Never>) async {
    guard let finalValue = await first(in: updates, timeout: 3.0, where: { output in
        print("checkOutputDebug received: \(Array(output))")
        print("checkOutputDebug expected: \(Array(expectedOutput))")

        return output == expectedOutput
    }) else {
        Issue.record("Timed out")
        return
    }
    #expect(finalValue == expectedOutput)
}

// Helper to await the first element of a Combine Publisher that matches a predicate, with a timeout.
func first<P: Publisher>(
    in publisher: P,
    timeout seconds: TimeInterval,
    where predicate: @escaping (P.Output) -> Bool = { _ in true }
) async -> P.Output? {
    await withTaskGroup(of: P.Output?.self) { group in
        // Producer task: waits for first element matching predicate
        group.addTask {
            do {
                for try await value in publisher.values {
                    if predicate(value) { return value }
                }
            } catch {
                print(error)
            }
            return nil
        }

        // Timeout task
        group.addTask {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            return nil
        }

        let result = await group.next() ?? nil
        group.cancelAll()
        return result
    }
}
