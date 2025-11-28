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
        textView.isEditable = false
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
        textView.layoutManager?.usesDefaultHyphenation = false

        // Set typing attributes up-front
        textView.font = font
        textView.textColor = foregroundColor
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

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: AppleOneTextView
        weak var textView: NSTextView?

        private var isUpdating = false
        private var pendingUpdate: (() -> Void)?

        init(_ parent: AppleOneTextView) {
            self.parent = parent
        }

        func performCoalescedUpdate(_ block: @escaping () -> Void) {
            if isUpdating {
                pendingUpdate = block
                return
            }
            isUpdating = true
            block()
            isUpdating = false

            if let next = pendingUpdate {
                pendingUpdate = nil
                DispatchQueue.main.async { [weak self] in
                    self?.performCoalescedUpdate(next)
                }
            }
        }

        func replaceText(_ newText: String, scrollToBottom: Bool, in scrollView: NSScrollView) {
            guard let tv = textView else { return }

            if let container = tv.textContainer {
                let width = scrollView.contentView.bounds.width
                if container.containerSize.width != width {
                    container.containerSize.width = width
                }
                container.lineBreakMode = .byCharWrapping
            }

            tv.layoutManager?.allowsNonContiguousLayout = true
            if let container = tv.textContainer {
                tv.layoutManager?.ensureLayout(for: container)
            }

            // Build a paragraph style that enforces char wrapping and disables hyphenation
            let para = NSMutableParagraphStyle()
            para.lineBreakMode = .byCharWrapping
            para.hyphenationFactor = 0

            tv.textStorage?.beginEditing()
            tv.string = newText
            let fullRange = NSRange(location: 0, length: (newText as NSString).length)
            if fullRange.length > 0 {
                tv.textStorage?.setAttributes([
                    .font: parent.font,
                    .foregroundColor: parent.foregroundColor,
                    .paragraphStyle: para
                ], range: fullRange)
            }
            tv.textStorage?.endEditing()

            if let container = tv.textContainer {
                tv.layoutManager?.ensureLayout(for: container)
            }

            if scrollToBottom {
                tv.scrollToEndOfDocument(nil)
            }
        }

        func handleKeyPress(_ string: String) {
            parent.onKeyPress(string)
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = textView, parent.text != tv.string else { return }
            parent.text = tv.string
        }
    }

    // MARK: - Subclasses

    final class NoPageScrollView: NSScrollView {
        override func keyDown(with event: NSEvent) {
            let kVK_Space: UInt16 = 49
            if event.keyCode == kVK_Space { return }
            super.keyDown(with: event)
        }

        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            let kVK_Space: UInt16 = 49
            if event.keyCode == kVK_Space { return true }
            return super.performKeyEquivalent(with: event)
        }
    }

    final class WrapToWidthTextView: NSTextView {
        weak var host: Coordinator?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.makeFirstResponder(self)
        }

        override var acceptsFirstResponder: Bool { true }

        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            let kVK_Space: UInt16 = 49
            let pageUp: UInt16 = 116
            let pageDown: UInt16 = 121
            let home: UInt16 = 115
            let end: UInt16 = 119
            switch event.keyCode {
            case kVK_Space, pageUp, pageDown, home, end:
                if let chars = event.characters, !chars.isEmpty {
                    host?.handleKeyPress(chars)
                } else if let charsIgnoringMods = event.charactersIgnoringModifiers, !charsIgnoringMods.isEmpty {
                    host?.handleKeyPress(charsIgnoringMods)
                }
                return true
            default:
                return super.performKeyEquivalent(with: event)
            }
        }

        override func keyDown(with event: NSEvent) {
            if let chars = event.characters, !chars.isEmpty {
                host?.handleKeyPress(chars)
                return
            }
            if let charsIgnoringMods = event.charactersIgnoringModifiers, !charsIgnoringMods.isEmpty {
                host?.handleKeyPress(charsIgnoringMods)
                return
            }
        }
    }
}
