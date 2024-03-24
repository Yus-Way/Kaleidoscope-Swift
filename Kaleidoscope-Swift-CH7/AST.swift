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
protocol ExprAST {
    func codegen() -> LLVMValueRef?
}

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

/// UnaryExprAST - Expression class for a unary operator.
class UnaryExprAST: ExprAST {
    let opcode: Character
    let operand: ExprAST
    
    init(opcode: Character, operand: ExprAST) {
        self.opcode = opcode
        self.operand = operand
    }
}


/// IfExprAST - Expression class for if/then/else.
class IfExprAST: ExprAST {
    let Cond, Then, Else: ExprAST
    
    init(Cond: ExprAST, Then: ExprAST, Else: ExprAST) {
        self.Cond = Cond
        self.Then = Then
        self.Else = Else
    }
}

/// ForExprAST - Expression class for for/in.
class ForExprAST: ExprAST {
    let varName: String
    let start, end, body: ExprAST
    let step: ExprAST?
    
    init(varName: String, start: ExprAST, end: ExprAST, step: ExprAST?, body: ExprAST) {
        self.varName = varName
        self.start = start
        self.end = end
        self.step = step
        self.body = body
    }
}

/// VarExprAST - Expression class for var/in
class VarExprAST: ExprAST {
    let VarNames: [(String, ExprAST?)]
    let body: ExprAST
    
    init(VarNames: [(String, ExprAST?)], body: ExprAST) {
        self.VarNames = VarNames
        self.body = body
    }
}

/// PrototypeAST - This class represents the "prototype" for a function,
/// which captures its name, and its argument names (thus implicitly the number
/// of arguments the function takes), as well as if it is an operator.
class PrototypeExprAST: ExprAST {
    let name: String
    let Args: [String]
    let isOperator: Bool
    let precedence: UInt    //  Precedence if a binary op.
    
    init(name: String, Args: [String], isOperator: Bool = false, precedence: UInt = 0) {
        self.name = name
        self.Args = Args
        self.isOperator = isOperator
        self.precedence = precedence
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
