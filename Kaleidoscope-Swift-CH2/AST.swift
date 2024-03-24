//
//  AST.swift
//  Kaleidoscope-Swift-CH2
//
//  Created by Yu Liu on 2024-03-26.
//

import Foundation

//===----------------------------------------------------------------------===//
// Abstract Syntax Tree (aka Parse Tree)
//===----------------------------------------------------------------------===//


/// ExprAST - Base class for all expression nodes.
protocol ExprAST { }

/// NumberExprAST - Expression class for numeric literals like "1.0".
class NumberExprAST: ExprAST {
    let val: Double
    
    init(_ val: Double) {
        self.val = val
    }
}

/// VariableExprAST - Expression class for referencing a variable, like "a".
class VariableExprAST: ExprAST {
    let name: String
    
    init(name: String) {
        self.name = name
    }
}

/// BinaryExprAST - Expression class for a binary operator.
class BinaryExprAST: ExprAST {
    let op: Character
    let LHS, RHS: ExprAST
    
    init(op: Character, LHS: ExprAST, RHS: ExprAST) {
        self.op = op
        self.LHS = LHS
        self.RHS = RHS
    }
}

/// CallExprAST - Expression class for function calls.
class CallExprAST: ExprAST {
    let callee: String
    let Args: [ExprAST]
    
    init(callee: String, Args: [ExprAST]) {
        self.callee = callee
        self.Args = Args
    }
}

/// PrototypeAST - This class represents the "prototype" for a function,
/// which captures its name, and its argument names (thus implicitly the number
/// of arguments the function takes).
class PrototypeExprAST: ExprAST {
    let name: String
    let Args: [String]
    
    init(name: String, Args: [String]) {
        self.name = name
        self.Args = Args
    }
}

/// FunctionAST - This class represents a function definition itself.
class FunctionAST: ExprAST {
    let proto: PrototypeExprAST
    let body: ExprAST
    
    init(proto: PrototypeExprAST, body: ExprAST) {
        self.proto = proto
        self.body = body
    }
}
