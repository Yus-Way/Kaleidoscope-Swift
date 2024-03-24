//
//  main.swift
//  Kaleidoscope-Swift
//
//  Created by Yu Liu on 2024-03-24.
//

import Foundation


let readFile = false

var CurTok: Int = -1
var BinopPrecedence: [Character: Int] = ["<": 10, "+": 20, "-": 20, "*": 40]

//print("Hello world!")
//testReadline1()

//source = Array(code)

//startConsole()

getNextToken()
mainLoop()



func mainLoop() {
//    print(#function, CurTok)
    while true {
//        print(source, CurTok)
        print("❇️ready> ", terminator: "")
        switch CurTok {
        case Token.eof.rawValue:
            return
        case Int(UnicodeScalar(";").value):
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
            break
        }
    }
}

func HandleDefinition() {
    if parseDefinition() != nil {
            print("Parsed a function definition.")
    } else {
        getNextToken()
    }
}

func HandleExtern() {
    if parseExtern() != nil {
            print("Parsed an extern")
    } else {
        getNextToken()
    }
}

func HandleTopLevelExpression() {
    if parseTopLevelExpr() != nil {
            print("Parsed a top-level expr")
    } else {
        getNextToken()
    }
}
