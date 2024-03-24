//
//  Parser.swift
//  Kaleidoscope-Swift-CH2
//
//  Created by Yu Liu on 2024-03-31.
//

import Foundation


//===----------------------------------------------------------------------===//
// Parser
//===----------------------------------------------------------------------===//

/// CurTok/getNextToken - Provide a simple token buffer.  CurTok is the current
/// token the parser is looking at.  getNextToken reads another token from the
/// lexer and updates CurTok with its results.
@discardableResult
func getNextToken() -> Int {
    CurTok = gettok()
    return CurTok
}

/// GetTokPrecedence - Get the precedence of the pending binary operator token.
func getTokPrecedence() -> Int {
    guard let scalar = UnicodeScalar(CurTok)
    else {
        return -1
    }
    
    // Make sure it's a declared binop.
    guard let tokPrec = BinopPrecedence[Character(scalar)] else {
        return -1
    }
    return tokPrec
}

/// LogError* - These are little helper functions for error handling.
@discardableResult
func LogError(_  str: String) -> ExprAST? {
    print("❌Error:", str)
    return nil
}

@discardableResult
func LogErrorP(_ str: String) -> PrototypeExprAST? {
    LogError(str)
    return nil
}

/// numberexpr ::= number
func parseNumberExpr() -> ExprAST {
    let result = NumberExprAST(NumVal)
    getNextToken()  //  consume the number
    return result
}

/// parenexpr ::= '(' expression ')'
func parseParenExpr() -> ExprAST? {
    getNextToken()  //  eat (.
    guard let v = parseExpression() else { return nil }
    
    if CurTok != Character(")").intValue() {
        return LogError( "expected ')'")
    }
    getNextToken() // eat ).
    return v
}

/// identifierexpr
///   ::= identifier
///   ::= identifier '(' expression* ')'
func parseIdentifierExpr() -> ExprAST? {
    let idName = IdentifierStr
    
    getNextToken() // eat identifier.
    
    if CurTok != Character("(").intValue() { // Simple variable ref.
        return VariableExprAST(name: idName)
    }
    
    // Call.
    getNextToken() // eat (
    var Args: [ExprAST] = []
    if CurTok != Character(")").intValue() {
        while true {
            if let Arg = parseExpression() {
                Args.append(Arg)
            } else {
                return nil
            }
            
            if CurTok == Character(")").intValue() {
                break
            }
            
            if CurTok != Character(",").intValue() {
                return LogError("Expected ')' or ',' in argument list")
            }
            getNextToken()
            
        }
    }
    
    // Eat the ')'.
    getNextToken()
    
    return CallExprAST(callee: idName, Args: Args)
}

