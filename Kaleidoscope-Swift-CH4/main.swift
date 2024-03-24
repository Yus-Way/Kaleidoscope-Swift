//
//  main.swift
//  Kaleidoscope-Swift
//
//  Created by Yu Liu on 2024-03-24.
//

import Foundation


// Set "readFile" to "false" if input from terminal.
//  Otherwise reads "code" in file "K-Codes.swift".
let readFile = true

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
    
    // Make the module, which holds all the code.
    InitializeModule()
    
    // Run the main "interpreter loop" now.
    mainLoop()
    
    print("\n------------✅✅✅✅✅✅-------------\n")
    LLVMDumpModule(TheModule)
    LLVMDisposeModule(TheModule)
}





//===----------------------------------------------------------------------===//
// Top-Level parsing
//===----------------------------------------------------------------------===//

func InitializeModule() {
    TheContext = LLVMContextCreate()
    TheModule = LLVMModuleCreateWithNameInContext("my cool jit", TheContext)
    Builder = LLVMCreateBuilderInContext(TheContext)
}

func HandleDefinition() {
    if let fnAST = parseDefinition() {
        if let fnIR = fnAST.codegen() {
            print("Read function definition:")
            //        fnIR.print(errs())
            LLVMDumpValue(fnIR)
            print()
            
            var RT = LLVMExecutionEngineRef(bitPattern: 1)
            var error: UnsafeMutablePointer<CChar>?
            guard LLVMCreateExecutionEngineForModule(&RT, TheModule, &error) == 0
            else {
                let messege = String(cString: error!)
                LLVMDisposeMessage(error)
                print(messege)
                exit(1)
            }
        }
    } else {
        getNextToken()
    }
}

func HandleExtern() {
    if let protoAST = parseExtern() {
        if let fnIR = protoAST.codegen() {
            print("Read extern: ")
            LLVMDumpValue(fnIR)
            print()
        }
    } else {
        getNextToken()
    }
}

func HandleTopLevelExpression() {
    if let fnAST = parseTopLevelExpr() {
        if let fnIR = fnAST.codegen() {
            
            // Create a ResourceTracker to track JIT'd memory allocated to our
            // anonymous expression -- that way we can free it after executing.
            var RT = LLVMExecutionEngineRef(bitPattern: 1)
//            var TSM = LLVMOrcCreateth  //(TheModule, TheContext)
            var error: UnsafeMutablePointer<CChar>?
            guard LLVMCreateExecutionEngineForModule(&RT, TheModule, &error) == 0
            else {
                let messege = String(cString: error!)
                LLVMDisposeMessage(error)
                print(messege)
                exit(1)
            }
            
            let value = LLVMRunFunction(RT, fnIR, 0, nil)
            let result = LLVMGenericValueToFloat(LLVMDoubleType(), value)
            
            
            print("Read top-level expression:")
            LLVMDumpValue(fnIR)
            print()
            
            print("✅Evaluated to \(result)")
            print()
            
            LLVMDeleteFunction(fnIR)    //  ❇️Because of the this line, TheModule won't print this function's IR.
        }
    } else {
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
