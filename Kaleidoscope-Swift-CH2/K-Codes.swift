//
//  K-Codes.swift
//  Kaleidoscope-Swift-CH2
//
//  Created by Yu Liu on 2024-03-27.
//

let code = code2_3
let source = Array(code)

let code0_0 = "4+5;"
let code1_0 = "foo(x);"
let code1_1 = "def foo(x y) x+foo(y, 4.0);"
let code1_2 = "def foo(x y) x+y y;"
let code1_3 = "def foo(x y) x+y );"
let code1_4 = "extern sin(a);"
//let code1_5 = "extern sin(a);"
//let code1_6 = "extern sin(a);"


let code2_1 = "def foo(x y) x+foo(y, 4.0);"
let code2_2 = "def foo(x y) x+y y;"
let code2_3 = "def foo(x y) x+y );"
let code2_4 = "extern sin(a);"

let code3_1 = "4+5;"
let code3_2 = "def foo(a b) a*a + 2*a*b + b*b;"
let code3_3 = "def bar(a) foo(a, 4.0) + bar(31337);"
let code3_4 = "extern cos(x);"
let code3_5 = "cos(1.234);"

let code3_6 =
"""
4+5;
def foo(a b) a*a + 2*a*b + b*b;
def bar(a) foo(a, 4.0) + bar(31337);
extern cos(x);
cos(1.234);
"""
