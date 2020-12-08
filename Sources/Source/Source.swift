//
//  File.swift
//  
//
//  Created by neutralradiance on 11/9/20.
//

import SwiftUI
import Combine
import Parser
import Theme

#if os(macOS)
import AppKit
public typealias TextView = NSTextView
public typealias ViewRepresentable = NSViewRepresentable
public typealias TextViewDelegate = NSTextViewDelegate
public typealias NativeEdgeInsets = NSEdgeInsets
#elseif os(iOS)
public typealias TextView = UITextView
public typealias ViewRepresentable = UIViewRepresentable
public typealias TextViewDelegate = UITextViewDelegate
public typealias NativeEdgeInsets = UIEdgeInsets
#endif

@available(iOS 14.0, *)
public struct Source: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var textView: SourceTextView = SourceTextView()
    @Binding var input: String
    @Binding var language: Language
    @Binding var fontSet: FontSet
    @Binding var themeSet: ThemeSet
    @Binding var themeDidChange: Bool
    let isEditable: Bool
    let isScrollEnabled: Bool
    let insets: NativeEdgeInsets
    let offset: CGPoint
    let modify: ((SourceTextView) -> Void)?
    let onChange: (() -> Void)?
    @State var theme: Theme = .styri {
        didSet {
            themeDidChange = true
            themeDidChange = false
        }
    }

    public var body: some View {
        _Source(
            input: $input,
            language: $language,
            fontSet: $fontSet,
            themeSet: $themeSet,
            theme: $theme,
            isEditable: isEditable,
            isScrollEnabled: isScrollEnabled,
            insets: insets,
            offset: offset,
            onChange: onChange
        )
        .onAppear {
            modify?(textView)
            update(for: colorScheme)
            #if os(macOS)
            textView.delegate?.textDidChange?(
                Notification(
                    name: .NSManagedObjectContextObjectsDidChange,
                    object: textView,
                    userInfo: nil)
            )
            #elseif os(iOS)
            textView.delegate?.textViewDidChange?(textView)
            #endif
        }
        .onChange(of: themeDidChange) { didChange in
            guard didChange else { return }
            textView.updateTheme()
            themeDidChange = false
        }
        .onChange(of: colorScheme) { scheme in
            update(for: scheme)
        }
        .environmentObject(textView)
    }
    public init(input: Binding<String>,
                language: Binding<Language>,
                fontSet: Binding<FontSet>,
                themeSet: Binding<ThemeSet>,
                themeDidChange: Binding<Bool>,
                isEditable: Bool = true,
                isScrollEnabled: Bool = true,
                insets: NativeEdgeInsets =
                    NativeEdgeInsets(top: 0,
                                     left: 0,
                                     bottom: 0,
                                     right: 0),
                offset: CGPoint = .zero,
                modify: ((SourceTextView) -> Void)? = nil,
                onChange perform: (() -> Void)? = nil) {
        self.isEditable = isEditable
        self.isScrollEnabled = isScrollEnabled
        self.insets = insets
        self.offset = offset
        self.modify = modify
        self._input = input
        self._language = language
        self._fontSet = fontSet
        self._themeSet = themeSet
        self._themeDidChange = themeDidChange
        self.onChange = perform
    }
    func update(for scheme: ColorScheme) {
        theme =
            scheme == .dark ?
            themeSet.dark : themeSet.light
    }
}
@available(iOS 13.0, *)
public struct __Source: View {
    @ObservedObject var textView: SourceTextView = SourceTextView()
    @Binding var input: String
    @Binding var language: Language
    @Binding var fontSet: FontSet
    @Binding var themeSet: ThemeSet
    @Binding var themeDidChange: Bool
    let isEditable: Bool
    let isScrollEnabled: Bool
    let insets: NativeEdgeInsets
    let offset: CGPoint
    let modify: ((SourceTextView) -> Void)?
    let onChange: (() -> Void)?
    @State var theme: Theme = .styri

    public var body: some View {
        _Source(
            input: $input,
            language: $language,
            fontSet: $fontSet,
            themeSet: $themeSet,
            theme: $theme,
            isEditable: isEditable,
            isScrollEnabled: isScrollEnabled,
            insets: insets,
            offset: offset,
            onChange: onChange
        )
        .onAppear {
            modify?(textView)
            #if os(macOS)
            textView.delegate?.textDidChange?(
                Notification(
                    name: .NSManagedObjectContextObjectsDidChange,
                    object: textView,
                    userInfo: nil)
            )
            #elseif os(iOS)
            textView.delegate?.textViewDidChange?(textView)
            #endif
        }
        .environmentObject(textView)
    }

