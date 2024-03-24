//
//  main.swift
//  Kaleidoscope-Swift
//
//  Created by Yu Liu on 2024-03-24.
//

import Foundation

// Set "readFile" to "false" if input from terminal.
//  Otherwise reads "code" in file "K-Codes.swift".
let readFile = false

var CurTok: Int = -1
var BinopPrecedence: [Character: Int] = [:]

main()

func main() {
    // Install standard binary operators.
    // 1 is lowest precedence.
    BinopPrecedence = [
        "<": 10,
        "+": 20,
        "-": 20,
        "*": 40 // highest.
    ]
    
    // Prime the first token.
    if !readFile {
        print("ready> ", terminator: "")
    }
    getNextToken()
    
    // Run the main "interpreter loop" now.
    mainLoop()
}





//===----------------------------------------------------------------------===//
// Top-Level parsing
//===----------------------------------------------------------------------===//

func HandleDefinition() {
    if parseDefinition() != nil {
        print("Parsed a function definition.")
    } else {
        // Skip token for error recovery.
        getNextToken()
    }
}

func HandleExtern() {
    if parseExtern() != nil {
        print("Parsed an extern")
    } else {
        // Skip token for error recovery.
        getNextToken()
    }
}

func HandleTopLevelExpression() {
    // Evaluate a top-level expression into an anonymous function.
    if parseTopLevelExpr() != nil {
        print("Parsed a top-level expr")
    } else {
        // Skip token for error recovery.
        getNextToken()
    }
}

/// top ::= definition | external | expression | ';'
func mainLoop() {
    while true {
        if !readFile {
            print("❇️ready> ", terminator: "")
        }
        switch CurTok {
        case Token.eof.rawValue:
            return
        case Character(";").intValue(): // ignore top-level semicolons.
            getNextToken()
            break
        case Token.def.rawValue:
            HandleDefinition()
            break
        case Token.extern.rawValue:
            HandleExtern()
            break
        default:
            HandleTopLevelExpression()
        }
    }
}

var index: Int = 0

func getChar() -> Character {
    if readFile {
        guard index < source.count else { return eof }
        let char = source[index]
//        print(index, char)
        index += 1
        return char
    } else {
        return getchar().character()
    }
}
