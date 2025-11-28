//
//  AppleOneTextViewCoordinator.swift
//  AppleOne
//
//  Created by James Weatherley on 28/11/2025.
//

import SwiftUI

final class AppleOneTextViewCoordinator: NSObject, NSTextViewDelegate {
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

        // Block user edits while still allowing a visible caret.
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            // Forward the key press if you still want to handle it
            if let replacementString, !replacementString.isEmpty {
                parent.onKeyPress(replacementString)
            }
            return false
        }
    }
