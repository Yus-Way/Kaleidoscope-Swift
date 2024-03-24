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


extension UnaryExprAST {
    func codegen() -> LLVMValueRef? {
        var operandV = operand.codegen()
        if operandV == nil {
            return nil
        }
        guard let f = LLVMGetNamedFunction(TheModule, "unary" + String(opcode)) else {
            return LogErrorV("Unkown unary operator")
        }
        
        return LLVMBuildCall2(Builder, LLVMGlobalGetValueType(f), f, &operandV, 1, "unop")
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
            break
        }
        
        // If it wasn't a builtin binary operator, it must be a user defined one. Emit
        // a call to it.
        guard let f = LLVMGetNamedFunction(TheModule, "binary" + String(op)) else {
            print("binary operator not found!")
            return nil
        }
        var Ops: [LLVMValueRef?] = [l, r]
        let type = LLVMGlobalGetValueType(f)
        return LLVMBuildCall2(Builder, type, f, &Ops, 2, "binop")
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

extension IfExprAST {
    func codegen() -> LLVMValueRef? {
        guard var CondV = Cond.codegen() else { return nil }
        
        // Convert condition to a bool by comparing non-equal to 0.0.
        CondV = LLVMBuildFCmp(Builder, LLVMRealONE, CondV, LLVMConstReal(LLVMDoubleTypeInContext(TheContext), 0.0), "ifcond")
        
        let theFunction = LLVMGetBasicBlockParent(LLVMGetInsertBlock(Builder))
        
        // Create blocks for the then and else cases.  Insert the 'then' block at the
        // end of the function.
        var ThenBB = LLVMAppendBasicBlockInContext(TheContext, theFunction, "then") // ✅
        var ElseBB = LLVMAppendBasicBlockInContext(TheContext, theFunction, "else")
        let MergeBB = LLVMAppendBasicBlockInContext(TheContext, theFunction, "ifcont")

        LLVMBuildCondBr(Builder, CondV, ThenBB, ElseBB)
        
        // Emit then value.
        LLVMPositionBuilderAtEnd(Builder, ThenBB)    // ❓❓❓
        
        var ThenV = Then.codegen()
        if ThenV == nil { return nil }
        
        LLVMBuildBr(Builder, MergeBB)
        // Codegen of 'Then' can change the current block, update ThenBB for the PHI.
        ThenBB = LLVMGetInsertBlock(Builder)
        
        // Emit else block.
        LLVMPositionBuilderAtEnd(Builder, ElseBB)    // ❓❓❓
        
        var ElseV = Else.codegen()
        if ElseV == nil { return nil }
        
        LLVMBuildBr(Builder, MergeBB)
        // Codegen of 'Else' can change the current block, update ElseBB for the PHI.
        ElseBB = LLVMGetInsertBlock(Builder)
        
        // Emit merge block.
        LLVMPositionBuilderAtEnd(Builder, MergeBB)    // ❓❓❓
        
        let PN = LLVMBuildPhi(Builder, LLVMDoubleTypeInContext(TheContext), "iftmp")
        
        LLVMAddIncoming(PN, &ThenV, &ThenBB, 1)
        LLVMAddIncoming(PN, &ElseV, &ElseBB, 1)
        
        return PN
    }
}


// Output for-loop as:
//   ...
//   start = startexpr
//   goto loop
// loop:
//   variable = phi [start, loopheader], [nextvariable, loopend]
//   ...
//   bodyexpr
//   ...
// loopend:
//   step = stepexpr
//   nextvariable = variable + step
//   endcond = endexpr
//   br endcond, loop, endloop
// outloop:
extension ForExprAST {
    func codegen() -> LLVMValueRef? {
        // Emit the start code first, without 'variable' in scope.
        var StartVal = start.codegen()
        if StartVal == nil { return nil }
        
        // Make the new basic block for the loop header, inserting after current
        // block.
        let theFunction = LLVMGetBasicBlockParent(LLVMGetInsertBlock(Builder))
        var PreheaderBB = LLVMGetInsertBlock(Builder)
        let LoopBB = LLVMAppendBasicBlockInContext(TheContext, theFunction, "loop")
        
        // Insert an explicit fall through from the current block to the LoopBB.
        LLVMBuildBr(Builder, LoopBB)
        
        // Start insertion in LoopBB.
        LLVMPositionBuilderAtEnd(Builder, LoopBB)
        
        // Start the PHI node with an entry for Start.
        let Variable = LLVMBuildPhi(Builder, LLVMDoubleTypeInContext(TheContext), varName)
        LLVMAddIncoming(Variable, &StartVal, &PreheaderBB, 1)
        
        // Within the loop, the variable is defined equal to the PHI node.  If it
        // shadows an existing variable, we have to restore it, so save it now.
        let oldVal = NameValues[varName]
        NameValues[varName] = Variable
        
        // Emit the body of the loop.  This, like any other expr, can change the
        // current BB.  Note that we ignore the value computed by the body, but don't
        // allow an error.
        if body.codegen() == nil { return nil }
        
        // Emit the step value.
        var StepVal: LLVMValueRef?
        if step != nil {
            StepVal = step!.codegen()
            if StepVal == nil { return nil }
        } else {
            // If not specified, use 1.0.
            StepVal = LLVMConstReal(LLVMDoubleTypeInContext(TheContext), 1.0)
        }
        
        var NextVar = LLVMBuildFAdd(Builder, Variable, StepVal, "nextvar")
        
        // Compute the end condition.
        var EndCond = end.codegen()
        if EndCond == nil { return nil }
        
        // Convert condition to a bool by comparing non-equal to 0.0.
        EndCond = LLVMBuildFCmp(Builder, LLVMRealONE, EndCond, LLVMConstReal(LLVMDoubleTypeInContext(TheContext), 0.0), "loopcond")
        
        // Create the "after loop" block and insert it.
        var LoopEndBB = LLVMGetInsertBlock(Builder)
        let AfterBB = LLVMAppendBasicBlockInContext(TheContext, theFunction, "afterloop")
        
        // Insert the conditional branch into the end of LoopEndBB.
        LLVMBuildCondBr(Builder, EndCond, LoopBB, AfterBB)
        
        // Any new code will be inserted in AfterBB.
        LLVMPositionBuilderAtEnd(Builder, AfterBB)
        
        // Add a new entry to the PHI node for the backedge.
        LLVMAddIncoming(Variable, &NextVar, &LoopEndBB, 1)
        
        // Restore the unshadowed variable.
        if oldVal != nil {
            NameValues[varName] = oldVal
        } else {
            NameValues[varName] = nil
        }
        
        // for expr always returns 0.0.
        return LLVMConstNull(LLVMDoubleTypeInContext(TheContext))
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
    
    func isUnaryOp() -> Bool {
        return isOperator && Args.count == 1
    }
    
    func  isBinary() -> Bool {
        return isOperator && Args.count == 2
    }
    
    func getOperatorName() -> String? {
        guard let name = self.name.last else { return nil }
        return String(name)
    }
    
    func getBinaryPrecedence() -> UInt {
        precedence
    }
}

extension FunctionAST {
    func codegen() -> LLVMValueRef? {
        // Transfer ownership of the prototype to the FunctionProtos map, but keep a
        // reference to it for use below.
        var theFunction = LLVMGetNamedFunction(TheModule, proto.getName())

        if theFunction == nil {
            theFunction = proto.codegen()
        }
        
        if theFunction == nil {
            return nil
        }
        
        // If this is an operator, install it.
        if proto.isBinary() {
            let opName: Character = [Character](proto.getOperatorName()!).first!
            BinopPrecedence[opName] = Int(proto.getBinaryPrecedence())
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
