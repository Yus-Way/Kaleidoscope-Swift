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
var NumVal: Double = 0.0        // Filled in if tok_number

var source: [Character] = []
var index: Int = -1

/// gettok - Return the next token from standard input.
func gettok() -> Int {
    var LastChar: Character = " "
    
    // Skip any whitespace.
    while LastChar.isWhitespace {
        LastChar = getChar()
    }
    
    if LastChar.isLetter {
        IdentifierStr = String(LastChar)
        
        while true {
            LastChar = getChar()
            if LastChar.isNumber || LastChar.isLetter { // identifier: [a-zA-Z][a-zA-Z0-9]*
                IdentifierStr.append(LastChar)
            } else {
                break
            }
        }
        
        if IdentifierStr == "def" {
            return Token.def.rawValue
        }
        if IdentifierStr == "extern" {
            return Token.extern.rawValue
        }
        return Token.identifier.rawValue
    }
    
    if LastChar.isNumber || LastChar == "." {   // Number: [0-9.]+
        var NumStr: String = ""
        repeat {
            NumStr.append(LastChar)
            LastChar = getChar()
        } while LastChar.isNumber || LastChar == "."
        
        NumVal = Double(NumStr)!
        return Token.number.rawValue
    }
    
    if LastChar == "#" {
        // Comment until end of line.
        repeat {
            LastChar = getChar()
        } while LastChar != "\0"
        && LastChar != "\n"
        && LastChar != "\r"
        
        if LastChar != "\0" {
            return gettok()
        }
    }
    
    // Check for end of file.  Don't eat the EOF.
    if LastChar == "\0" {
        return Token.eof.rawValue
    }
    
    // Otherwise, just return the character as its ascii value.
    let ThisChar = LastChar
    LastChar = getChar()
    
    return ThisChar.intValue()!
}

func getChar() -> Character {
    index += 1
    guard index < source.count else { return "\0"}
    let char = source[index]
    return char
}

extension Character {
    func intValue() -> Int? {
        guard let asciiValue = self.asciiValue else { return nil }
        return Int(asciiValue)
    }
}
