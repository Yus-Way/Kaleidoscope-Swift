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
    case `if` = -6
    case then = -7
    case `else` = -8
    case For = -9
    case `in` = -10
    case binary = -11
    case unary = -12
}

var IdentifierStr: String = ""  // Filled in if tok_identifier
var NumVal: Double = 0.0        // Filled in if tok_number
var LastChar: Character = " "

/// gettok - Return the next token from standard input.
func gettok() -> Int {
    
    // Skip any whitespace.
    while LastChar.isWhitespace {
        LastChar = getChar()
    }
    
    if LastChar.isLetter {  // identifier: [a-zA-Z][a-zA-Z0-9]*
        IdentifierStr = String(LastChar)
        
        while true {
            LastChar = getChar()
            if LastChar.isNumber || LastChar.isLetter {
                IdentifierStr.append(LastChar)
            } else {
                break
            }
        }
                
        switch IdentifierStr {
        case "def":
            return Token.def.rawValue
        case "extern":
            return Token.extern.rawValue
        case "if":
            return Token.if.rawValue
        case "then":
            return Token.then.rawValue
        case "else":
            return Token.else.rawValue
        case "for":
            return Token.For.rawValue
        case "in":
            return Token.in.rawValue
        case "binary":
            return Token.binary.rawValue
        case "unary":
            return Token.unary.rawValue
        default:
            return Token.identifier.rawValue
        }
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
        } while LastChar != eof
        && LastChar != "\n"
        && LastChar != "\r"
        
        if LastChar != eof {
            return gettok()
        }
    }
    
    // Check for end of file.  Don't eat the EOF.
    if LastChar == eof {
        return Token.eof.rawValue
    }
    
    // Otherwise, just return the character as its ascii value.
    let ThisChar = LastChar
    LastChar = getChar()
    return ThisChar.intValue()
}

extension Character {
    func intValue() -> Int {
        let asciiValue = self.asciiValue!
        return Int(asciiValue)
    }
}

extension Int32 {
    func character() -> Character {
        if self == -1 {
            exit(0)
        }
        return Character(Unicode.Scalar(Int(self))!)
    }
}

let eof: Character = "\u{03}"
