//
//  Parser.swift
//  Kaleidoscope-Swift-CH2
//
//  Created by Yu Liu on 2024-03-31.
//

import Foundation

@discardableResult
func getNextToken() -> Int {
    CurTok = gettok()
    print("❇️❇️❇️CurTok:", CurTok, IdentifierStr)
    return CurTok
}

func getTokPrecedence() -> Int {
    guard let scalar = UnicodeScalar(CurTok)
    else {
        return -1
    }
    guard let tokPrec = BinopPrecedence[Character(scalar)] else {
        return -1
    }
    return tokPrec
}


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

func parseNumberExpr() -> ExprAST {
    let result = NumberExprAST(NumVal)
    getNextToken()  //  consume the number
    return result
}

/// parenexpr ::= '(' expression ')'
func parseParenExpr() -> ExprAST? {
    print("0️⃣0️⃣0️⃣", #function)
    getNextToken()  //  eat (.
    guard let v = parseExpression() else { return nil }
    
    if CurTok != Int(Character(")").asciiValue!) {
        return LogError( "expected ')'")
    }
    getNextToken()
    return v
}

/// identifierexpr
///   ::= identifier
///   ::= identifier '(' expression* ')'
func parseIdentifierExpr() -> ExprAST? {
    let idName = IdentifierStr
    
    getNextToken()
    
    if CurTok != Character("(").asciiValue! {
        return VariableExprAST(name: idName)
    }
    // Call.
    getNextToken() // eat (
    var Args: [ExprAST] = []
    if CurTok != Int(Character(")").asciiValue!){
        while true {
            if let Arg = parseExpression() {
                Args.append(Arg)
            } else {
                return nil
            }
            
            if CurTok == Int(Character(")").asciiValue!) {
                break
            }
            
            if CurTok != Int(Character(",").asciiValue!) {
                return LogError("Expected ')' or ',' in argument list")
            }
            getNextToken()
            
        }
    }
    
    // Eat the ')'.
    getNextToken()
    
    return CallExprAST(callee: idName, Args: Args)
}

/// primary
///   ::= identifierexpr
///   ::= numberexpr
///   ::= parenexpr
func parsePrimary() -> ExprAST? {
//    print(#function, CurTok)
    switch CurTok {
    case Token.identifier.rawValue:
        return parseIdentifierExpr()
    case Token.number.rawValue:
        return parseNumberExpr()
    case Character("(").intValue():
        return parseParenExpr()
    default:
        return LogError("unknown token when expecting an expression")
    }
}

/// binoprhs
///   ::= ('+' primary)*
func parseBinOpRHS(exprPrec: Int, LHS: inout ExprAST) -> ExprAST? {
    while true {
        let tokPrec = getTokPrecedence()
        
        if tokPrec < exprPrec {
            return LHS
        }
        
        let binOp = CurTok
        getNextToken()
        
        var rhs = parsePrimary()
        guard rhs != nil else {
            return nil
        }
        
        let nextPrec = getTokPrecedence()
        if tokPrec < nextPrec {
            rhs = parseBinOpRHS(exprPrec: tokPrec + 1, LHS: &rhs!)
            guard rhs != nil else {
                return nil
            }
        }
        
        LHS = BinaryExprAST(op: Character(UnicodeScalar(binOp)!), LHS: LHS, RHS: rhs!)
    }
}

/// expression
///  ::= primary binoprhs
///
func parseExpression() -> ExprAST? {
    guard var lhs = parsePrimary() else { return nil }
    return parseBinOpRHS(exprPrec: 0, LHS: &lhs)
}

func parsePrototype() -> PrototypeExprAST? {
//    print("💙", #function, CurTok)
    if CurTok != Token.identifier.rawValue {
        return LogErrorP("Expected function name in prototype")
    }
    
    let fnName = IdentifierStr
    getNextToken()
    
    if CurTok != Character("(").intValue() {
        return LogErrorP("Expected '(' in prototype")
    }
    
    var argNames: [String] = []
    while getNextToken() == Token.identifier.rawValue {
        argNames.append(IdentifierStr)
    }
    if CurTok != Int(Character(")").asciiValue!) {
        return LogErrorP("Expected ')' in prototype")
    }
    
    getNextToken()
    
    return PrototypeExprAST(name: fnName, Args: argNames)
}

func parseDefinition() -> FunctionAST? {
    getNextToken()  //  eat def.
    guard let proto = parsePrototype() else { return nil }
    if let e = parseExpression() {
        return FunctionAST(proto: proto, body: e)
    }
    return nil
}

func parseTopLevelExpr() -> FunctionAST? {
    if let e = parseExpression() {
        let proto = PrototypeExprAST(name: "__anon_expr", Args: [String]())
//        let proto = PrototypeExprAST(name: "", Args: [String]())
        return FunctionAST(proto: proto, body: e)
    }
    return nil
}

func parseExtern() -> PrototypeExprAST? {
    getNextToken()
    return parsePrototype()
}

