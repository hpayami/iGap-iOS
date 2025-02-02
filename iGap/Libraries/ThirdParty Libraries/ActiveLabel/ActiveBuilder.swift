//
//  ActiveBuilder.swift
//  ActiveLabel
//
//  Created by Pol Quintana on 04/09/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation

typealias ActiveFilterPredicate = ((String) -> Bool)

struct ActiveBuilder {

    static func createElements(type: ActiveType, from text: String, range: NSRange, filterPredicate: ActiveFilterPredicate?) -> [ElementTuple] {
        switch type {
        case .bold:
            return createElements(from: text, for: type, range: range, filterPredicate: filterPredicate)
        case .mention, .hashtag, .bot:
            return createElementsIgnoringFirstCharacter(from: text, for: type, range: range, filterPredicate: filterPredicate)
        case .url, .email, .deepLink:
            return createElements(from: text, for: type, range: range, filterPredicate: filterPredicate)
        case .custom:
            return createElements(from: text, for: type, range: range, minLength: 1, filterPredicate: filterPredicate)
        }
    }

    static func createURLElements(from text: String, range: NSRange, maximumLenght: Int?) -> ([ElementTuple], String) {
        let type = ActiveType.url
        var text = text
        let matches = RegexParser.getElements(from: text, with: type.pattern, range: range)
        let nsstring = text as NSString
        var elements: [ElementTuple] = []

        for match in matches where match.range.length > 2 {
            let word = nsstring.substring(with: match.range)
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            guard let maxLenght = maximumLenght, word.count > maxLenght else {
                let range = maximumLenght == nil ? match.range : (text as NSString).range(of: word)
                let element = ActiveElement.create(with: type, text: word)
                elements.append((range, element, type))
                continue
            }

            let trimmedWord = word.trim(to: maxLenght)
            text = text.replacingOccurrences(of: word, with: trimmedWord)

            let newRange = (text as NSString).range(of: trimmedWord)
            let element = ActiveElement.url(original: word, trimmed: trimmedWord)
            elements.append((newRange, element, type))
        }
        return (elements, text)
    }

    private static func createElements(from text: String, for type: ActiveType, range: NSRange, minLength: Int = 2, filterPredicate: ActiveFilterPredicate?) -> [ElementTuple] {
        let matches = RegexParser.getElements(from: text, with: type.pattern, range: range)
        let nsstring = text as NSString
        var elements: [ElementTuple] = []

//        IGGlobal.getTime()
        for match in matches where match.range.length > minLength {
            let word = nsstring.substring(with: match.range).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if filterPredicate?(word) ?? true {
                let element = ActiveElement.create(with: type, text: word)
                if type != .bold && ActiveLabelJsonify.isBold(candidate: word){
                    continue
                }
                elements.append((match.range, element, type))
            }
        }
//        IGGlobal.getTime("My Time ---")
        
//        _ = matches.withUnsafeBufferPointer { buffer -> Int? in
//            for i in stride(from: buffer.startIndex, to: buffer.endIndex, by: 1) {
//
//                let match = buffer[i]
//                if match.range.length > minLength {
//                    let word = nsstring.substring(with: match.range).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//                    if filterPredicate?(word) ?? true {
//                        let element = ActiveElement.create(with: type, text: word)
//                        elements.append((match.range, element, type))
//                    }
//                }
//            }
//            return nil
//        }
        
        return elements
    }

    private static func createElementsIgnoringFirstCharacter(from text: String,
                                                                  for type: ActiveType,
                                                                      range: NSRange,
                                                                      filterPredicate: ActiveFilterPredicate?) -> [ElementTuple] {
        let matches = RegexParser.getElements(from: text, with: type.pattern, range: range)
        let nsstring = text as NSString
        var elements: [ElementTuple] = []
        
        
        

        for match in matches where match.range.length > 2 {
            let range = NSRange(location: match.range.location + 1, length: match.range.length - 1)
            var word = nsstring.substring(with: range)
            if word.hasPrefix("@") {
                word.remove(at: word.startIndex)
            }
            else if word.hasPrefix("#") {
                word.remove(at: word.startIndex)
            }

            if filterPredicate?(word) ?? true {
                let element = ActiveElement.create(with: type, text: word)
                elements.append((match.range, element, type))
            }
        }
        
        
//        _ = matches.withUnsafeBufferPointer { buffer -> Int? in
//            for i in stride(from: buffer.startIndex, to: buffer.endIndex, by: 1) {
//
//                let match = buffer[i]
//                let range = NSRange(location: match.range.location + 1, length: match.range.length - 1)
//                var word = nsstring.substring(with: range)
//                if word.hasPrefix("@") {
//                    word.remove(at: word.startIndex)
//                }
//                else if word.hasPrefix("#") {
//                    word.remove(at: word.startIndex)
//                }
//
//                if filterPredicate?(word) ?? true {
//                    let element = ActiveElement.create(with: type, text: word)
//                    elements.append((match.range, element, type))
//                }
//            }
//            return nil
//        }
        
        
        
        
        
        return elements
    }
}
