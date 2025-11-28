//
//  AppleOneTextView.swift
//  AppleOne
//
//  Created by James Weatherley on 27/11/2025.
//

import SwiftUI
import AppKit

struct AppleOneTextView: NSViewRepresentable {
    @Binding var text: String

    var font: NSFont = .monospacedSystemFont(ofSize: 18, weight: .regular)
    var foregroundColor: NSColor = .systemGreen
    var backgroundColor: NSColor = .black

    // Called for each key press received by the hosted text view.
    var onKeyPress: (String) -> Void = { _ in }

    func makeNSView(context: Context) -> NSScrollView {
        // Use a scroll view subclass that ignores space paging
        let scrollView = NoPageScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        // Configure text view
        let textView = WrapToWidthTextView()
        textView.host = context.coordinator

        // Important: allow editing so the insertion point (caret) is drawn.
        // We'll still block actual edits in shouldChangeText.
        textView.isEditable = true
        textView.isSelectable = true

        textView.isRichText = false
        textView.importsGraphics = false
        textView.usesFindPanel = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.allowsUndo = false

        // Disable default hyphenation via layout manager (modern API)
        textView.layoutManager?.usesDefaultHyphenation = false

        // Set visual attributes up-front
        textView.font = font
        textView.textColor = foregroundColor
        textView.insertionPointColor = foregroundColor
        textView.backgroundColor = backgroundColor
        textView.drawsBackground = true
        textView.textContainerInset = .zero

        // Wrap at view width, but break by character (not punctuation/word)
        if let container = textView.textContainer {
            container.widthTracksTextView = true
            container.containerSize = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
            container.lineBreakMode = .byCharWrapping
        }

        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]

        // Hook up delegate
        textView.delegate = context.coordinator

        // Embed in scroll view
        scrollView.documentView = textView

        // Initial content
        context.coordinator.textView = textView
        context.coordinator.parent = self
        context.coordinator.replaceText(text, scrollToBottom: true, in: scrollView)

        // Make it first responder so the caret shows immediately
        textView.window?.makeFirstResponder(textView)

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }

        // Keep the container tracking the visible width if the view resized
        if let container = textView.textContainer {
            let width = nsView.contentView.bounds.width
            if container.containerSize.width != width {
                container.containerSize.width = width
            }
            // Re-assert desired wrapping behavior
            if container.lineBreakMode != .byCharWrapping {
                container.lineBreakMode = .byCharWrapping
            }
        }

        // Coalesce frequent updates and only replace when content actually differs
        if textView.string != text {
            let wasAtBottom = isAtBottom(scrollView: nsView)
            context.coordinator.performCoalescedUpdate {
                context.coordinator.replaceText(text, scrollToBottom: wasAtBottom, in: nsView)
            }
        }

        // Re-apply colors and font if theme changes dynamically
        if textView.font != font { textView.font = font }
        if textView.textColor != foregroundColor { textView.textColor = foregroundColor }
        if textView.insertionPointColor != foregroundColor { textView.insertionPointColor = foregroundColor }
        if textView.backgroundColor != backgroundColor { textView.backgroundColor = backgroundColor }

        // Only set first responder if none yet
        if textView.window?.firstResponder == nil {
            textView.window?.makeFirstResponder(textView)
        }

        context.coordinator.parent = self
    }

    private func isAtBottom(scrollView: NSScrollView) -> Bool {
        guard let docView = scrollView.documentView else { return true }
        let clipView = scrollView.contentView
        let maxY = docView.bounds.maxY - clipView.bounds.height
        return clipView.bounds.origin.y >= maxY - 2
    }

    func makeCoordinator() -> AppleOneTextViewCoordinator {
        AppleOneTextViewCoordinator(self)
    }

}
