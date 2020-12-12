//
//  File.swift
//  
//
//  Created by neutralradiance on 12/12/20.
//

import SwiftUI
import Combine
import Parser
import Theme

extension _Source {
    class Coordinator: NSObject, TextViewDelegate {
        var view: _Source
        init(view: _Source) {
            self.view = view
        }
        #if os(macOS)
        var selectedRanges: [NSValue] = []
        func textDidChange(_ notification: Notification) {
            guard
                let textView = notification.object as? TextView else { return }
            view.input = textView.string
            view.onChange?()
            highlight(textView)
        }
        func textDidBeginEditing(_ notification: Notification) {
            guard
                let textView = notification.object as? TextView else { return }
            selectedRanges = textView.selectedRanges
            view.input = textView.string
        }
        func textDidEndEditing(_ notification: Notification) {
            //            guard
            //                let textView = notification.object as? TextView else { return }
        }
        #elseif os(iOS)
        func textViewDidChange(_ textView: TextView) {
            view.input = textView.text
            view.onChange?()
            highlight(textView)
        }
        func textViewDidBeginEditing(_ textView: TextView) {
            //view.didBegin()
        }
        func textViewDidEndEditing(_ textView: TextView) {
            //view.didEnd()
        }
        #endif

        func highlight(_ textView: TextView) {
            guard let language = view.language as? ParsingLanguage else { return }
            do {
                #if os(macOS)
                let text = textView.string
                #elseif os(iOS)
                guard let text = textView.text else { return }
                #endif
                try language.parse(text: text,
                                   theme: view.theme,
                                   fontSet: view.fontSet, result: { result, string in
                                    DispatchQueue.main.async(qos: .userInteractive) {
                                        #if os(macOS)
                                        textView.textStorage?.setAttributedString(string)
                                        #elseif os(iOS)
                                        textView.textStorage.setAttributedString(string)
                                        #endif
                                    }
                                   }
                )
            }
            catch {
                debugPrint(error.localizedDescription)
            }
        }
        func updateAttributes(_ textView: TextView) {
            #if os(macOS)
            textView.insertionPointColor = view.theme.foreground
            //textView.selectedTextRange = context.coordinator.selection
            //        let layoutDirection = UIView.userInterfaceLayoutDirection(for: textView.semanticContentAttribute)
            //        textView.textAlignment = NSTextAlignment(textAlignment: textAlignment, userInterfaceLayoutDirection: layoutDirection)
            #elseif os(iOS)
            textView.tintColor = view.theme.foreground
            #endif
            textView.backgroundColor = .clear
        }
    }
}