    public init(input: Binding<String>,
                language: Binding<Language>,
                fontSet: Binding<FontSet>,
                themeSet: Binding<ThemeSet>,
                themeDidChange: Binding<Bool>,
                isEditable: Bool = true,
                isScrollEnabled: Bool = true,
                insets: NativeEdgeInsets =
                    NativeEdgeInsets(top: 0,
                                     left: 0,
                                     bottom: 0,
                                     right: 0),
                offset: CGPoint = .zero,
                modify: ((SourceTextView) -> Void)? = nil,
                onChange perform: (() -> Void)? = nil) {
        self.isEditable = isEditable
        self.isScrollEnabled = isScrollEnabled
        self.insets = insets
        self.offset = offset
        self.modify = modify
        self._input = input
        self._language = language
        self._fontSet = fontSet
        self._themeSet = themeSet
        self._themeDidChange = themeDidChange
        self.onChange = perform
    }
}

// MARK: - UIKitComponent
struct _Source: ViewRepresentable {
    @EnvironmentObject var textView: SourceTextView
    @Binding var input: String
    @Binding var language: Language
    @Binding var fontSet: FontSet
    @Binding var themeSet: ThemeSet
    @Binding var theme: Theme
    let isEditable: Bool
    let isScrollEnabled: Bool
    let insets: NativeEdgeInsets
    let offset: CGPoint
    let onChange: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(view: self)
    }

    func makeView(context: Context) -> SourceTextView {
        textView.delegate = context.coordinator
        textView.isEditable = context.coordinator.view.isEditable
        #if os(macOS)
        textView.string = context.coordinator.view.input
        textView.isRichText = false
        textView.drawsBackground = false
        textView.enclosingScrollView?.automaticallyAdjustsContentInsets = false
        textView.textContainer?.textView?.additionalSafeAreaInsets =
            context.coordinator.view.insets
        textView.textContainer?.textView?.bounds.origin =
            context.coordinator.view.offset
        #elseif os(iOS)
        textView.delegate = context.coordinator
        textView.text = context.coordinator.view.input
        textView.isScrollEnabled = context.coordinator.view.isScrollEnabled
        textView.contentInset = context.coordinator.view.insets
        textView.contentOffset = context.coordinator.view.offset
        #endif
        context.coordinator.updateFont(textView)
        context.coordinator.updateAttributes(textView)
        context.coordinator.highlight(textView)
        return textView
    }

    #if os(macOS)
    typealias NSViewType = SourceTextView
    func makeNSView(context: Context) -> SourceTextView {
        makeView(context: context)
    }

    func updateNSView(_ nsView: SourceTextView, context: Context) {
        context.coordinator.updateAttributes(nsView)
    }
    #elseif os(iOS)
    typealias UIViewType = SourceTextView

    func makeUIView(context: Context) -> SourceTextView {
        makeView(context: context)
    }

    func updateUIView(_ uiView: SourceTextView, context: Context) {
        context.coordinator.updateAttributes(uiView)
    }
    #endif
}



extension _Source {
    class Coordinator: NSObject, TextViewDelegate {
        var view: _Source

        init(view: _Source) {
            self.view = view
        }
        #if os(macOS)
        func textDidChange(_ notification: Notification) {
            guard
                let textView = notification.object as? TextView else { return }
            view.input = textView.string
            view.onChange?()
            highlight(textView)
        }
        func textDidBeginEditing(_ notification: Notification) {
            //            guard
            //                let textView = notification.object as? TextView else { return }
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
            guard let language = view.language as? ParsingLanguage else {
                updateFont(textView)
                //                updateAttributes(textView)
                return
            }
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
        func updateFont(_ textView: TextView) {
            textView.font = view.fontSet.font
            textView.textColor = view.theme.foreground
        }
        func updateAttributes(_ textView: TextView) {
            #if os(macOS)
            textView.insertionPointColor = view.theme.foreground
            #elseif os(iOS)
            textView.tintColor = view.theme.foreground
            #endif
            textView.backgroundColor = view.theme.background
            //textView.selectedTextRange = context.coordinator.selection
            //        let layoutDirection = UIView.userInterfaceLayoutDirection(for: textView.semanticContentAttribute)
            //        textView.textAlignment = NSTextAlignment(textAlignment: textAlignment, userInterfaceLayoutDirection: layoutDirection)
        }
    }
}

// MARK: - Subclass
public class SourceTextView: TextView, ObservableObject {
    #if os(macOS)
    lazy var stringValue = string
    #elseif os(iOS)
    lazy var stringValue = text ?? ""

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if let delegate = (delegate as? _Source.Coordinator) {
            if !delegate.view.input.isEmpty, !stringValue.isEmpty,
               let previous = previousTraitCollection?.userInterfaceStyle,
               previous != traitCollection.userInterfaceStyle {
                DispatchQueue.main.async(qos: .userInteractive) { [self] in
                    delegate.highlight(self)
                }
            }
        }
    }
    #endif
    func updateTheme() {
        if let delegate = delegate as? _Source.Coordinator {
            DispatchQueue.main.async(qos: .userInteractive) { [self] in
                delegate.updateFont(self)
                delegate.updateAttributes(self)
                delegate.highlight(self)
            }
        }
    }
}

