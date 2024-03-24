//
//  K-Codes.swift
//  Kaleidoscope-Swift-CH2
//
//  Created by Yu Liu on 2024-03-27.
//

let code = code5_3
let source = Array(code)

/// ----------- Chapter 4 ---------------------

let code5_1 =
"""
def fib(x)
  if x < 3 then
    1
  else
    fib(x-1)+fib(x-2);

"""

let code5_2 =
"""
extern foo();
extern bar();
def baz(x) if x then foo() else bar();

"""

//  ❇️For extended C++ code (putchard) to run, we have to call it in Swift first.
let code5_3 =
"""
extern putchard(char);
def printstar(n)
  for i = 1, i < n, 1.0 in
    putchard(42);  # ascii 42 = '*'

# print 100 '*' characters
printstar(100);

"""


/// ----------- Chapter 4 ---------------------
let code4_1 = "4+5;"
let code4_2 = "def testfunc(x y) x + y*2;"
let code4_3 = "testfunc(4, 10);"
let code4_4 = "testfunc(5, 10);"
let code4_5 = "def foo(x) x + 1;"
let code4_6 = "foo(2);"
let code4_7 = "def foo(x) x + 2;"
let code4_8 = "foo(2);"
let code4_9 = "extern sin(x);"
let code4_10 = "extern cos(x);"
let code4_11 = "sin(1.0);"
let code4_12 = "def foo(x) sin(x)*sin(x) + cos(x)*cos(x);"
let code4_13 = "foo(4.0);"
//let code4_14 =
//"""
//extern putchard(x);
//putchard(65);
//
//"""

let code4_20 =
"""
4+5;
def testfunc(x y) x + y*2;
testfunc(4, 10);
testfunc(5, 10);
def foo(x) x + 1;
foo(2);
def foo(x) x + 2;
foo(2);
extern sin(x);
extern cos(x);
sin(1.0);
def foo(x) sin(x)*sin(x) + cos(x)*cos(x);
foo(4.0);

"""

/// ----------- Chapter 3 ---------------------
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

/// ----------- Chapter 2 ---------------------
let code2_1 = "def foo(x y) x+foo(y, 4.0);"
let code2_2 = "def foo(x y) x+y y;"
let code2_3 = "def foo(x y) x+y );"
let code2_4 = "extern sin(a);"

