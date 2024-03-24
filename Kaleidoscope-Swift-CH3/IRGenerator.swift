//
//  IRGenerator.swift
//  Kaleidoscope-Swift-CH3
//
//  Created by Yu Liu on 2024-04-03.
//

import Foundation

var TheContext: LLVMContextRef = LLVMContextCreate()
var TheModule = LLVMModuleCreateWithNameInContext("my cool jit", TheContext)
var Builder = LLVMCreateBuilderInContext(TheContext)
var NameValues: [String : LLVMValueRef] = [:]


@discardableResult
func LogErrorV(_ str: String) -> LLVMValueRef? {
    LogError(str)
    return nil
}

extension NumberExprAST {
    func codegen() -> LLVMValueRef? {
        let doubleType = LLVMDoubleTypeInContext(TheContext)
        return LLVMConstReal(doubleType, val)
    }
}

extension VariableExprAST {
    // Look this variable up in the function.
    func codegen() -> LLVMValueRef? {
        guard let v = NameValues[name] else {
            LogErrorV("Unknown variable name")
            return nil
        }
        return v
    }
}

extension BinaryExprAST {
    func codegen() -> LLVMValueRef? {
        guard var l = LHS.codegen(), let r = RHS.codegen()
        else { return nil }
        
        switch op {
        case "+":
            return LLVMBuildFAdd(Builder, l, r, "addtmp")
        case "-":
            return LLVMBuildFSub(Builder, l, r, "subtmp")
        case "*":
            return LLVMBuildFMul(Builder, l, r, "multmp")
        case "<":
            l = LLVMBuildFCmp(Builder, LLVMRealULT, l, r, "cmptmp")
            // Convert bool 0/1 to double 0.0 or 1.0
            return LLVMBuildUIToFP(Builder, l, LLVMDoubleTypeInContext(TheContext), "booltmp")
        default:
            return LogErrorV("invalid binary operator")
        }
    }
}

extension CallExprAST {
    func codegen() -> LLVMValueRef? {
        // Look up the name in the global module table.
        guard let calleeF = LLVMGetNamedFunction(TheModule, callee)
        else {
            return LogErrorV("Unknown function referenced")
        }
        
        // If argument mismatch error.
        if LLVMCountParams(calleeF) != Args.count {
            return LogErrorV("Incorrect # arguments passed")
        }
        
        var argsV: [LLVMValueRef?] = []
        for i in 0..<Args.count {
            if let argV = Args[i].codegen() {
                argsV.append(argV)
            } else {
                return nil
            }
        }
        
        let functionType = LLVMGlobalGetValueType(calleeF)
        return LLVMBuildCall2(Builder, functionType, calleeF, &argsV, UInt32(Args.count), "calltmp")
    }
}

extension PrototypeExprAST {    
    func getName() -> String {
        name
    }
    
    // Make the function type:  double(double,double) etc.
    func codegen() -> LLVMValueRef? {
        let doubleType = LLVMDoubleTypeInContext(TheContext)
        var Doubles = [LLVMTypeRef?](repeating: doubleType, count: Args.count)
        let ft = LLVMFunctionType(doubleType, &Doubles, UInt32(Doubles.count), LLVMBool(0))
        
        let function = LLVMAddFunction(TheModule, name, ft)
        
        // Set names for all arguments.
        for (index, arg) in Args.enumerated() {
            let param = LLVMGetParam(function, UInt32(index))
            LLVMSetValueName(param, arg)
        }
        
        return function
    }
}

extension FunctionAST {
    func codegen() -> LLVMValueRef? {
        // First, check for an existing function from a previous 'extern' declaration.
        var theFunction = LLVMGetNamedFunction(TheModule, proto.getName())

        if theFunction == nil {
            theFunction = proto.codegen()
        }
        
        if theFunction == nil {
            return nil
        }

        /*
         if (!TheFunction->empty())
             return (Function*)LogErrorV("Function cannot be redefined.");
         */
        
        // Create a new basic block to start insertion into.
        let bb = LLVMAppendBasicBlockInContext(TheContext, theFunction, "entry")
        LLVMPositionBuilderAtEnd(Builder, bb)

        // Record the function arguments in the NamedValues map.
        NameValues.removeAll()
        
        // Record the function arguments in the NamedValues map.
        let count = LLVMCountParams(theFunction)
        for index in 0..<count {
            let parameter = LLVMGetParam(theFunction, UInt32(index))
            var nameLength = 0
            let name = String(cString: LLVMGetValueName2(parameter, &nameLength))
            NameValues[name] = parameter
        }

        if let retVal = body.codegen() {
            // Finish off the function.
            LLVMBuildRet(Builder, retVal)
            
            // Validate the generated code, checking for consistency.
            if LLVMVerifyFunction(theFunction, LLVMPrintMessageAction) == 1 {
                print("Invalid function")
                LLVMDeleteFunction(theFunction)
            }
            
            return theFunction
        }
        
        // Error reading body, remove function.
        LLVMDeleteFunction(theFunction) //  ❇️Because of the this line, TheModule won't print this function.
        return nil
    }
}
