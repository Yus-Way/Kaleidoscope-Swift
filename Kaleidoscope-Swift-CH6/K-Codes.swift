//
//  K-Codes.swift
//  Kaleidoscope-Swift-CH2
//
//  Created by Yu Liu on 2024-03-27.
//

let code = code6_3
let source = Array(code)

/// ----------- Chapter 6 ---------------------

let code6_1 =
"""
extern printd(x);
def binary : 1 (x y) 0; # Low-precedence operator that ignores operands.
printd(123) : printd(456) : printd(789);

"""

let code6_2 =
"""
# Logical unary not.
def unary!(v)
if v then
0
else
1;

# Unary negate.
def unary-(v)
0-v;

# Define > with the same precedence as <.
def binary> 10 (LHS RHS)
RHS < LHS;

# Binary logical or, which does not short circuit.
def binary| 5 (LHS RHS)
if LHS then
1
else if RHS then
1
else
0;

# Binary logical and, which does not short circuit.
def binary& 6 (LHS RHS)
if !LHS then
0
else
!!RHS;

# Define = with slightly lower precedence than relationals.
def binary = 9 (LHS RHS)
!(LHS < RHS | LHS > RHS);
# Define ':' for sequencing: as a low-precedence operator that ignores operands
# and just returns the RHS.
def binary : 1 (x y) y;

extern putchard(char);
def printdensity(d)
  if d > 8 then
    putchard(32)  # ' '
  else if d > 4 then
    putchard(46)  # '.'
  else if d > 2 then
    putchard(43)  # '+'
  else
    putchard(42); # '*'
printdensity(1): printdensity(2): printdensity(3):
printdensity(4): printdensity(5): printdensity(9):
putchard(10);

"""

let code6_3 = code6_2 +
"""
def binary> 10 (LHS RHS)
  RHS < LHS;
# Determine whether the specific location diverges.
# Solve for z = z^2 + c in the complex plane.
def mandelconverger(real imag iters creal cimag)
  if iters > 255 | (real*real + imag*imag > 4) then
    iters
  else
    mandelconverger(real*real - imag*imag + creal,
                    2*real*imag + cimag,
                    iters+1, creal, cimag);

# Return the number of iterations required for the iteration to escape
def mandelconverge(real imag)
  mandelconverger(real, imag, 0, real, imag);

# Compute and plot the mandelbrot set with the specified 2 dimensional range
# info.
def mandelhelp(xmin xmax xstep   ymin ymax ystep)
  for y = ymin, y < ymax, ystep in (
    (for x = xmin, x < xmax, xstep in
       printdensity(mandelconverge(x,y)))
    : putchard(10)
  )

# mandel - This is a convenient helper function for plotting the mandelbrot set
# from the specified position with the specified Magnification.
def mandel(realstart imagstart realmag imagmag)
  mandelhelp(realstart, realstart+realmag*78, realmag,
             imagstart, imagstart+imagmag*40, imagmag);

mandel(-2.3, -1.3, 0.05, 0.07);
mandel(-2, -1, 0.02, 0.04);
mandel(-0.9, -1.4, 0.02, 0.03);

"""

/// ----------- Chapter 5 ---------------------

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

