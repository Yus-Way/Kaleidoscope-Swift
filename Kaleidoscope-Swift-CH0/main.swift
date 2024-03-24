//
//  main.swift
//  Kaleidoscope-Swift-CH0
//
//  Created by Yu Liu on 2024-03-25.
//

import Foundation


let context = LLVMContextCreate()
defer { LLVMContextDispose(context) }

let module = LLVMModuleCreateWithNameInContext("Chapter 0", context)
defer { LLVMDisposeModule(module)}

let builder = LLVMCreateBuilderInContext(context)
defer { LLVMDisposeBuilder(builder) }

//  ❇️Create function: double sum(double, double).
let doubleType = LLVMDoubleTypeInContext(context)

var parameters = [doubleType, doubleType]
var functionType = LLVMFunctionType(doubleType, &parameters, UInt32(parameters.count), LLVMBool(0))

let function = LLVMAddFunction(module, "sum", functionType)
let basicBlock = LLVMAppendBasicBlockInContext(context, function, "entry")

LLVMPositionBuilderAtEnd(builder, basicBlock)
LLVMBuildRet(builder, LLVMBuildFAdd(builder, LLVMGetParam(function, 0), LLVMGetParam(function, 1), "add_tmp"))

//  ❇️main: int(*)(void)
let mainFunctionType = LLVMFunctionType(LLVMInt32Type(), nil, 0, LLVMBool(0))
let wrapperFunction = LLVMAddFunction(module, "__wrapper_main", mainFunctionType)
let mainBasicBlock = LLVMAppendBasicBlockInContext(context, wrapperFunction, "entry")

LLVMPositionBuilderAtEnd(builder, mainBasicBlock)

let x = 100.0, y = 25.6
var args = [LLVMConstReal(doubleType, x), LLVMConstReal(doubleType, y)]
let call = LLVMBuildCall2(builder, functionType, function, &args, UInt32(args.count), "call")
LLVMBuildRet(builder, call)

var execututionEngine: LLVMExecutionEngineRef?
var error: UnsafeMutablePointer<CChar>?

guard LLVMCreateExecutionEngineForModule(&execututionEngine, module, &error) == 0
else {
    let messege = String(cString: error!)
    LLVMDisposeMessage(error)
    print(messege)
    exit(1)
}

LLVMDumpModule(module)

let result = LLVMRunFunction(execututionEngine, wrapperFunction, 0, nil)
print("\(x) + \(y) = \(LLVMGenericValueToFloat(LLVMDoubleType(), result))")




/* ------------- Without the context -----------------
 
 let module = LLVMModuleCreateWithName("Chapter 0")
 defer { LLVMDisposeModule(module) }

 let builder = LLVMCreateBuilder()
 defer { LLVMDisposeBuilder(builder) }

 let doubleType = LLVMDoubleType()

 // sum: int(*)(int, int)
 var parameters = [doubleType, doubleType]
 let functionType = LLVMFunctionType(doubleType, &parameters, UInt32(parameters.count), LLVMBool(0))

 let function = LLVMAddFunction(module, "sum", functionType)
 let basicBlock = LLVMAppendBasicBlock(function, "entry")

 LLVMPositionBuilderAtEnd(builder, basicBlock)
 LLVMBuildRet(builder, LLVMBuildFAdd(builder, LLVMGetParam(function, 0), LLVMGetParam(function, 1), "add_tmp"))

 // main: int(*)(void)
 let mainFunctionType = LLVMFunctionType(doubleType, nil, 0, LLVMBool(0))
 let wrapperFunction = LLVMAddFunction(module, "__wrapper_main", mainFunctionType)
 let mainBasicBlock = LLVMAppendBasicBlock(wrapperFunction, "entry")
 LLVMPositionBuilderAtEnd(builder, mainBasicBlock)

 let x = 100.0, y = 25.4
 var args = [LLVMConstReal(doubleType, x),
             LLVMConstReal(doubleType, y)]
 LLVMBuildRet(builder, LLVMBuildCall2(builder, functionType, function, &args, UInt32(args.count), "call_tmp"))

 // execution
 var executionEngine = LLVMExecutionEngineRef(bitPattern: 1)
 var error: UnsafeMutablePointer<CChar>? = nil
 defer { error?.deallocate() }

 guard LLVMCreateExecutionEngineForModule(&executionEngine, module, &error) == 0
 else {
     print(String(cString: error!))
     LLVMDisposeMessage(error)
     exit(1)
 }

 LLVMDumpModule(module)

 let z = LLVMRunFunction(executionEngine, wrapperFunction, 0, nil)
 print("✅\(x) + \(y) = \(LLVMGenericValueToFloat(LLVMDoubleType(), z))")
*/
