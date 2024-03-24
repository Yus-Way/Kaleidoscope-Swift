//
//  AST.swift
//  Kaleidoscope-Swift-CH2
//
//  Created by Yu Liu on 2024-03-26.
//

import Foundation


protocol ExprAST {
    
}

class NumberExprAST: ExprAST {
    let val: Double
    
    init(_ val: Double) {
        self.val = val
    }
}

class VariableExprAST: ExprAST {
    let name: String
    
    init(name: String) {
        self.name = name
    }
}

class BinaryExprAST: ExprAST {
    let op: Character
    let LHS, RHS: ExprAST
    
    init(op: Character, LHS: ExprAST, RHS: ExprAST) {
        self.op = op
        self.LHS = LHS
        self.RHS = RHS
    }
}

class CallExprAST: ExprAST {
    let callee: String
    let Args: [ExprAST]
    
    init(callee: String, Args: [ExprAST]) {
        self.callee = callee
        self.Args = Args
    }
}

class PrototypeExprAST: ExprAST {
    let name: String
    let Args: [String]
    
    init(name: String, Args: [String]) {
        self.name = name
        self.Args = Args
    }
}

class FunctionAST: ExprAST {
    let proto: PrototypeExprAST
    let body: ExprAST
    
    init(proto: PrototypeExprAST, body: ExprAST) {
        self.proto = proto
        self.body = body
    }
}
