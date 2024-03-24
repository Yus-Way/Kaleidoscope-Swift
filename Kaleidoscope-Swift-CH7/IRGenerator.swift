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
var NamedValues: [String : LLVMValueRef] = [:]


@discardableResult
func LogErrorV(_ str: String) -> LLVMValueRef? {
    LogError(str)
    return nil
}

/// CreateEntryBlockAlloca - Create an alloca instruction in the entry block of
/// the function. This is used for mutable variables etc.
func createEntryBlockAlloca(TheFunction: LLVMValueRef, varName: String) -> LLVMValueRef? {
    return LLVMBuildAlloca(Builder, LLVMDoubleTypeInContext(TheContext), varName)
}

extension NumberExprAST {
    func codegen() -> LLVMValueRef? {
        let doubleType = LLVMDoubleTypeInContext(TheContext)
        return LLVMConstReal(doubleType, val)
    }
}

extension VariableExprAST {
    func codegen() -> LLVMValueRef? {
        // Look this variable up in the function.
        guard let A = NamedValues[name] else {
            LogErrorV("Unknown variable name")
            return nil
        }
        
        // Load the value.
        return LLVMBuildLoad2(Builder, LLVMGetAllocatedType(A), A, name)
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
        // Special case '=' because we don't want to emit the LHS as an expression.
        if op == "=" {
            // Assignment requires the LHS to be an identifier.
            // This assume we're building without RTTI because LLVM builds that way by
            // default. If you build LLVM with RTTI this can be changed to a
            // dynamic_cast for automatic error checking.

            let LHSE = LHS as? VariableExprAST
            if LHSE == nil {
                return LogErrorV("destination of '=' must be a variable")
            }
            
            // Codegen the RHS.
            guard let Val = RHS.codegen() else { return nil }
            
            // Look up the name.
            guard let Variable = NamedValues[LHSE!.name]
            else {
                return LogErrorV("Unkown variable name")
            }
            
            LLVMBuildStore(Builder, Val, Variable)
            return Val
        }
        
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
        let theFunction = LLVMGetBasicBlockParent(LLVMGetInsertBlock(Builder))
        
        // Create an alloca for the variable in the entry block.
        let Alloca = createEntryBlockAlloca(TheFunction: theFunction!, varName: varName)
        
        // Emit the start code first, without 'variable' in scope.
        let StartVal = start.codegen()
        if StartVal == nil { return nil }
        
        // Store the value into the alloca.
        LLVMBuildStore(Builder, StartVal!, Alloca)
        
        // Make the new basic block for the loop header, inserting after current
        // block.
        let LoopBB = LLVMAppendBasicBlockInContext(TheContext, theFunction, "loop")
        
        // Insert an explicit fall through from the current block to the LoopBB.
        LLVMBuildBr(Builder, LoopBB)
        
        // Start insertion in LoopBB.
        LLVMPositionBuilderAtEnd(Builder, LoopBB)
        
        // Within the loop, the variable is defined equal to the PHI node.  If it
        // shadows an existing variable, we have to restore it, so save it now.
        let oldVal = NamedValues[varName]
        NamedValues[varName] = Alloca
        
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
        
        // Compute the end condition.
        var EndCond = end.codegen()
        if EndCond == nil { return nil }
        
        // Reload, increment, and restore the alloca. This handles the case where
        // the body of the loop mutates the variable.
        let CurVar = LLVMBuildLoad2(Builder, LLVMGetAllocatedType(Alloca), Alloca, varName)
        let NextVar = LLVMBuildFAdd(Builder, CurVar, StepVal, "nextvar")
        LLVMBuildStore(Builder, NextVar, Alloca)
        
        // Convert condition to a bool by comparing non-equal to 0.0.
        EndCond = LLVMBuildFCmp(Builder, LLVMRealONE, EndCond, LLVMConstReal(LLVMDoubleTypeInContext(TheContext), 0.0), "loopcond")
        
        // Create the "after loop" block and insert it.
        let AfterBB = LLVMAppendBasicBlockInContext(TheContext, theFunction, "afterloop")
        
        // Insert the conditional branch into the end of LoopEndBB.
        LLVMBuildCondBr(Builder, EndCond, LoopBB, AfterBB)
        
        // Any new code will be inserted in AfterBB.
        LLVMPositionBuilderAtEnd(Builder, AfterBB)
        
        // Restore the unshadowed variable.
        if oldVal != nil {
            NamedValues[varName] = oldVal
        } else {
            NamedValues[varName] = nil
        }
        
        // for expr always returns 0.0.
        return LLVMConstNull(LLVMDoubleTypeInContext(TheContext))
    }
}

