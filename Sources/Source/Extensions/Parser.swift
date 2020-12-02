//
//  File.swift
//  
//
//  Created by neutralradiance on 12/2/20.
//

import SwiftUI
import Parser
import Theme
import Light

public extension ParsingLanguage {
    func parse(text: String,
               theme: Theme? = nil,
               fontSet: FontSet = .init(),
               result handler: (
                (Result<ParseResult?, ParseError>, NSMutableAttributedString) -> Void)? = nil) throws {
        let font = fontSet.font
        #if os(macOS)
        let defaultForeground: NativeColor = .labelColor
        #elseif os(iOS)
        let defaultForeground: NativeColor = .label
        #endif
        let string = NSMutableAttributedString(
            string: text,
            attributes:
                [.foregroundColor: theme?.foreground ?? defaultForeground,
                 .font: font]
        )
        do {
            handler?(
                try lex(
                    input: text,
                    output: { result in
                        guard !result.ranges.isEmpty else { return }
                        if let context = result.context {
                            var attributes: [NSAttributedString.Key: Any] =
                                [.foregroundColor: (context.color ?? theme?[context.index]) ?? defaultForeground]
                            if let background = context.background ?? theme?[context.bgIndex] {
                                attributes[.backgroundColor] = background
                            }
                            var traits = FontDescriptor.SymbolicTraits()
                            if let contextTraits = context.traits {
                                if contextTraits.contains(.underline) ||
                                    contextTraits.contains(.strikethrough) {
                                    let isStroked = contextTraits.contains(.strikethrough)
                                    attributes[isStroked ? .strikethroughStyle: .underlineStyle] =
                                        NSUnderlineStyle.single.rawValue
                                }
                                if let symbolicTraits = contextTraits.symbolic {
                                    traits = traits.union(symbolicTraits)
                                }
                            }
                            let finalDescriptor = font.fontDescriptor.withSymbolicTraits(traits)
                            #if os(macOS)
                            attributes[.font] =
                                NativeFont(descriptor: finalDescriptor, size: CGFloat(fontSet.size))
                            #elseif os(iOS)
                            if let finalDescriptor = finalDescriptor {
                                attributes[.font] =
                                    NativeFont(descriptor: finalDescriptor, size: CGFloat(fontSet.size))
                            }
                            #endif
                            // check for highlighting context
                            result.ranges.forEach { range in
                                string.addAttributes(attributes, range: range)
                            }
                        }
                    }
                ), string
            )
        }
        catch {
            guard let error = error as? ParseError else { return }
            handler?(.failure(error), string)
        }
    }
}
