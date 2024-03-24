//
//  Lexer.swift
//  Kaleidoscope-Swift-CH1
//
//  Created by Yu Liu on 2024-03-26.
//

import Foundation

// The lexer returns tokens [0-255] if it is an unknown character, otherwise one
// of these for known things.
enum Token: Int {
    case eof = -1
    case def = -2
    case extern = -3
    case identifier = -4
    case number = -5
}

var IdentifierStr: String = ""  // Filled in if tok_identifier
var LastChar: Character = " "
var NumVal: Double = 0.0        // Filled in if tok_number

//var source: [Character] = []
//var index: Int = 0

/// gettok - Return the next token from standard input.
//func gettok1() -> Int {
////    IdentifierStr = " " //  ❓❓❓
////    defer { index -= 1}
//    var LastChar: Character = "\u{020}"
////    LastChar = "\u{020}"
//    // Skip any whitespace.
//    while LastChar.isWhitespace {
////        print("💙", LastChar)
//        LastChar = Character(String(getchar()))
////        LastChar = Character(UnicodeScalar(getchar()))
//    }
//    
//    if LastChar.isLetter {  // identifier: [a-zA-Z][a-zA-Z0-9]*
//        IdentifierStr = String(LastChar)
//        
////        while true {
////            LastChar = getChar()
////            if LastChar.isNumber || LastChar.isLetter {
////                IdentifierStr.append(LastChar)
////            } else {
////                index -= 1
////                break
////            }
////        }
//        
//        
//        LastChar = getChar()
//        while LastChar.isNumber || LastChar.isLetter {
//            IdentifierStr.append(LastChar)
//            LastChar = getChar()
//        }
//        index -= 1
//
////        print("❇️IdentifierStr", IdentifierStr, LastChar)
//        if IdentifierStr == "def" {
////            print("def")
//            return Token.def.rawValue
//        }
//        if IdentifierStr == "extern" {
//            return Token.extern.rawValue
//        }
////        print("Identifier", IdentifierStr)
//        return Token.identifier.rawValue
//    }
//    
//    if LastChar.isNumber || LastChar == "." {   // Number: [0-9.]+
//        var NumStr: String = ""
//        repeat {
//            NumStr.append(LastChar)
//            LastChar = getChar()
//        } while LastChar.isNumber || LastChar == "."
//        index -= 1
//        
//        NumVal = Double(NumStr)!
//        return Token.number.rawValue
//    }
//    
//    if LastChar == "#" {
//        // Comment until end of line.
//        repeat {
//            LastChar = getChar()
//        } while LastChar != eof
//        && LastChar != "\n"
//        && LastChar != "\r"
//        
//        if LastChar != eof {
//            return gettok()
//        }
//    }
//    
//    // Check for end of file.  Don't eat the EOF.
//    if LastChar == eof {
////        print("Token.eof")
//        return Token.eof.rawValue
//    }
//    
//    // Otherwise, just return the character as its ascii value.
//    let ThisChar = LastChar
//    
////    print("💙This char", ThisChar)
//    return ThisChar.intValue()!
//}

/// gettok - Return the next token from standard input.
func gettok() -> Int {
//    IdentifierStr = " " //  ❓❓❓
//    defer { index -= 1}
//    var LastChar: Character = "\u{020}"
//    LastChar = "\u{020}"
    // Skip any whitespace.
    while LastChar.isWhitespace {
//        print("💙", LastChar)
//        let scalar = Unicode.Scalar(Int(getchar()))
        LastChar = Character(Unicode.Scalar(Int(getchar()))!)
    }
    
    if LastChar.isLetter {  // identifier: [a-zA-Z][a-zA-Z0-9]*
        IdentifierStr = String(LastChar)
        
        while true {
            LastChar = Character(Unicode.Scalar(Int(getchar()))!)
            if LastChar.isNumber || LastChar.isLetter {
                IdentifierStr.append(LastChar)
            } else {
//                index -= 1
                break
            }
        }
        
        
//        LastChar = Character(Unicode.Scalar(Int(getchar()))!)
//        while LastChar.isNumber || LastChar.isLetter {
//            IdentifierStr.append(LastChar)
//            LastChar = Character(Unicode.Scalar(Int(getchar()))!)
//        }
//        index -= 1

//        print("❇️IdentifierStr", IdentifierStr, LastChar)
        if IdentifierStr == "def" {
//            print("def")
            return Token.def.rawValue
        }
        if IdentifierStr == "extern" {
            return Token.extern.rawValue
        }
//        print("Identifier", IdentifierStr)
        return Token.identifier.rawValue
    }
    
    if LastChar.isNumber || LastChar == "." {   // Number: [0-9.]+
        var NumStr: String = ""
        repeat {
            NumStr.append(LastChar)
            LastChar = Character(Unicode.Scalar(Int(getchar()))!)
        } while LastChar.isNumber || LastChar == "."
//        index -= 1
        
        NumVal = Double(NumStr)!
        return Token.number.rawValue
    }
    
    if LastChar == "#" {
        // Comment until end of line.
        repeat {
            LastChar = Character(Unicode.Scalar(Int(getchar()))!)
        } while LastChar != eof
        && LastChar != "\n"
        && LastChar != "\r"
        
        if LastChar != eof {
            return Int(getchar())
        }
    }
    
    // Check for end of file.  Don't eat the EOF.
    if LastChar == eof {
//        print("Token.eof")
        return Token.eof.rawValue
    }
    
    // Otherwise, just return the character as its ascii value.
    let ThisChar = LastChar
    
//    print("💙This char", ThisChar)
    return ThisChar.intValue()!
}


//func getChar() -> Character {
////    print(source)
//    guard index < source.count else { return "\n"}
//    let char = source[index]
//    index += 1
////    print(index, char)
//    return char
//}

extension Character {
    func intValue() -> Int? {
        guard let asciiValue = self.asciiValue else { return nil }
        return Int(asciiValue)
    }
}

let eof: Character = "\u{03}"
