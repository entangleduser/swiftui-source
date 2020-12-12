//
//  SwiftUIView.swift
//  
//
//  Created by neutralradiance on 12/3/20.
//

import SwiftUI
import Parser
import Theme

#if os(macOS)
typealias SourceLabel = NSTextField
#elseif os(iOS)
typealias SourceLabel = UILabel
#endif

public struct SourceText: View {
    public let input: String
    public var scale: CGFloat
    public var lineLimit: Int
    public var shouldHighlight: Bool
    @ObservedObject var label: SourceLabel = SourceLabel()
    @Binding var language: Language
    @Binding var fontSet: FontSet
    @Binding var theme: Theme
    
    public var body: some View {
        _SourceText(input: input,
                    scale: scale,
                    lineLimit: lineLimit,
                    shouldHighlight: shouldHighlight,
                    language: $language,
                    fontSet: $fontSet,
                    theme: $theme)
            .environmentObject(label)
    }
    public init(input: String,
                scale: CGFloat = 1.0,
                lineLimit: Int = 4,
                shouldHighlight: Bool = false,
                language: Binding<Language>,
                fontSet: Binding<FontSet>,
                theme: Binding<Theme>) {
        self._language = language
        self._fontSet = fontSet
        self._theme = theme
        self.input = input
        self.scale = scale
        self.lineLimit = lineLimit
        self.shouldHighlight = shouldHighlight
    }
}

// MARK: - UIKitComponent
struct _SourceText: ViewRepresentable {
    let input: String
    let scale: CGFloat
    let lineLimit: Int
    let shouldHighlight: Bool
    @EnvironmentObject var label: SourceLabel
    @Binding var language: Language
    @Binding var fontSet: FontSet
    @Binding var theme: Theme

    func makeView(context: Context) -> SourceLabel {
        fontSet.size = fontSet.size*Float(scale)
        #if os(macOS)
        label.maximumNumberOfLines = lineLimit
        label.stringValue = input
        #elseif os(iOS)
        label.text = input
        #endif
        label.lineBreakMode = .byWordWrapping
        label.font = fontSet.font
        label.textColor = theme.foreground
        highlight(label)
        return label
    }

    #if os(macOS)
    typealias NSViewType = SourceLabel
    func makeNSView(context: Context) -> SourceLabel {
        makeView(context: context)
    }

    func updateNSView(_ nsView: SourceLabel, context: Context) {
        updateAttributes(nsView)
    }
    #elseif os(iOS)
    typealias UIViewType = SourceLabel

    func makeUIView(context: Context) -> SourceLabel {
        makeView(context: context)
    }

    func updateUIView(_ uiView: SourceLabel, context: Context) {
        updateAttributes(uiView)
    }
    #endif
}

extension _SourceText {
    func highlight(_ label: SourceLabel) {
        updateAttributes(label)
        guard shouldHighlight,
        let language = language as? ParsingLanguage else { return }
        do {
            #if os(macOS)
            let text = label.stringValue
            #elseif os(iOS)
            guard let text = label.text else { return }
            #endif
            try language.parse(
                text: text,
                theme: theme,
                fontSet: fontSet, result: { result, string in
                    DispatchQueue.main.async(qos: .userInteractive) {
                        #if os(macOS)
                        label.attributedStringValue = string
                        #elseif os(iOS)
                        label.attributedText = string
                        #endif
                    }
                }
            )
        }
        catch {
            debugPrint(error.localizedDescription)
        }
    }
    func updateAttributes(_ label: SourceLabel) {
        #if os(macOS)
        #elseif os(iOS)
        #endif
        label.backgroundColor = .clear
    }
}

// MARK: Subclass
extension SourceLabel: ObservableObject {}