extension VarExprAST {
    func codegen() -> LLVMValueRef? {
        var OldBindings: [LLVMValueRef] = []
        
        let TheFunction = LLVMGetBasicBlockParent(LLVMGetInsertBlock(Builder))
        
        // Register all variables and emit their initializer.
        for i in 0..<VarNames.count {
            let VarName = VarNames[i].0
            let Init = VarNames[i].1
            
            // Emit the initializer before adding the variable to scope, this prevents
            // the initializer from referencing the variable itself, and permits stuff
            // like this:
            // var a = 1 in
            // var a = a in ... # refers to outer 'a'.
            let InitVal: LLVMValueRef?
            if Init != nil {
                InitVal = Init!.codegen()
                if InitVal == nil {
                    return nil
                }
            } else {    //  If not specified, use 0.0.
                let doubleType = LLVMDoubleTypeInContext(TheContext)
                InitVal = LLVMConstReal(doubleType, 0.0)
            }
            
            let Alloca = createEntryBlockAlloca(TheFunction: TheFunction!, varName: VarName)
            LLVMBuildStore(Builder, InitVal, Alloca)
            
            // Remember the old variable binding so that we can restore the binding when
            // we unrecurse.
            OldBindings.append(InitVal!)
            
            // Remember this binding.
            NamedValues[VarName] = Alloca
        }
        
        // Codegen the body, now that all vars are in scope.
        guard let BodyVal = body.codegen() else { return nil }
        
        // Pop all our variables from scope.
        for i in 0..<VarNames.count {
            NamedValues[VarNames[i].0] = OldBindings[i]
        }
        
        // Return the body computation.
        return BodyVal
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
        
        let F = LLVMAddFunction(TheModule, name, ft)
        
        // Set names for all arguments.
        for (index, arg) in Args.enumerated() {
            let param = LLVMGetParam(F, UInt32(index))
            LLVMSetValueName(param, arg)
        }
        
        return F
    }
    
    func isUnaryOp() -> Bool {
        return isOperator && Args.count == 1
    }
    
    func  isBinaryOp() -> Bool {
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
        
        /*
         auto &P = *Proto;
         FunctionProtos[Proto->getName()] = std::move(Proto);
         */
        
        var theFunction = LLVMGetNamedFunction(TheModule, proto.getName())

        if theFunction == nil {
            theFunction = proto.codegen()
        }
        
        if theFunction == nil {
            return nil
        }
        
        // If this is an operator, install it.
        if proto.isBinaryOp() {
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
        NamedValues.removeAll()
        let count = LLVMCountParams(theFunction)
        for index in 0..<count {
            let parameter = LLVMGetParam(theFunction, UInt32(index))
            var nameLength = 0
            let name = String(cString: LLVMGetValueName2(parameter, &nameLength))
            
            // Create an alloca for this variable.
            let Alloca = createEntryBlockAlloca(TheFunction: theFunction!, varName: name)
            
            // Store the initial value into the alloca.
            LLVMBuildStore(Builder, parameter, Alloca)
            
            // Add arguments to variable symbol table.
            NamedValues[name] = Alloca
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
        
        if proto.isBinaryOp() {
            BinopPrecedence[Character(proto.getOperatorName()!)] = nil
        }
        return nil
    }
}
