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
            .frame(width: 445, height: 600)
            .tint(.green)
            HStack {
                Button("Reset") {
                    viewModel.reset()
                }
                Toggle("Halt", isOn: $viewModel.halt)
                    .onChange(of: viewModel.halt, initial: false) {
                        Task {
                            await viewModel.haltExecution()
                        }
                    }
                Toggle("Echo delete", isOn: $viewModel.echoDelete)
            }
        }
        .padding()
    }
}

#Preview {
    AppleOneView()
}