/// ifexpr ::= 'if' expression 'then' expression 'else' expression
func parseIfExpr() -> ExprAST? {
    print("✳️", #function, getNextToken()) // eat the if.
    
    // condition.
    guard let Cond = parseExpression() else { return nil }
    
    if CurTok != Token.then.rawValue {
        return LogError("expected then")
    }
    getNextToken()  // eat the then
    
    guard let Then = parseExpression() else { return nil }
    
    if CurTok != Token.else.rawValue {
        return LogError("expected else")
    }
    
    getNextToken()
    
    guard let Else = parseExpression() else { return nil }
    
    return IfExprAST(Cond: Cond, Then: Then, Else: Else)
}

/// forexpr ::= 'for' identifier '=' expr ',' expr (',' expr)? 'in' expression
func parseForExpr() -> ExprAST? {
    getNextToken() // eat the for.

    if CurTok != Token.identifier.rawValue {
        return LogError("expected identifier after for")
    }
    
    let IdName = IdentifierStr
    getNextToken() // eat identifier.
    
    if CurTok != Int(Character("=").asciiValue!) {
        return LogError("expected '=' after for")
    }
    getNextToken()   // eat '=''.
    
    guard let Start = parseExpression() else { return nil }
    if CurTok != Int(Character(",").asciiValue!) {
        return LogError("expected ',' after for start value")
    }
    getNextToken()
    
    guard let End = parseExpression() else { return nil }
    
    // The step value is optional.
    var Step: ExprAST?
    if CurTok == Int(Character(",").asciiValue!) {
        getNextToken()
        Step = parseExpression()
        if Step == nil {
            return nil
        }
    }
    
    if CurTok != Token.in.rawValue {
        return LogError("expected 'in' after for")
    }
    getNextToken()  // eat 'in'.
    
    guard let Body = parseExpression() else { return nil }
    
    return ForExprAST(varName: IdName, start: Start, end: End, step: Step, body: Body)
}

/// varexpr ::= 'var' identifier ('=' expression)?
// (',' identifier ('=' expression)?)* 'in' expression
func parseVarExpr() -> ExprAST? {
    getNextToken()  //  eat the var.
    
    var VarNames: Array<(String, ExprAST?)> = []
    
    // At least one variable name is required.
    if CurTok != Token.identifier.rawValue {
        return LogError("expected identifier after var")
    }
    
    while true {
        let name = IdentifierStr
        getNextToken()  //  eat identifier.
        
        // Read the optional initializer.
        var Init: ExprAST? = nil
        if CurTok == Int(Character("=").asciiValue!) {
            getNextToken()  //  eat the '='
            
            Init = parseExpression()
            if Init == nil {
                return nil
            }
        }
        
        VarNames.append((name, Init))
        
        // End of var list, exit loop.
        if CurTok != Int(Character(",").asciiValue!) {
            break
        }
        getNextToken()  //  eat the ','.
        
        if CurTok != Token.identifier.rawValue {
            return LogError("expected identifier list after var")
        }
    }
    
    // At this point, we have to have 'in'.
    if CurTok != Token.in.rawValue {
        return LogError("expected 'in' keyword after 'var'")
    }
    getNextToken()  //  eat 'in'.
    
    guard let Body = parseExpression() else { return nil }
    
    return VarExprAST(VarNames: VarNames, body: Body)
}

/// primary
///   ::= identifierexpr
///   ::= numberexpr
///   ::= parenexpr
///   ::= ifexpr
///   ::= forexpr
///   ::= varexpr
func parsePrimary() -> ExprAST? {
    switch CurTok {
    case Token.identifier.rawValue:
        return parseIdentifierExpr()
    case Token.number.rawValue:
        return parseNumberExpr()
    case Character("(").intValue():
        return parseParenExpr()
    case Token.if.rawValue:
        return parseIfExpr()
    case Token.For.rawValue:
        return parseForExpr()
    case Token.Var.rawValue:
        return parseVarExpr()
    default:
        return LogError("unknown token when expecting an expression")
    }
}


/// unary
/// ::= primary
/// ::= '!' unary
func parseUnary() -> ExprAST? {
    // If the current token is not an operator, it must be a primary expr.
    if (UnicodeScalar(CurTok) == nil || !UnicodeScalar(CurTok)!.isASCII)
        || CurTok == Int(Character("(").asciiValue!)
        || CurTok == Int(Character(",").asciiValue!) {
        return parsePrimary()
    }
    
    // If this is a unary operator, read it.
    let opc = CurTok
    getNextToken()
    if let operand = parseUnary() {
        return UnaryExprAST(opcode: Character(UnicodeScalar(opc)!), operand: operand)
    }
    
    return nil
}

/// binoprhs
///   ::= ('+' primary)*
func parseBinOpRHS(exprPrec: Int, LHS: inout ExprAST) -> ExprAST? {
    // If this is a binop, find its precedence.
    while true {
        let tokPrec = getTokPrecedence()
        
        // If this is a binop that binds at least as tightly as the current binop,
        // consume it, otherwise we are done.
        if tokPrec < exprPrec {
            return LHS
        }
        
        // Okay, we know this is a binop.
        let binOp = CurTok
        getNextToken()
        
        // Parse the unary expression after the binary operator.
        var rhs = parseUnary()
        guard rhs != nil else {
            return nil
        }
        
        // If BinOp binds less tightly with RHS than the operator after RHS, let
        // the pending operator take RHS as its LHS.
        let nextPrec = getTokPrecedence()
        if tokPrec < nextPrec {
            rhs = parseBinOpRHS(exprPrec: tokPrec + 1, LHS: &rhs!)
            guard rhs != nil else {
                return nil
            }
        }
        
        // Merge LHS/RHS.
        LHS = BinaryExprAST(op: Character(UnicodeScalar(binOp)!), LHS: LHS, RHS: rhs!)
    }
}

/// expression
/// ::= unary binoprhs
///
func parseExpression() -> ExprAST? {
    guard var lhs = parseUnary() else { return nil }
    return parseBinOpRHS(exprPrec: 0, LHS: &lhs)
}

/// prototype
/// ::= id '(' id* ')'
/// ::= binary LETTER number? (id, id)
/// ::= unary LETTER (id)
func parsePrototype() -> PrototypeExprAST? {
    var fnName: String = ""
    
    var kind: UInt = 0    // 0 = identifier, 1 = unary, 2 = binary.
    var binaryPrecendence: UInt = 30
    
    switch CurTok {
    case Token.identifier.rawValue:
        fnName = IdentifierStr
        kind = 0
        getNextToken()
        
    case Token.unary.rawValue:
        getNextToken()
        if !UnicodeScalar(CurTok)!.isASCII {
            return LogErrorP("Expected unary operator")
        }
        fnName = "unary"
        fnName .append(String(UnicodeScalar(UInt8(CurTok))))
        kind = 1
        getNextToken()
        
    case Token.binary.rawValue:
        getNextToken()
        if !UnicodeScalar(CurTok)!.isASCII {
            return LogErrorP("Expected binary operator")
        }
        fnName = "binary"
        fnName.append(String(UnicodeScalar(UInt8(CurTok))))
        kind = 2
        getNextToken()
        
        // Read the precedence if present.
        if CurTok == Token.number.rawValue {
            if NumVal < 1 || NumVal > 100 {
                return LogErrorP("Invalid precendence: must be 1..100")
            }
            binaryPrecendence = UInt(NumVal)
            getNextToken()
        }
        
    default:
        LogErrorP("Expected function name in prototype")
    }
    
    if CurTok != Character("(").intValue() {
        return LogErrorP("Expected '(' in prototype")
    }
    
    var argNames: [String] = []
    while getNextToken() == Token.identifier.rawValue {
        argNames.append(IdentifierStr)
    }
    if CurTok != Character(")").intValue() {
        return LogErrorP("Expected ')' in prototype")
    }
    
    // success.
    getNextToken() // eat ')'.
    
    // Verify right number of names for operator.
    if kind > 0 && argNames.count != kind {
        return LogErrorP("Invalid number of operands for operator")
    }
    
    return PrototypeExprAST(name: fnName, Args: argNames, isOperator: kind != 0, precedence: binaryPrecendence)
}

/// definition ::= 'def' prototype expression
func parseDefinition() -> FunctionAST? {
    getNextToken()  //  eat def.
    guard let proto = parsePrototype() else { return nil }
    if let e = parseExpression() {
        return FunctionAST(proto: proto, body: e)
    }
    return nil
}

/// toplevelexpr ::= expression
func parseTopLevelExpr() -> FunctionAST? {
    if let e = parseExpression() {
        let proto = PrototypeExprAST(name: "__anon_expr", Args: [String]())
        return FunctionAST(proto: proto, body: e)
    }
    return nil
}

/// external ::= 'extern' prototype
func parseExtern() -> PrototypeExprAST? {
    getNextToken() // eat extern.
    return parsePrototype()
}

