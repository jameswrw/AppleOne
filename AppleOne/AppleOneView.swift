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
            TextEditor(text: $viewModel.text)
                .scrollContentBackground(.hidden)
                .background(.black)
                .foregroundColor(.green)
                .tint(.green)
                .font(.custom("Monaco", size: 18))
                .onKeyPress() { keyPress in
                    viewModel.keyPressed(keyPress.characters)
                    return .handled
                }
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
