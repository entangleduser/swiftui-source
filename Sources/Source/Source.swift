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
            //            #if os(macOS)
            //            textView.delegate?.textDidChange?(
            //                Notification(
            //                    name: .NSManagedObjectContextObjectsDidChange,
            //                    object: textView,
            //                    userInfo: nil)
            //            )
            //            #elseif os(iOS)
            //            textView.delegate?.textViewDidChange?(textView)
            //            #endif
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
        DispatchQueue.main.async { [self] in
            theme =
                scheme == .dark ?
                themeSet.dark :
                themeSet.light
            //            print(colorScheme, scheme)
            //            print(theme.scheme, themeSet.light.scheme)
            textView.updateTheme()
        }
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
        .background(Color(theme.background))
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
        #if os(macOS)
        textView.baseView.delegate = context.coordinator
        textView.baseView.isEditable = context.coordinator.view.isEditable
        textView.baseView.string = context.coordinator.view.input
        textView.baseView.isRichText = false
        textView.baseView.drawsBackground = false
        textView.baseView.font = fontSet.font
        textView.baseView.textColor = theme.foreground
        context.coordinator.updateAttributes(textView.baseView)
        context.coordinator.highlight(textView.baseView)
        #elseif os(iOS)
        textView.delegate = context.coordinator
        textView.text = context.coordinator.view.input
        textView.isEditable = context.coordinator.view.isEditable
        textView.isScrollEnabled = context.coordinator.view.isScrollEnabled
        textView.contentInset = context.coordinator.view.insets
        textView.contentOffset = context.coordinator.view.offset
        textView.font = fontSet.font
        textView.textColor = theme.foreground
        context.coordinator.updateAttributes(textView)
        context.coordinator.highlight(textView)
        #endif
        return textView
    }

    #if os(macOS)
    typealias NSViewType = NSView
    func makeNSView(context: Context) -> NSView {
        makeView(context: context)
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        
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


// MARK: - Subclass
#if os(macOS)
public class SourceTextView: NSView, ObservableObject {
    weak var delegate: NSTextViewDelegate?

    private lazy var scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = true
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalRuler = false
        scrollView.autoresizingMask = [.width, .height]
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        return scrollView
    }()

    lazy var baseView: TextView = {
        let contentSize = scrollView.contentSize
        let textStorage = NSTextStorage()


        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)


        let textContainer = NSTextContainer(containerSize: scrollView.frame.size)
        textContainer.widthTracksTextView = true
        textContainer.containerSize = NSSize(
            width: contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )

        layoutManager.addTextContainer(textContainer)


        let textView = NSTextView(frame: .zero, textContainer: textContainer)
        textView.autoresizingMask = .width
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize = NSSize(width: 0, height: contentSize.height)

        return textView
    }()

    var text: String = "" {
        didSet {
            baseView.string = text
        }
    }

    var selectedRanges: [NSValue] = [] {
        didSet {
            guard selectedRanges.count > 0 else {
                return
            }
            baseView.selectedRanges = selectedRanges
        }
    }

    init() {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillDraw() {
        super.viewWillDraw()

        setupScrollViewConstraints()
        setupTextView()
    }

    func setupScrollViewConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])
    }

    func setupTextView() {
        scrollView.documentView = baseView
    }
}
#elseif os(iOS)
public class SourceTextView: TextView, ObservableObject {
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if let delegate = (delegate as? _Source.Coordinator) {
            if !delegate.view.input.isEmpty, !text.isEmpty,
               let previous = previousTraitCollection?.userInterfaceStyle,
               previous != traitCollection.userInterfaceStyle {
                DispatchQueue.main.async(qos: .userInteractive) { [self] in
                    delegate.highlight(self)
                }
            }
        }
    }
}
#endif

extension SourceTextView {
    func updateTheme() {
        if let delegate = delegate as? _Source.Coordinator {
            DispatchQueue.main.async(qos: .userInteractive) { [self] in
                #if os(macOS)
                delegate.updateAttributes(self.baseView)
                delegate.highlight(self.baseView)
                #elseif os(iOS)
                delegate.updateAttributes(self)
                delegate.highlight(self)
                #endif
            }
        }
    }

}
