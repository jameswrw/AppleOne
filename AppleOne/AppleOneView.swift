//
//  AppleOneView.swift
//  AppleOne
//
//  Created by James Weatherley on 26/11/2025.
//

import SwiftUI

struct AppleOneView: View {
    @StateObject private var viewModel = AppleOneViewModel()
    
    var body: some View {
        VStack {
            AppleOneTextView(
                text: $viewModel.text,
                font: .init(name: "Monaco", size: 18) ?? .monospacedSystemFont(ofSize: 18, weight: .regular),
                foregroundColor: .systemGreen,
                backgroundColor: .black,
                onKeyPress: { chars in
                    viewModel.keyPressed(chars)
                }
            )
            .tint(.green)
            Button("Reset") {
                print("Reset!")
            }
        }
        .padding()
    }
}

#Preview {
    AppleOneView()
}
