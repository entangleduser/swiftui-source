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

public class SourceTextView: TextView, ObservableObject {
    #if os(macOS)
    lazy var stringValue = string
    #elseif os(iOS)
    lazy var stringValue = text ?? ""
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if let delegate = (delegate as? _Source.Coordinator),
              !delegate.view.input.isEmpty, !stringValue.isEmpty,
              let previous = previousTraitCollection,
              previous.hasDifferentColorAppearance(comparedTo: traitCollection) {
        themeDidChange = true
        DispatchQueue.main.async(qos: .userInteractive) {
            delegate.highlight(self)
        }
    }
        themeDidChange = false
    }
    #endif
    @Published var themeDidChange: Bool = false {
        willSet {
            if newValue,
                  let delegate = delegate as? _Source.Coordinator,
                  !delegate.view.input.isEmpty, !stringValue.isEmpty {
            DispatchQueue.main.async(qos: .userInteractive) {
                delegate.highlight(self)
            }
            }
        }
    }
}

//struct SourceInputKey: FocusedValueKey {
//    typealias Value = Binding<String>
//}
//
//extension FocusedValues {
//    var sourceInput: Binding<String>? {
//        get { self[SourceInputKey.self] }
//        set { self[SourceInputKey.self] = newValue }
//    }
//}
struct SourceInputKey: EnvironmentKey {
    static var defaultValue: Binding<String> { .constant("") }
}

extension EnvironmentValues {
    var sourceInput: Binding<String> {
        get { self[SourceInputKey.self] }
        set { self[SourceInputKey.self] = newValue }
    }
}

@available(iOS 14.0, *)
public struct Source: View {
    @StateObject var textView: SourceTextView = SourceTextView()
    @Binding var input: String
    @Binding var language: ParsingLanguage
    @Binding var fontSet: FontSet
    @Binding var theme: Theme
    @Binding var themeDidChange: Bool
    let insets: NativeEdgeInsets
    let offset: CGPoint
    let isEditable: Bool
    let isScrollEnabled: Bool
    let modify: ((SourceTextView) -> Void)?

    public var body: some View {
        _Source(
            input: $input,
            language: $language,
            fontSet: $fontSet,
            theme: $theme
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
        .onChange(of: themeDidChange) { didChange in
            guard didChange else { return }
            textView.themeDidChange = didChange
            themeDidChange = false
        }
    }
    public init(input: Binding<String>,
                language: Binding<ParsingLanguage>,
                fontSet: Binding<FontSet>,
                //                themeSet: Binding<ThemeSet>,
                theme: Binding<Theme>,
                themeDidChange: Binding<Bool>,
                isEditable: Bool = true,
                isScrollEnabled: Bool = true,
                insets: NativeEdgeInsets =
                    NativeEdgeInsets(top: 0,
                                     left: 4.5,
                                     bottom: 0,
                                     right: 4.5),
                offset: CGPoint = .zero,
                modify: ((SourceTextView) -> Void)? = nil) {
        self.isEditable = isEditable
        self.isScrollEnabled = isScrollEnabled
        self.insets = insets
        self.offset = offset
        self.modify = modify
        self._input = input
        self._language = language
        self._fontSet = fontSet
        self._theme = theme
        self._themeDidChange = themeDidChange
        //        self._themeSet = themeSet
    }
}
@available(iOS 13.0, *)
public struct __Source: View {
    @ObservedObject var textView: SourceTextView = SourceTextView()
    @Binding var input: String
    @Binding var language: ParsingLanguage
    @Binding var fontSet: FontSet
    @Binding var theme: Theme
    @Binding var themeDidChange: Bool
    let insets: NativeEdgeInsets
    let offset: CGPoint
    let isEditable: Bool
    let isScrollEnabled: Bool
    let modify: ((SourceTextView) -> Void)?

    public var body: some View {
        _Source(
            input: $input,
            language: $language,
            fontSet: $fontSet,
            theme: $theme
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
                language: Binding<ParsingLanguage>,
                fontSet: Binding<FontSet>,
                //                themeSet: Binding<ThemeSet>,
                theme: Binding<Theme>,
                themeDidChange: Binding<Bool>,
                isEditable: Bool = true,
                isScrollEnabled: Bool = true,
                insets: NativeEdgeInsets =
                    NativeEdgeInsets(top: 0,
                                 left: 4.5,
                                 bottom: 0,
                                 right: 4.5),
                offset: CGPoint = .zero,
                modify: ((SourceTextView) -> Void)? = nil) {
        self.isEditable = isEditable
        self.isScrollEnabled = isScrollEnabled
        self.insets = insets
        self.offset = offset
        self.modify = modify
        self._input = input
        self._language = language
        self._fontSet = fontSet
        self._theme = theme
        self._themeDidChange = themeDidChange
        //        self._themeSet = themeSet
    }
}

struct _Source: ViewRepresentable {
    @EnvironmentObject var textView: SourceTextView
    //    @FocusedBinding(\.sourceInput) public var input: String!
    //    @Binding var input: String
    @Binding var input: String
    @Binding var language: ParsingLanguage
    @Binding var fontSet: FontSet
    //    @Binding var themeSet: ThemeSet
    @Binding var theme: Theme
    
    let isEditable: Bool
    let isScrollEnabled: Bool
    let insets: NativeEdgeInsets
    let offset: CGPoint

    init(input: Binding<String>,
         language: Binding<ParsingLanguage>,
         fontSet: Binding<FontSet>,
         //         themeSet: Binding<ThemeSet>,
         theme: Binding<Theme>,
         isEditable: Bool = true,
         isScrollEnabled: Bool = true,
         insets: NativeEdgeInsets =
            NativeEdgeInsets(top: 0,
                             left: 3.5,
                             bottom: 0,
                             right: 3.5),
         offset: CGPoint = .zero) {
        self.isEditable = isEditable
        self.isScrollEnabled = isScrollEnabled
        self.insets = insets
        self.offset = offset
        self._input = input
        self._language = language
        self._fontSet = fontSet
        //        self._themeSet = themeSet
        self._theme = theme
    }

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
        textView.textColor = theme.foreground

        textView.font = fontSet.font
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
            do {
                #if os(macOS)
                let text = textView.string
                #elseif os(iOS)
                guard let text = textView.text else { return }
                #endif
                try view.language.parse(text: text,
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
//            switch tokens?.parse(text: attributedText,
//                                 range: nil,
//                                 language: view.language,
//                                 theme: view.theme,
//                                 font: view.fontSet.font) {
//                case .success(let value):
//                    DispatchQueue.main.async(qos: .userInteractive) {
//                        #if os(macOS)
//                        textView.textStorage?.setAttributedString(value)
//                        #elseif os(iOS)
//                        textView.textStorage.setAttributedString(value)
//                        #endif
//                    }
//                case .failure(let error):
//                    print(error.errorDescription!)
//                default: break
//            }
        }
        func updateAttributes(_ textView: TextView) {
            #if os(macOS)
            textView.insertionPointColor = view.theme.foreground
            #elseif os(iOS)
            textView.tintColor = view.theme.foreground
            #endif
            textView.backgroundColor = .clear
            //textView.selectedTextRange = context.coordinator.selection
            //        let layoutDirection = UIView.userInterfaceLayoutDirection(for: textView.semanticContentAttribute)
            //        textView.textAlignment = NSTextAlignment(textAlignment: textAlignment, userInterfaceLayoutDirection: layoutDirection)
        }
    }
}
